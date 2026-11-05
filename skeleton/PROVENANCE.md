# Provenance — skeleton pack

## What the deck is

An illustrated deck of **human skeletal anatomy**: the `part_of` hierarchy of
the skeleton, one fact per card, in three atomic shapes — *locate* ("The sternum
is part of which structure?"), *clue* ("Which flat bone runs down the middle of
the chest…?") and *members* (a cloze linking two members of a region) — with a
public-domain anatomy plate on each structure's locate card.

## Sources

### UBERON anatomy ontology — CC-BY-3.0

- **Ontology:** UBERON (Uberon Multi-species Anatomy Ontology), served by the
  EMBL-EBI Ontology Lookup Service —
  `https://www.ebi.ac.uk/ols4/ontologies/uberon`
- **License:** CC-BY-3.0 (Attribution 3.0 Unported) —
  https://creativecommons.org/licenses/by/3.0/
- **Relation used:** `part_of` (BFO:0000050).
- **What was used:** the structure list and the containing-structure relation.
  Each card's `bok_references` carries the `UBERON:xxxx` id the structure came
  from.
- **Curation (this is a derivative, and the changes are these):** UBERON's
  `part_of` assertions mix the anatomical parent with developmental nodes
  (cartilage elements, primordia, the sclerotome, "bone tissue") and broad
  groupings, and some of them are asserted in a direction anatomy does not read
  (UBERON carries `sternum part_of rib`). The deck keeps the **immediate
  anatomical parent** only, drops the developmental and broad parents, and
  phrases every relation explicitly.

### Gray's Anatomy of the Human Body (1918) — public domain

- **Plates:** fetched from Wikimedia Commons via `Special:FilePath` at 560 px
  (`https://commons.wikimedia.org/wiki/Category:Gray%27s_Anatomy_plates`).
- **License:** public domain (published 1918).
- **Processing:** flattened on white, greyscaled, resized to at most 640 px wide,
  and reduced to a 16-colour palette PNG (line art, so this is near-lossless and
  keeps the bytes small — the pictures travel inline in the deck document).
- Each plate carries a caption naming the structure and the source.
- Each image's bytes are embedded inline (base64) under the content handle the
  learn_me media store derives for them (SHA-256 of the bytes plus the extension
  for their MIME type), so a re-import lands the same picture under the same
  handle.

## Conversion record

- **Tool:** the learn_me pack builder in `learn_me_core`
  (`packages/pack-builder/`, `rdf-owl` adapter) for the UBERON structure list and
  its `part_of` parents; the curated hierarchy, the prompts and the plates were
  assembled into the pack from that.
- **Deck id:** `us-skeleton` (stable — a regenerated corpus keeps the same id).
- **Card ids:** `us-skeleton-<structure>-part-of`, `us-skeleton-<structure>-clue`,
  `us-skeleton-<parent>-members-<member>`.
- **License:** `CC0-1.0` (derived from CC-BY-3.0 UBERON, with attribution).

## This rebuild replaces the earlier mechanical dump

The first version of this pack (109 cards) was a mechanical conversion: front =
UBERON's label, back = one raw `part_of` parent, no media. It read as a word
association (*Sternum → Rib*) with the relation left unstated, it carried
developmental and overly broad parents, and it had no pictures, which made the
terms hard to tell apart.

This pack replaces it: 103 cards, 35 of them illustrated. The card ids changed,
so importing it **adds** the new cards beside the old ones — remove the earlier
`us-skeleton` import before importing this pack.

## Verification

Imported end-to-end through the engine's own `JsonDeckParser` with a media store
wired (throwaway test, since removed): **103/103 cards imported, no issues
reported, 35 cards carrying a picture**, and the sternum card answers *the
thoracic cage*.

## License

The converted pack is `CC0-1.0` (public domain), derived from CC-BY-3.0 UBERON
with attribution and using public-domain Gray's Anatomy plates. Full terms:
[LICENSE.md](LICENSE.md).
