// pack_builder.dart — generic pack builder for learn_me packs.
//
// Takes 1..N source corpora (local files OR http(s) URLs), each parsed by a
// registered format adapter, merges them, dedupes by content (the same
// content-derived handle the learn_me engine uses, so re-adding a card reuses
// it), sorts, and emits ONE learn_me DeckDocument pack — exactly what
// `learn_me deck import --format json` reads (packages/parser-json).
//
// The pipeline is: wrangle -> parse -> merge/dedupe -> sort -> emit.
// Source formats are registered adapters; each owns loading (JSON pools vs
// binary .apkg differ) plus parsing.
//
//   dart run tools/pack_builder.dart \
//     --out packs/technician_2018-2022.json \
//     --deck us-technician-2018-2022 \
//     --source fcc-pool:C:/data/US-Technician-2018-2022.json \
//     --images C:/data/images
//
//   # N sources for the same pool → merged + deduped (richer card wins):
//   dart run tools/pack_builder.dart \
//     --out packs/extra_2020-2024.json \
//     --deck us-extra-2020-2024 \
//     --source fcc-pool:C:/a/US-Extra-2020-2024.json \
//     --source fcc-pool:https://raw.githubusercontent.com/<org>/<repo>/extra.json
//
//   # An Anki .apkg deck (basic 2-field cards; cloze/skip, media embedded):
//   dart run tools/pack_builder.dart \
//     --out packs/gross_anatomy.json \
//     --deck us-gross-anatomy \
//     --source anki:C:/data/GrossAnatomy.apkg
//
// Declared adapters (--source FORMAT:location):
//   fcc-pool  — BaksiLi/RadioExamToolkit JSON schema: sections[] -> items[]
//   anki      — Anki .apkg (zip+sqlite): basic 2-field cards -> front/back,
//               media bytes embedded as image/audio facts
//
// Deck id: from --deck when given, else derived from the first source.

import 'dart:convert';
import 'dart:io';

import 'anki_apkg.dart';
import 'raw_cards.dart';
import 'rdf_owl.dart';

// ---------------------------------------------------------------------------
// Adapters: FORMAT -> (location bytes) -> List<RawCard>. Each adapter owns its
// loading because sources differ in bytes (JSON vs zip).
// ---------------------------------------------------------------------------

typedef Adapter = Future<List<RawCard>> Function(
  List<int> bytes,
  String location, {
  Map<String, String>? images,
});

Future<List<RawCard>> _fccPoolAdapter(
  List<int> bytes,
  String location, {
  Map<String, String>? images,
}) =>
    Future.value(_parseFccPool(bytes, location, images));

final _registry = <String, Adapter>{
  'fcc-pool': _fccPoolAdapter,
  'anki': _parseAnkiApkg,
  // rdf-owl: the location IS the root IRI (or comma-separated list); bytes are
  // unused — the adapter fetches the subtree from OLS itself.
  'rdf-owl': (bytes, location, {images}) => rdfOwlParse(location),
};

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

