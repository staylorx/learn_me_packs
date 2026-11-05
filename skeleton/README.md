# Human Skeletal Anatomy Pack (illustrated, from UBERON)

An illustrated flashcard deck for the human skeleton, in the learn_me
`DeckDocument` interchange format — one JSON file. A pack is exactly what
`learn_me deck import --format json` reads, so any learn_me install can consume
it without a custom import path.

## Packs

| Pack | License | Cards |
|------|---------|-------|
| `packs/skeleton.json` | `CC0-1.0` (derived from CC-BY-3.0 UBERON, with attribution) | see `manifest.json` |

## What is in it

The deck teaches the **skeleton as a tree** and the structures in it, one fact
per card, in three shapes:

| Card | Front | Back | Why |
|------|-------|------|-----|
| **locate** | *"The sternum is part of which structure?"* | *the thoracic cage* — with the structure's own plate under the answer | the relation is stated, not left to be guessed |
| **clue** | *"Which flat bone runs down the middle of the chest and joins the ribs at the front?"* | *The sternum.* | one prompt, one unambiguous answer |
| **members** | *"The forearm is made up of the radius and the \_\_\_\_."* | *the ulna.* | the sibling facts link to each other |

A structure is therefore quizzed in both directions — from the name to the
region it belongs to, and from a description back to the name — and each card
carries the **immediate** anatomical parent rather than everything UBERON's
`part_of` closure drags in.

**Media.** The locate cards carry a public-domain **Gray's Anatomy (1918)**
plate of the structure on the answer side, so flipping a card shows what the
term actually is. The plates travel inline (base64) with a caption naming the
structure; a serving surface that can render media shows the picture, and one
that cannot still reads the text.

Every pack carries its license + provenance at deck level — `source_license`,
`license_url`, `source`, `provenance` — so the terms travel with the data even
when the engine re-exports it. UBERON is a CC-BY-3.0 (not share-alike) source;
a CC-BY derivative may be released under CC0 with attribution, which is what
this pack does. Gray's Anatomy (1918) is public domain. See
[PROVENANCE.md](PROVENANCE.md) for the full source + license record.

The deck id (`us-skeleton`) is stable, so a regenerated corpus keeps the same id
and re-importing reuses cards instead of duplicating them.

## The format

This is the learn_me **JSON deck document** — the same shape the engine's
`JsonDeckParser` reads and its `InterchangeDeckFileExporter` writes
(`packages/parser-json`). One document, one field mapping; a deck can go out and
come back the same deck. A side is its words, its media, or both.

```json
{
  "deck": "us-skeleton",
  "domain": "anatomy",
  "source_license": "CC0-1.0",
  "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
  "source": "Curated human-skeleton hierarchy from the UBERON anatomy ontology, illustrated with Gray's Anatomy (1918) plates",
  "provenance": { "source_url": "https://www.ebi.ac.uk/ols4/ontologies/uberon" },
  "cards": [
    {
      "id": "us-skeleton-sternum-part-of",
      "front": "The sternum is part of which structure?",
      "back": {
        "text": "the thoracic cage",
        "media": [
          {
            "kind": "image",
            "handle": "<sha256>.png",
            "mime_type": "image/png",
            "data": "<base64 bytes>",
            "caption": "The sternum — Gray's Anatomy (1918), public domain."
          }
        ]
      },
      "domain": "anatomy",
      "scope": "skeleton",
      "bok_references": "UBERON:0000975"
    }
  ]
}
```

### Card fields

| Field | Means |
|-------|-------|
| `id` | `<deck>-<structure>-<kind>`, stable per fact so a re-import reuses the card. |
| `front` | The prompt — text, or `{text, media}` when a side carries a picture. |
| `back` | The answer — text, or `{text, media}`. |
| `domain` | `anatomy` for every card in this deck. |
| `scope` | `skeleton` — the scope the deck studies under. |
| `bok_references` | The `UBERON:xxxx` id the fact came from, when it came from UBERON. |

### Why JSON (not YAML)

This is the house convention. The learn_me engine's native interchange is the
JSON `DeckDocument` above, which a JSON pack maps onto one-to-one with **zero
schema to maintain** — the parser already enforces it. YAML would have invented
a *second* schema to keep in sync instead of reusing the one the app already
reads.

## Source

Built with the learn_me pack builder (`rdf-owl` source adapter) from the
[UBERON](https://www.ebi.ac.uk/ols4/ontologies/uberon) `part_of` relations,
curated to the immediate anatomical parent and phrased as explicit prompts, and
illustrated with Gray's Anatomy (1918) plates from Wikimedia Commons.

Full source + license record: [PROVENANCE.md](PROVENANCE.md).

## See also

- [learn_me `parser-json`](https://github.com/taybiz/learn_me) — the reader/writer
  of this format.
- [UBERON anatomy ontology](https://www.ebi.ac.uk/ols4/ontologies/uberon)
