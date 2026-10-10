// manifest_build.dart — regenerate the root manifest.json from existing packs.
//
// The manifest is derived output, but deriving it by re-emitting a pack through
// the builder can drift cosmetic deck-level metadata (`domain`, provenance
// source) that the original build set correctly. This tool reads each pack
// file's own deck-level fields + card count directly and writes the manifest,
// so the packs stay byte-identical to what is on disk.
//
// Usage — one `--file` per pack, followed by that pack's row extras (any flag
// applies to the most recent --file; the documented form groups them):
//
//   dart run tools/manifest_build.dart \
//     --manifest manifest.json \
//     --file fcc_radio/packs/technician_2018-2022.json --id us-technician-2018-2022 \
//       --title "US Amateur Radio Technician (2018-2022)" --subject amateur-radio \
//       --tags "fcc,ncvec,license-exam,us" --age 16+ \
//     --file fcc_radio/packs/general_2019-2023.json --id us-general-2019-2023 \
//       --title "US Amateur Radio General (2019-2023)" --subject amateur-radio \
//       --tags "fcc,ncvec,license-exam,us" --age 16+ \
//     --file fcc_radio/packs/extra_2020-2024.json --id us-extra-2020-2024 \
//       --title "US Amateur Radio Extra (2020-2024)" --subject amateur-radio \
//       --tags "fcc,ncvec,license-exam,us" --age 16+

import 'dart:io';

import 'manifest.dart';

Future<void> main(List<String> args) async {
  final manifestPath = flag(args, '--manifest');
  if (manifestPath == null) {
    stderr.writeln(
      'usage: dart run tools/manifest_build.dart --manifest <path> '
      '[--file <pack.json> [--id <id>] [--title <t>] [--subject <s>] '
      '[--tags <csv>] [--age <a>] ...]',
    );
    exit(2);
  }

  var count = 0;
  final fileIdx = <int>[];
  for (var j = 0; j < args.length - 1; j++) {
    if (args[j] == '--file') fileIdx.add(j);
  }

  for (final idx in fileIdx) {
    final packPath = args[idx + 1];
    final rest = args.sublist(idx + 1, args.length);
    final id = flag(rest, '--id') ?? _defaultId(packPath);
    final title = flag(rest, '--title');
    final subject = flag(rest, '--subject');
    final tags = flag(rest, '--tags');
    final age = flag(rest, '--age');

    final entry = manifestEntryFromPack(
      packPath: packPath,
      deckId: id,
      title: title,
      subject: subject,
      tags: tags == null
          ? const []
          : tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
      age: age,
    );
    count = upsertManifestEntry(manifestPath, entry);
  }

  if (count == 0) {
    stderr.writeln('no --file packs given; nothing written');
    exit(2);
  }
  stdout.writeln('Manifest $manifestPath now lists $count packs');
}

/// First value for [name] in [args], or `null` when absent.
String? flag(List<String> args, String name) {
  final i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

/// Deck id fallback: the pack filename without `.json`.
String _defaultId(String packPath) {
  final base = packPath.split(RegExp(r'[/\\]')).last;
  return base.replaceAll(RegExp(r'\.json$'), '');
}