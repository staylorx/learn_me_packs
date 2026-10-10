// raw_cards.dart — the normalised intermediate + shared helpers for
// pack_builder's format adapters.
//
// Every adapter (fcc-pool, anki, …) produces List<RawCard>; the emitter writes
// them as a learn_me DeckDocument. "One shape in the middle" is what keeps the
// tool generic — sources disagree wildly but land in the same format.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class RawOption {
  RawOption(this.label, this.text, this.score, [this.rationale]);

  final String label;
  final String text;
  final int score;
  final String? rationale;

  Map<String, Object?> toJson() => {
        'label': label,
        'text': text,
        'score': score,
        if (rationale != null && rationale!.isNotEmpty) 'rationale': rationale,
      };
}

class Figure {
  Figure({required this.ref, required this.bytes, required this.mime});

  final String ref;
  final List<int> bytes;
  final String mime;

  Map<String, Object?> toJson() => {
        'kind': 'image',
        'mime_type': mime,
        'data': base64Encode(bytes),
      };
}

class RawCard {
  RawCard({
    required this.id,
    required this.front,
    this.back,
    this.options = const [],
    this.domain,
    this.scope,
    this.bokReferences = const [],
    this.figure,
    this.figureDependent = false,
    this.media = const [],
    this.source = '',
  });

  final String id;
  final String front;
  final String? back;
  final List<RawOption> options;
  final String? domain;
  final String? scope;
  final List<String> bokReferences;

  /// Primary figure for FCC-style figure questions (single diagram).
  final Figure? figure;

  /// All media (images/audio) found on a card's faces, e.g. from an Anki deck
  /// where a card may carry several images. Kept separate from [figure] so
  /// nothing is dropped; the engine ignores both keys today but a serving
  /// surface can render them. "The bytes are the pack."
  final List<Figure> media;

  final bool figureDependent;
  final String source;

  Map<String, Object?> toCardJson() => {
        'id': id,
        'front': front,
        if (back != null && back!.isNotEmpty) 'back': back,
        'shape': options.length > 1 ? 'simple_mcq' : 'plain',
        if (options.isNotEmpty) 'options': [for (final o in options) o.toJson()],
        if (domain != null && domain!.isNotEmpty) 'domain': domain,
        if (scope != null && scope!.isNotEmpty) 'scope': scope,
        if (bokReferences.isNotEmpty) 'bok_references': bokReferences,
        if (figureDependent) 'figure_dependent': true,
        if (figure != null) 'figure': figure!.toJson(),
        if (media.isNotEmpty) 'media': [for (final m in media) m.toJson()],
      };
}

/// Content handle: identity over the card's meaning. The engine derives its own
/// fact handle the same way (content-derived, so re-adding reuses history). Here
/// it is the dedupe key: two sources with the same question (front + best
/// answer) collapse to one card.
String contentHandle(RawCard c) {
  final best = c.options.where((o) => o.score > 0).map((o) => o.text).join('|');
  final buffer = StringBuffer()
    ..write(clean(c.front))
    ..write('@@')
    ..write(clean(best));
  return buffer.toString();
}

/// Collapse whitespace and normalise line endings for identity and display.
String clean(String s) =>
    s.replaceAll(RegExp(r'\r\n'), '\n').replaceAll(RegExp(r'\s+'), ' ').trim();

String mimeFor(String filename) {
  if (filename.endsWith('.jpg') || filename.endsWith('.jpeg')) return 'image/jpeg';
  if (filename.endsWith('.png')) return 'image/png';
  if (filename.endsWith('.gif')) return 'image/gif';
  if (filename.endsWith('.webp')) return 'image/webp';
  if (filename.endsWith('.svg')) return 'image/svg+xml';
  if (filename.endsWith('.mp3')) return 'audio/mpeg';
  if (filename.endsWith('.wav')) return 'audio/wav';
  if (filename.endsWith('.ogg')) return 'audio/ogg';
  return 'application/octet-stream';
}

/// Fetch a URL as bytes. Used by adapters that accept http(s) locations.
Future<List<int>> httpGet(String url) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse(url));
    final resp = await req.close();
    if (resp.statusCode != 200) {
      throw HttpException('GET $url -> ${resp.statusCode}');
    }
    final buf = BytesBuilder();
    await for (final chunk in resp) {
      buf.add(chunk);
    }
    return buf.takeBytes();
  } finally {
    client.close();
  }
}

/// Read a local file or a URL into bytes.
Future<List<int>> readLocation(String location) async =>
    location.startsWith('http://') || location.startsWith('https://')
        ? httpGet(location)
        : File(location).readAsBytesSync();
