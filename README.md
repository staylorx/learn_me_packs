# learn_me_packs

Flashcard/fact packs for the [learn_me](https://github.com/taybiz/learn_me)
spaced-repetition engine, in the learn_me **`DeckDocument` interchange format**
(JSON). Every pack is exactly what `learn_me deck import --format json` reads.

Packs only — no source code. Packs are built with the pack builder in
[`learn_me_core`](https://github.com/taybiz/learn_me_core)
(`packages/pack-builder/`).

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

The manifest is **derived output, never hand-edited** — regenerated from the
packs on disk by the pack builder, so it can't drift.

Apps filter this inventory by `license` / `subject` / `tags` / `age` to decide
what a user can import from a registered pack endpoint.

## How this repo is laid out

**One folder per pack group.** Each group carries its own license and provenance,
called out explicitly so terms never get mixed or lost across packs:

| Pack group | Content | License |
|------------|---------|---------|
| [`fcc_radio/`](fcc_radio/) | U.S. Amateur Radio FCC/NCVEC question pools (Technician / General / Extra) | `CC0-1.0` |
| [`skeleton/`](skeleton/) | Human skeletal anatomy "X is part of Y" facts (UBERON) | `CC0-1.0` (derived from CC-BY-3.0) |

Each group has:
- **`packs/`** — the JSON `DeckDocument` packs,
- **`LICENSE.md`** — the license for that group's converted content,
- **`PROVENANCE.md`** — the source corpora, versions, figures, and conversion record,
- **`README.md`** — the group's format.

## License of this repo

The **pack contents** carry the license of their pack group (see the `LICENSE.md`
inside each group — the source corpora and derivative packs are attributed
there). No copyrighted deck material is redistributed here; all sources are open
licensed and pointed to rather than claimed.
