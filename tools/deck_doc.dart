// deck_doc.dart — DeckDocument source adapter for pack_builder.
//
// Reads an existing learn_me DeckDocument pack (the JSON the builder emits)
// back into RawCards. This makes the builder round-trippable: a pack can be
// re-ingested as a source, which is what lets `--manifest` regenerate the root
// inventory with correct card counts without re-running the original source
// pipeline. It is the inverse of the emitter in pack_builder.dart.
//
//   dart run tools/pack_builder.dart \
//     --out fcc_radio/packs/technician_2018-2022.json \
//     --deck us-technician-2018-2022 \
//     --manifest manifest.json \
//     --source deck-doc:fcc_radio/packs/technician_2018-2022.json

import 'dart:convert';
import 'dart:io';

import 'raw_cards.dart';

/// Parse a DeckDocument pack (bytes [jsonBytes]) into RawCards. Returns empty
/// (not throws) on a non-DeckDocument after logging.
List<RawCard> deckDocParse(List<int> jsonBytes, String location) {
  final Map<String, dynamic> doc;
  try {
    doc = jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('deck-doc: $location is not valid JSON: $e');
    return const [];
  }
  if (doc['cards'] is! List) {
    stderr.writeln('deck-doc: $location has no "cards" list (not a DeckDocument)');
    return const [];
  }

  final cards = <RawCard>[];
  for (final raw in (doc['cards'] as List)) {
    final c = raw as Map<String, dynamic>;
    final front = c['front'];
    final back = c['back'];
    // A media side is an object, not text; skip cards whose front is media
    // (the builder's RawCard model is text-first). Back media is dropped.
    if (front is! String) continue;

    final options = <RawOption>[];
    for (final o in (c['options'] as List? ?? const [])) {
      final opt = o as Map<String, dynamic>;
      options.add(
        RawOption(
          opt['label'] as String? ?? '',
          opt['text'] as String? ?? '',
          (opt['score'] as num?)?.toInt() ?? 0,
          opt['rationale'] as String?,
        ),
      );
    }

    final figure = c['figure'];
    Figure? figureObj;
    if (figure is Map<String, dynamic> && figure['data'] is String) {
      figureObj = Figure(
        ref: c['id'] as String? ?? '',
        bytes: base64Decode(figure['data'] as String),
        mime: figure['mime_type'] as String? ?? 'application/octet-stream',
      );
    }

    cards.add(
      RawCard(
        id: c['id'] as String? ?? '',
        front: front,
        back: back is String ? back : null,
        options: options,
        domain: c['domain'] as String?,
        scope: c['scope'] as String?,
        bokReferences: (c['bok_references'] as List? ?? const [])
            .cast<String>(),
        figure: figureObj,
        figureDependent: c['figure_dependent'] == true,
        source: location,
      ),
    );
  }
  return cards;
}