Future<void> main(List<String> args) async {
  final outPath = _flag(args, '--out');
  final deckId = _flag(args, '--deck');
  final algorithm = _flag(args, '--algorithm') ?? 'sm2';
  final imagesDir = _flag(args, '--images');
  final license = _flag(args, '--license');
  final sourceName = _flag(args, '--source-name');
  final sourceUrl = _flag(args, '--source-url');

  final srcList = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--source' && i + 1 < args.length) {
      srcList.add(args[i + 1]);
    }
  }

  if (outPath == null || srcList.isEmpty) {
    stderr.writeln(
      'usage: dart run tools/pack_builder.dart --out <pack.json> '
      '[--deck <id>] [--algorithm <sm2|fsrs|naive>] '
      '[--images <dir>] [--license <SPDX>] [--source-name <name>] '
      '[--source-url <url>] --source <FORMAT:path-or-url> [--source ...]',
    );
    exit(2);
  }

  final images = <String, String>{};
  if (imagesDir != null) {
    images.addAll(_loadImages(imagesDir));
  }

  final cards = <String, RawCard>{}; // keyed by contentHandle
  final levelDomain = <String>{};

  for (final spec in srcList) {
    final colon = spec.indexOf(':');
    final format = colon < 0 ? 'fcc-pool' : spec.substring(0, colon);
    final location = colon < 0 ? spec : spec.substring(colon + 1);

    final adapter = _registry[format];
    if (adapter == null) {
      stderr.writeln('unknown format "$format" (have: ${_registry.keys.join(', ')})');
      exit(2);
    }

    // rdf-owl's location is a root IRI the adapter fetches itself; it has no
    // bytes to read. Every other adapter reads a file or URL.
    final bytes = format == 'rdf-owl'
        ? const <int>[]
        : await readLocation(location);
    final parsed = await adapter(bytes, location, images: images);
    if (parsed.isEmpty) {
      stderr.writeln('warning: no cards parsed from $location');
    }
    for (final card in parsed) {
      final key = contentHandle(card);
      final existing = cards[key];
      if (existing == null) {
        cards[key] = card;
      } else {
        final preferred = _richer(existing, card);
        if (preferred != existing) cards[key] = preferred;
      }
      if (card.domain != null && card.domain!.isNotEmpty) {
        levelDomain.add(card.domain!);
      }
    }
    stdout.writeln('parsed ${parsed.length} cards from $location');
  }

  final sorted = cards.values.toList()..sort(_compareCards);
  final topDomain = levelDomain.isEmpty ? null : levelDomain.first;
  final resolvedDeckId = deckId ?? _deckIdFromSources(srcList);
  final effectiveLicense = license ?? _defaultLicenseFor(resolvedDeckId);

  final document = <String, Object?>{
    'deck': resolvedDeckId,
    'algorithm': algorithm,
    if (topDomain != null) 'domain': topDomain,
    // License + provenance: every pack states where it came from and under what
    // terms, at deck level (the schema's `source_license` field, deck_document.dart).
    // A derived pack's license is the SOURCE's license for the derived content.
    'source_license': effectiveLicense,
    'license_url': _licenseUrl(effectiveLicense),
    if (sourceName != null && sourceName.isNotEmpty) 'source': sourceName,
    if (sourceUrl != null && sourceUrl.isNotEmpty) 'provenance': {
      'source_url': sourceUrl,
      'generated_by': 'pack_builder.dart v2',
      'sources': [for (final s in srcList) _describeSource(s)],
    },
    'cards': [for (final c in sorted) c.toCardJson()],
  };

  File(outPath).parent.createSync(recursive: true);
  File(outPath).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(document),
  );
  stdout.writeln(
    'Wrote $outPath: ${sorted.length} cards '
    '(${sorted.where((c) => c.figureDependent).length} figure-dependent, '
    '${sorted.where((c) => c.figure != null).length} primary figures, '
    '${sorted.where((c) => c.media.isNotEmpty).length} with media)',
  );
}

// ---------------------------------------------------------------------------
// FCC pool adapter — the BaksiLi/RadioExamToolkit JSON schema.
// ---------------------------------------------------------------------------

List<RawCard> _parseFccPool(
  List<int> bytes,
  String location,
  Map<String, String>? images,
) {
  final doc = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  final level = doc['level'] as String? ?? _levelFromSource(location);
  final cards = <RawCard>[];

  for (final section in (doc['sections'] as List? ?? const [])) {
    final s = section as Map<String, dynamic>;
    final subelement = s['label'] as String? ?? '';
    final domain = subelement.isEmpty ? level : subelement;
    final scope = subelement.isEmpty ? level.toLowerCase() : subelement;

    for (final item in (s['items'] as List? ?? const [])) {
      final q = item as Map<String, dynamic>;
      final serial = q['serial'] as String? ?? '';
      final question = q['question'] as String? ?? '';
      final branches = (q['branches'] as List?)?.cast<String>() ?? const [];
      final correctIndex = q['correctBranchIndex'] as int?;
      final reference = q['reference'] as String? ?? '';

      if (serial.isEmpty || question.isEmpty) continue;
      if (branches.isEmpty || correctIndex == null) continue;

      const labels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
      final options = <RawOption>[
        for (var i = 0; i < branches.length; i++)
          RawOption(labels[i], branches[i], i == correctIndex ? 5 : 0),
      ];

      final figureRef = _figureRef(question, images);
      Figure? figure;
      final figureDependent = figureRef != null;
      final imageBytes = figureRef == null ? null : images?[figureRef];
      if (imageBytes != null) {
        figure = Figure(
          ref: figureRef!,
          bytes: base64Decode(imageBytes),
          mime: mimeFor(figureRef),
        );
      }

      cards.add(
        RawCard(
          id: serial,
          front: clean(question),
          options: options,
          domain: domain,
          scope: scope,
          bokReferences: reference.isEmpty ? const [] : [reference],
          figure: figure,
          figureDependent: figureDependent,
          source: location,
        ),
      );
    }
  }
  return cards;
}

// ---------------------------------------------------------------------------
// Anki .apkg adapter — implemented in anki_apkg.dart (self-contained).
// ---------------------------------------------------------------------------

