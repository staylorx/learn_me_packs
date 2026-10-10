// manifest.dart — the learn_me pack manifest (root inventory).
//
// A pack repo's root `manifest.json` is the inventory an app that registers a
// pack endpoint reads: which packs it can import, under what license, by
// subject/tag/age. It is part of the learn_me pack spec (see
// manifest.schema.json at the repo root).
//
// The manifest is DERIVED output, not hand-maintained: the pack builder
// updates it after every build (--manifest <path>), so it never drifts from
// the packs actually on disk. This file owns the read-modify-write so the
// builder stays a thin caller.

import 'dart:convert';
import 'dart:io';

/// Derive a manifest entry from an existing DeckDocument pack file, reading the
/// deck-level fields + card count from the pack itself so the row matches what
/// is actually on disk without re-emitting the pack (re-emit can drift cosmetic
/// metadata like `domain`). Fields passed explicitly win over the pack's own.
ManifestEntry manifestEntryFromPack({
  required String packPath,
  required String deckId,
  String? file,
  String? title,
  String? subject,
  List<String> tags = const [],
  String? age,
  String? license,
  int? cards,
  String? algorithm,
  String? source,
  String? sourceUrl,
}) {
  Map<String, dynamic>? doc;
  try {
    final parsed = jsonDecode(File(packPath).readAsStringSync());
    doc = parsed is Map<String, dynamic> ? parsed : null;
  } catch (_) {
    doc = null;
  }

  final fileValue = file ?? packPath;
  final idValue = deckId;
  final titleValue =
      title ??
      (doc?['deck'] is String ? doc!['deck'] as String : null) ??
      deckId;
  final subjectValue = subject ?? doc?['domain'] as String? ?? 'general';
  final licenseValue = license ?? doc?['source_license'] as String? ?? 'CC0-1.0';
  final cardCount =
      cards ??
      ((doc?['cards'] is List) ? (doc?['cards'] as List).length : 0);
  final algorithmValue = algorithm ?? doc?['algorithm'] as String?;
  final sourceValue = source ?? doc?['source'] as String?;
  final prov = doc?['provenance'];
  final sourceUrlValue = sourceUrl ??
      (prov is Map && prov['source_url'] is String
          ? prov['source_url'] as String
          : null);

  return ManifestEntry(
    id: idValue,
    file: fileValue,
    title: titleValue,
    subject: subjectValue,
    tags: tags,
    age: age,
    license: licenseValue,
    cards: cardCount,
    algorithm: algorithmValue,
    source: sourceValue,
    sourceUrl: sourceUrlValue,
  );
}

/// One manifest entry — the inventory row for a single pack.
class ManifestEntry {
  ManifestEntry({
    required this.id,
    required this.file,
    required this.title,
    required this.subject,
    this.tags = const [],
    this.age,
    required this.license,
    required this.cards,
    this.algorithm,
    this.source,
    this.sourceUrl,
  });

  final String id;
  final String file;
  final String title;
  final String subject;
  final List<String> tags;
  final String? age;
  final String license;
  final int cards;
  final String? algorithm;
  final String? source;
  final String? sourceUrl;

  Map<String, Object?> toJson() => {
        'id': id,
        'file': file,
        'title': title,
        'subject': subject,
        if (tags.isNotEmpty) 'tags': tags,
        if (age != null && age!.isNotEmpty) 'age': age,
        'license': license,
        'cards': cards,
        if (algorithm != null && algorithm!.isNotEmpty) 'algorithm': algorithm,
        if (source != null && source!.isNotEmpty) 'source': source,
        if (sourceUrl != null && sourceUrl!.isNotEmpty) 'source_url': sourceUrl,
      };
}

/// Read the manifest at [path], or an empty one if absent/unreadable.
Map<String, Object?> readManifest(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return <String, Object?>{'spec': 'learn-me-pack-manifest', 'version': 1, 'packs': <Object?>[]};
  }
  try {
    final parsed = jsonDecode(file.readAsStringSync());
    if (parsed is Map<String, dynamic>) return parsed;
  } catch (_) {
    // Corrupt manifest: start fresh rather than fail the build.
  }
  return <String, Object?>{'spec': 'learn-me-pack-manifest', 'version': 1, 'packs': <Object?>[]};
}

/// Insert or replace [entry] in the manifest at [path], keyed by deck id, and
/// write it back sorted by deck id. Returns the number of packs now listed.
int upsertManifestEntry(String path, ManifestEntry entry) {
  final manifest = readManifest(path);
  final packs = (manifest['packs'] as List? ?? const [])
      .cast<Map<String, dynamic>>()
      .toList();

  packs.removeWhere((p) => p['id'] == entry.id);
  packs.add(entry.toJson().cast<String, dynamic>());
  packs.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

  manifest['packs'] = packs;
  File(path).parent.createSync(recursive: true);
  File(path).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(manifest) + '\n',
  );
  return packs.length;
}
