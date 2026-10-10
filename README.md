# learn_me_packs

Flashcard/fact packs for the [learn_me](https://github.com/taybiz/learn_me)
spaced-repetition engine, in the learn_me **`DeckDocument` interchange format**
(JSON). Every pack is exactly what `learn_me deck import --format json` reads.

## The root manifest — the pack inventory

[`manifest.json`](manifest.json) at the repo root is the **inventory** an app
that registers a pack endpoint reads: which packs it can import, under what
license, by subject/tag/age. It is part of the learn_me pack spec; the shape is
locked by [`manifest.schema.json`](manifest.schema.json).

```json
{
  "spec": "learn-me-pack-manifest",
  "version": 1,
  "packs": [
    {
      "id": "us-technician-2018-2022",
      "file": "fcc_radio/packs/technician_2018-2022.json",
      "title": "US Amateur Radio Technician (2018-2022)",
      "subject": "amateur-radio",
      "tags": ["fcc", "ncvec", "license-exam", "us"],
      "age": "16+",
      "license": "CC0-1.0",
      "cards": 423,
      "algorithm": "sm2",
      "source": "NCVEC FCC Technician Question Pool (2018-2022)",
      "source_url": "https://www.ncvec.org/index.php/amateur-question-pools"
    }
  ]
}
```

The manifest is **derived output, never hand-edited**, so it can't drift from
the packs on disk. Two ways it gets written:

- `tools/pack_builder.dart --manifest <path>` — register a pack while building
  it (fresh builds).
- `tools/manifest_build.dart` — regenerate the whole manifest directly from the
  existing pack files, reading each pack's own deck-level metadata + card count.
  This is what produced the committed `manifest.json`; it keeps the packs
  byte-identical (re-emitting a pack through the builder can drift cosmetic
  deck-level fields like `domain`).

Apps filter this inventory by `license` / `subject` / `tags` / `age` to decide
what a user can import from a registered pack endpoint.

## How this repo is laid out

**One folder per pack group.** Each group carries its own license and provenance,
called out explicitly so terms never get mixed or lost across packs:

| Pack group | Content | License |
|------------|---------|---------|
| [`fcc_radio/`](fcc_radio/) | U.S. Amateur Radio FCC/NCVEC question pools (Technician / General / Extra) | `CC0-1.0` |

Each group has:
- **`packs/`** — the JSON `DeckDocument` packs,
- **`LICENSE.md`** — the license for that group's converted content,
- **`PROVENANCE.md`** — the source corpora, versions, figures, and conversion record,
- **`README.md`** — the group's format + regenerate docs.

## The pack builder

`tools/pack_builder.dart` is a generic Dart tool (this is a Dart shop) that
takes **1..N sources** — local files or http(s) URLs, each parsed by a format
adapter (`fcc-pool`, `anki`, `rdf-owl`, `deck-doc`, …) — then wrangles, merges,
dedupes by content, sorts, and emits ONE `DeckDocument` pack. Every pack
carries its license + provenance at deck level:

```bash
dart run tools/pack_builder.dart \
  --out fcc_radio/packs/technician_2018-2022.json \
  --deck us-technician-2018-2022 \
  --license CC0-1.0 \
  --source-name "NCVEC FCC Technician Question Pool (2018-2022)" \
  --source-url "https://www.ncvec.org/index.php/amateur-question-pools" \
  --title "US Amateur Radio Technician (2018-2022)" \
  --subject amateur-radio --tags "fcc,ncvec,license-exam,us" --age "16+" \
  --manifest manifest.json \
  --source "fcc-pool:$SRC/generated/US-Technician-2018-2022.json"
```

Post-build, `--manifest <path>` upserts this pack's row into the root
[`manifest.json`](manifest.json) (the inventory above); `--title`/`--subject`/
`--tags`/`--age` fill the row. Adapters include `deck-doc`, which re-ingests an
existing pack (the builder's own output) so a repo's inventory can be
regenerated idempotently without re-running the original source pipeline.

Format, build commands, and adapter docs: see each pack group's README and the
header of `tools/pack_builder.dart`.

## License of this repo

The **conversion tooling** (`tools/`) is generic code written for this project;
the **pack contents** carry the license of their pack group (see the `LICENSE.md`
inside each group — the source corpora and derivative packs are attributed
there). No copyrighted deck material is redistributed here; all sources are open
licensed and pointed to rather than claimed.

## Notes / deferred

Open questions, pending decisions and future work live in
[`BACKLOG.md`](BACKLOG.md), not here.
