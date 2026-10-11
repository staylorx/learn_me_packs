# Human Skeletal Anatomy Pack (from UBERON)

Converted flashcard facts for the human skeletal system, derived from the
**UBERON anatomy ontology**, in the learn_me `DeckDocument` interchange format
— one JSON file. A pack is exactly what `learn_me deck import --format json`
reads, so any learn_me install can consume it without a custom import path.

## Packs

| Pack | License | Cards |
|------|---------|-------|
| `packs/skeleton.json` | `CC0-1.0` (derived from CC-BY-3.0 UBERON, with attribution) | 109 |

**Total: 109 cards** — each a "X is part of Y" fact: front = the anatomical
term, back = its `part_of` parent in UBERON. No figures or media.

Every pack carries its license + provenance at deck level — `source_license`,
`license_url`, `source`, `provenance` — so the terms travel with the data even
when the engine re-exports it. UBERON is a CC-BY-3.0 (not share-alike) source;
a CC-BY derivative may be released under CC0 with attribution, which is what
this pack does. See [PROVENANCE.md](PROVENANCE.md) for the full source +
license record.

The deck id (`us-skeleton`) is stable, so a regenerated corpus keeps the same id
and re-importing reuses cards instead of duplicating them.

## The format

This is the learn_me **JSON deck document** — the same shape the engine's
`JsonDeckParser` reads and its `InterchangeDeckFileExporter` writes
(`packages/parser-json`). One document, one field mapping; a deck can go out and
come back the same deck.

```json
{
  "deck": "us-skeleton",
  "domain": "skeleton",
  "source_license": "CC0-1.0",
  "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
  "source": "UBERON anatomy ontology (human skeletal bones)",
  "provenance": {
    "source_url": "https://www.ebi.ac.uk/ols4/ontologies/uberon",
    "sources": ["rdf-owl:.../UBERON_0000976, ..."]
  },
  "cards": [
    {
      "id": "UBERON:0000976-humerus-forelimb-skeleton",
      "front": "Humerus",
      "back": "Forelimb skeleton",
      "shape": "simple",
      "bok_references": "UBERON:0000976"
    }
  ]
}
```

### Card fields

| Field | Means |
|-------|-------|
| `id` | `UBERON:<term>-<parent-slug>`, unique per (term, parent) so the JSON importer keeps every card. |
| `front` | The anatomy term (always text). |
| `back` | The term's `part_of` parent in UBERON. |
| `shape` | `simple` — a front/back prompt pair. |
| `bok_references` | The `UBERON:xxxx` term id. |

### Why JSON (not YAML)

This is the house convention. The learn_me engine's native interchange is the
JSON `DeckDocument` above, which a JSON pack maps onto one-to-one with **zero
schema to maintain** — the parser already enforces it. YAML would have invented
a *second* schema to keep in sync instead of reusing the one the app already
reads.

## Source

Packs are built with the pack builder in `learn_me_core`
(`packages/pack-builder/`, `rdf-owl` adapter — it fetches each term's `part_of`
parents from OLS). The source ontology is
[UBERON](https://www.ebi.ac.uk/ols4/ontologies/uberon), served by the EMBL-EBI
Ontology Lookup Service.

Full source + license record: [PROVENANCE.md](PROVENANCE.md).

## See also

- [learn_me `parser-json`](https://github.com/taybiz/learn_me) — the reader/writer
  of this format.
- [UBERON anatomy ontology](https://www.ebi.ac.uk/ols4/ontologies/uberon)