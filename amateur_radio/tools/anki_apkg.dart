// anki_apkg.dart — self-contained Anki .apkg adapter for pack_builder.
//
// An .apkg is a ZIP containing a collection.* (SQLite) DB plus numbered media
// files and a JSON "media" manifest mapping numeric ids to original filenames.
// We extract, read notes/cards/models, and emit RawCards (front/back) with any
// images/audio embedded as media bytes.
//
// Deliberately self-contained: it does NOT import learn_me's parser-anki. That
// keeps the pack tool decoupled from wherever the anki importer ultimately
// lives (core or extracted). It shares only the RawCard/Figure intermediate.
//
// Card model handled: Basic-style 2-field notes (front/back). Cloze notes and
// multi-template notes are skipped and counted. Media referenced by <img> or
// [sound:...] on either face is embedded.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'raw_cards.dart';

/// Parse an Anki .apkg (bytes [apkgBytes], from [location] for provenance)
/// into RawCards. Returns empty (not throws) on a non-apkg after logging.
List<RawCard> ankiParseApkg(List<int> apkgBytes, String location) {
  final dir = Directory.systemTemp.createTempSync('pack_builder_anki_');
  try {
    // 1. Extract zip into temp.
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(apkgBytes);
    } catch (e) {
      stderr.writeln('anki: $location is not a valid zip: $e');
      return const [];
    }
    for (final file in archive) {
      if (!file.isFile) continue;
      final out = File(p.join(dir.path, file.name));
      out.createSync(recursive: true);
      out.writeAsBytesSync(file.content as List<int>);
    }

    // 2. Locate and open the SQLite collection (anki2 or anki21).
    final dbPath = _findCollection(dir.path);
    if (dbPath == null) {
      stderr.writeln('anki: $location has no collection.anki2/anki21');
      return const [];
    }

    // 3. Media manifest: numeric id -> original filename.
    final mediaMap = _loadMediaManifest(dir.path);

    // 4. Read model/note/card tables and emit RawCards.
    return _readDb(dbPath, dir.path, mediaMap, location);
  } finally {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {
      /* temp cleanup; leave to OS */
    }
  }
}

String? _findCollection(String dir) {
  for (final name in ['collection.anki2', 'collection.anki21']) {
    final f = File(p.join(dir, name));
    if (f.existsSync()) return f.path;
  }
  return null;
}

Map<String, String> _loadMediaManifest(String dir) {
  final mediaFile = File(p.join(dir, 'media'));
  if (!mediaFile.existsSync()) return const {};
  try {
    final parsed = jsonDecode(mediaFile.readAsStringSync());
    if (parsed is Map<String, dynamic>) {
      return {for (final e in parsed.entries) e.key: e.value as String};
    }
  } catch (_) {}
  return const {};
}

List<RawCard> _readDb(
  String dbPath,
  String mediaDir,
  Map<String, String> mediaMap,
  String location,
) {
  final db = sqlite3.open(dbPath);
  try {
    final models = _extractModels(db);
    final notes = _extractNotes(db);
    final cards = _extractCards(db);

    final noteById = {for (final n in notes) n.nid: n};
    final modelById = {for (final m in models) m.mid: m};

    final out = <RawCard>[];
    var clozeSkipped = 0;
    final seenNids = <int>{};

    for (final c in cards) {
      if (!seenNids.add(c.nid)) continue; // one RawCard per note
      final note = noteById[c.nid];
      if (note == null) continue;
      final model = modelById[note.mid];
      if (model == null) continue;

      final flds = note.fields;
      if (flds.length < 2) continue;
      if (flds.any(_isCloze)) {
        clozeSkipped++;
        continue;
      }

      final front = _faceToParts(flds[0], mediaMap, mediaDir);
      final back = _faceToParts(flds[1], mediaMap, mediaDir);
      final media = [...front.media, ...back.media];

      out.add(
        RawCard(
          id: '${c.nid}',
          front: front.text,
          back: back.text,
          figure: media.length == 1 ? media.first : null,
          media: media,
          source: location,
        ),
      );
    }

    if (clozeSkipped > 0) {
      stderr.writeln(
        'anki: skipped $clozeSkipped cloze/complex notes in $location',
      );
    }
    return out;
  } finally {
    db.close();
  }
}

bool _isCloze(String f) =>
    f.contains('{{c') ||
    f.contains('}}') ||
    f.contains('{{ type:');

class _Parts {
  _Parts(this.text, this.media);
  final String text;
  final List<Figure> media;
}

/// Turn one Anki field's HTML into trimmed text + embedded media.
_Parts _faceToParts(
  String html,
  Map<String, String> mediaMap,
  String mediaDir,
) {
  final media = <Figure>[];

  for (final m in RegExp(r'<img[^>]+src="([^"]+)"').allMatches(html)) {
    final src = m.group(1)!;
    final bytes = _mediaBytes(src, mediaMap, mediaDir);
    if (bytes != null) {
      media.add(Figure(ref: src, bytes: bytes, mime: mimeFor(src)));
    }
  }
  for (final m in RegExp(r'\[sound:([^\]]+)\]').allMatches(html)) {
    final src = m.group(1)!;
    final bytes = _mediaBytes(src, mediaMap, mediaDir);
    if (bytes != null) {
      media.add(Figure(ref: src, bytes: bytes, mime: mimeFor(src)));
    }
  }

  // Text: strip HTML, drop sound markers.
  final doc = html_parser.parse(html);
  final text = doc.body?.text ?? '';
  return _Parts(
    clean(text.replaceAll(RegExp(r'\[sound:[^\]]*\]'), '')),
    media,
  );
}

List<int>? _mediaBytes(String ref, Map<String, String> mediaMap, String mediaDir) {
  // Manifest key is the numeric file name; value is the original name org.g.
  String? numericId;
  for (final e in mediaMap.entries) {
    if (e.value == ref || p.basename(e.value) == p.basename(ref)) {
      numericId = e.key;
      break;
    }
  }
  final candidate = numericId != null
      ? File(p.join(mediaDir, numericId))
      : File(p.join(mediaDir, ref));
  return candidate.existsSync() ? candidate.readAsBytesSync() : null;
}

class _AnkiCard {
  _AnkiCard({required this.nid});
  final int nid;
}

class _AnkiNote {
  _AnkiNote({required this.nid, required this.mid, required this.fields});
  final int nid;
  final int mid;
  final List<String> fields;
}

class _AnkiModel {
  _AnkiModel({required this.mid});
  final int mid;
}

List<_AnkiModel> _extractModels(Database db) {
  final result = db.select('SELECT models FROM col');
  if (result.isEmpty) return const [];
  final modelsJson = result.first['models'] as String;
  final modelsMap = jsonDecode(modelsJson) as Map<String, dynamic>;
  return modelsMap.keys.map((k) => _AnkiModel(mid: int.parse(k))).toList();
}

List<_AnkiNote> _extractNotes(Database db) {
  return db.select('SELECT id AS nid, mid, flds FROM notes').map((row) {
    return _AnkiNote(
      nid: row['nid'] as int,
      mid: row['mid'] as int,
      fields: (row['flds'] as String).split('\x1f'),
    );
  }).toList();
}

List<_AnkiCard> _extractCards(Database db) {
  return db.select('SELECT nid FROM cards').map((row) {
    return _AnkiCard(nid: row['nid'] as int);
  }).toList();
}
