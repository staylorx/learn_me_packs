# Amateur Radio FCC Exam Flashcard Packs

Converted flashcard corpora for the US Amateur Radio license exams (FCC/NCVEC),
in the **learn_me `DeckDocument` interchange format** — one JSON file per license
level. A pack is exactly what `learn_me deck import --format json` reads, so any
learn_me install can consume these without a custom import path.

## Packs

| Pack | License | Pool period | Cards | Figure-dependent | Embedded figures |
|------|---------|-------------|-------|------------------|------------------|
| `packs/technician_2018-2022.json` | Technician | `CC0-1.0` | 2018-2022 | 423 | 12 | 12 |
| `packs/general_2019-2023.json` | General | `CC0-1.0` | 2019-2023 | 454 | 5 | 5 |
| `packs/extra_2020-2024.json` | Extra | `CC0-1.0` | 2020-2024 | 622 | 27 | 27 |

**Total: 1,499 cards, 44 figure-dependent, 44 figures embedded.**

Every pack carries its license + provenance at deck level — `source_license`,
`license_url`, `source`, `provenance` — so the terms travel with the data even
when the engine re-exports it. The FCC/NCVEC pools are U.S. government works
(47 CFR Part 97) in the public domain; the converted packs are released `CC0-1.0`.
See [PROVENANCE.md](PROVENANCE.md) for the full source + license record.

Each deck id (`us-technician-2018-2022`, …) derives from the pool filename, so a
regenerated corpus keeps the same id and re-importing reuses cards instead of
duplicating them.

## The format

This is the learn_me **JSON deck document** — the same shape the engine's
`JsonDeckParser` reads and its `InterchangeDeckFileExporter` writes
(`packages/parser-json`). One document, one field mapping; a deck can go out and
come back the same deck.

```json
{
  "deck": "us-extra-2020-2024",
  "algorithm": "sm2",
  "domain": "Extra",
  "source_license": "CC0-1.0",
  "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
  "source": "NCVEC FCC Extra Question Pool (2020-2024)",
  "provenance": {
    "source_url": "https://www.ncvec.org/index.php/amateur-question-pools",
    "sources": ["fcc-pool:US-Extra-2020-2024.json"]
  },
  "cards": [
    {
      "id": "E5C10",
      "front": "Which point on Figure E5-1 best represents the impedance …",
      "shape": "simple_mcq",
      "options": [
        {"label": "A", "text": "…", "score": 0},
        {"label": "B", "text": "…", "score": 5},
        {"label": "C", "text": "…", "score": 0}
      ],
      "domain": "E5C",
      "bok_references": "97.301",
      "figure_dependent": true,
      "figure": {
        "kind": "image",
        "mime_type": "image/png",
        "data": "<base64 bytes>"
      }
    }
  ]
}
```

### Card fields

| Field | Means |
|-------|-------|
| `id` | FCC pool serial (e.g. `T1A01`, `G7A09`); the card's stable identity — re-import reuses the card. |
| `front` | The question text (always text; see the figure note below). |
| `shape` | `simple_mcq` — one best answer among options (each FCC question has a single correct choice). |
| `options` | Answer choices with explicit scores; best = 5, distracters = 0. |
| `domain` | The FCC subelement group (e.g. `T1A`, `E5C`); lets the deck sort/filter in-app. |
| `bok_references` | The FCC rulebook (CFR Part 97) citation, e.g. `97.301(d)`. |
| `figure_dependent` | `true` when the answer needs a figure referenced in the question. |
| `figure` | Embedded media object (bytes, base64) for that figure — present on every `figure_dependent` card. |

### How figures travel

A card side in learn_me is **text *or* media**, not both — so the question keeps
`front`, and the figure's bytes ride as a sibling `figure` media object with the
`mime_type` and base64 `data`. No image is lost: the bytes are the pack.

Today the engine **withholds** a `figure_dependent` card when no asset is attached
("skipped rather than asked blind"). These packs attach the asset, so a serving
surface that learns to render `figure` can start serving them — the flag is what
it already uses to decide safe vs. not. Until then the cards are present and
fidelity-complete even though the engine skips them at study time.

### Why JSON (not YAML)

This is the house convention. `breadalone_packs` ships JSON packs validated by
JSON Schema; the learn_me engine's native interchange is the JSON `DeckDocument`
above, which a JSON pack maps onto one-to-one with **zero schema to maintain** —
the parser already enforces it. YAML would have invented a *second* schema to
keep in sync instead of reusing the one the app already reads.

## Convert / regenerate

The converter is a generic **pack builder** — a Dart tool (this is a Dart shop),
`tools/pack_builder.dart` at the repo root, that takes **1..N sources** (local
JSON *or* http(s)
URL), each parsed by a format adapter, merges them, dedupes by content (front +
best answer; richer card wins), sorts, and emits ONE learn_me DeckDocument pack.
The FCC question-pool schema is one adapter (`fcc-pool`); the pipeline is
`wrangle -> parse -> merge/dedupe -> sort -> emit` and is not FCC-specific —
an Anki or JSON-interchange adapter is a drop-in.

```bash
export PATH="<fvm>/default/bin:$PATH"   # fvm-managed Dart, not on PATH by default
SRC='<clone>/data/us'                    # BaksiLi/RadioExamToolkit clone
# one source -> one pack (run from the repo root, where pubspec.yaml lives):
dart run tools/pack_builder.dart \
  --out fcc_radio/packs/technician_2018-2022.json \
  --deck us-technician-2018-2022 \
  --license CC0-1.0 \
  --source-name "NCVEC FCC Technician Question Pool (2018-2022)" \
  --source-url "https://www.ncvec.org/index.php/amateur-question-pools" \
  --source "fcc-pool:$SRC/generated/US-Technician-2018-2022.json" \
  --images "$SRC/images"
# N sources for the same pool -> merged + deduped (richer card wins):
dart run tools/pack_builder.dart \
  --out fcc_radio/packs/extra_2020-2024.json \
  --deck us-extra-2020-2024 \
  --source "fcc-pool:$SRC/generated/US-Extra-2020-2024.json" \
  --source "fcc-pool:https://raw.githubusercontent.com/<org>/<repo>/US-Extra.json" \
  --images "$SRC/images"
```

Sources can be a URL — the tool fetches it. `--deck` fixes the deck id so a
regenerated corpus keeps the same id and re-import reuses cards; omit it to
derive the id from the first source's filename. Pass **native Windows paths**
(`C:/…`) to `--source`/`--images` — MSYS `/c/…` paths fail with
PathNotFoundException.

Source pools are the FCC/NCVEC public-domain question pools, parsed into JSON by
[BaksiLi/RadioExamToolkit](https://github.com/BaksiLi/RadioExamToolkit) (which
also carries the figure images, in `data/us/images/`). The
[jrf/anki_amateur_radio](https://github.com/jrf/anki_amateur_radio) repo embeds
the same figures in SVG form for the newer pools. NCVEC rotates pools on a
4-year cycle (July 1); to move to the current pool, re-run `pack_builder.dart`
against the updated source.

Raw source texts and provenance: see [`sources/`](../sources/PROVENANCE.md).

## Notes / deferred

Open items, pending decisions and future work live in
[`BACKLOG.md`](../BACKLOG.md), not here.

## See also

- [learn_me `parser-json`](https://github.com/taybiz/learn_me) — the reader/writer
  of this format.
- `breadalone_packs` — the sibling pack-source repo whose layout this mirrors
  (JSON packs + `schema/` + `FORMAT.md`, no per-pack code).
- [NCVEC Amateur Question Pools](https://www.ncvec.org/index.php/amateur-question-pools)