Future<List<RawCard>> _parseAnkiApkg(
  List<int> bytes,
  String location, {
  Map<String, String>? images,
}) =>
    Future.value(ankiParseApkg(bytes, location));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String? _flag(List<String> args, String name) {
  final i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

Map<String, String> _loadImages(String dir) {
  final result = <String, String>{};
  for (final entry in Directory(dir).listSync()) {
    if (entry is! File) continue;
    final name = entry.path.split(RegExp(r'[/\\]')).last;
    result[name] = base64Encode(entry.readAsBytesSync());
  }
  return result;
}

String? _figureRef(String question, Map<String, String>? images) {
  final match = RegExp(
    r'[Ff]igure\s+([A-Za-z]+\d+(?:-\d+)?|[Tt][123])\b',
  ).firstMatch(question);
  if (match == null) return null;
  final base = match[1]!;
  if (images == null || images.isEmpty) return base;
  const exts = ['png', 'jpg', 'jpeg', 'svg'];
  for (final e in exts) {
    for (final name in ['$base.$e', '${base.toLowerCase()}.$e']) {
      if (images.containsKey(name)) return name;
    }
  }
  return base;
}

String _levelFromSource(String source) {
  final lower = source.toLowerCase();
  if (lower.contains('technician')) return 'Technician';
  if (lower.contains('general')) return 'General';
  if (lower.contains('extra')) return 'Extra';
  return 'Amateur';
}

/// A sensible default source license. FCC/NCVEC pools are U.S. government
/// works (47 CFR Part 97) and effectively public domain; any other corpus
/// defaults to the safest general derivative license.
String _defaultLicenseFor(String deckId) {
  if (deckId.startsWith('us-')) return 'CC0-1.0';
  return 'CC-BY-4.0';
}

/// Canonical URL for a known license (SPDX ids). Unknown ids fall back to the
/// SPDX registry page so the value stays machine-readable.
String _licenseUrl(String license) => switch (license) {
      'CC0-1.0' => 'https://creativecommons.org/publicdomain/zero/1.0/',
      'CC-BY-3.0' => 'https://creativecommons.org/licenses/by/3.0/',
      'CC-BY-4.0' => 'https://creativecommons.org/licenses/by/4.0/',
      'MIT' => 'https://opensource.org/licenses/MIT',
      'Apache-2.0' => 'https://www.apache.org/licenses/LICENSE-2.0',
      _ => 'https://spdx.org/licenses/$license',
    };

/// Faithfully name a source for provenance: a URL as-is, a local path as its
/// basename (the format prefix preserved) — a path is only a note, not a
/// durable identity.
String _describeSource(String spec) {
  final colon = spec.indexOf(':');
  final format = colon < 0 ? 'fcc-pool' : spec.substring(0, colon);
  final location = colon < 0 ? spec : spec.substring(colon + 1);
  final isUrl = location.startsWith('http://') ||
      location.startsWith('https://');
  return isUrl
      ? location
      : '$format:${location.split(RegExp(r'[/\\\\]')).last}';
}

String _deckIdFromSources(List<String> srcs) {
  final first = srcs.first.split(':').last;
  final base = first.split(RegExp(r'[/\\]')).last.toLowerCase();
  return base
      .replaceAll(RegExp(r'\.(json|apkg)$'), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

/// Prefer the card carrying more fidelity: figure, rationale, more options.
RawCard _richer(RawCard a, RawCard b) {
  int score(RawCard c) =>
      (c.figure != null ? 1 : 0) +
      (c.media.length > 0 ? 1 : 0) +
      (c.options.any((o) => o.rationale != null) ? 1 : 0) +
      (c.bokReferences.isNotEmpty ? 1 : 0);
  return score(b) > score(a) ? b : a;
}

/// Natural order: split id into runs of digits vs. other (T1A01 + T1A02 sort
/// numerically, not T1A10 < T1A2). Fall back to front when no id.
int _compareCards(RawCard a, RawCard b) {
  final idA = a.id.isEmpty ? a.front : a.id;
  final idB = b.id.isEmpty ? b.front : b.id;
  final pa = RegExp(r'\d+|\D+').allMatches(idA).map((m) => m.group(0)!).toList();
  final pb = RegExp(r'\d+|\D+').allMatches(idB).map((m) => m.group(0)!).toList();
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    final aNum = int.tryParse(pa[i]);
    final bNum = int.tryParse(pb[i]);
    if (aNum != null && bNum != null) {
      if (aNum != bNum) return aNum.compareTo(bNum);
    } else if (pa[i] != pb[i]) {
      return pa[i].compareTo(pb[i]);
    }
  }
  return pa.length.compareTo(pb.length);
}
