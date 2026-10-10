# learn_me_packs

Flashcard/fact packs for the [learn_me](https://github.com/taybiz/learn_me)
spaced-repetition engine, in the learn_me **`DeckDocument` interchange format**
(JSON). Every pack is exactly what `learn_me deck import --format json` reads.

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
adapter (`fcc-pool`, `anki`, …) — then wrangles, merges, dedupes by content,
sorts, and emits ONE `DeckDocument` pack. Every pack carries its license +
provenance at deck level:

```bash
dart run tools/pack_builder.dart \
  --out fcc_radio/packs/technician_2018-2022.json \
  --deck us-technician-2018-2022 \
  --license CC0-1.0 \
  --source-name "NCVEC FCC Technician Question Pool (2018-2022)" \
  --source-url "https://www.ncvec.org/index.php/amateur-question-pools" \
  --images "$SRC/images" \
  --source "fcc-pool:$SRC/generated/US-Technician-2018-2022.json"
```

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
