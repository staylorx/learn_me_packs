# Provenance — skeleton pack

Every card in this pack is a "X is part of Y" fact derived from the **UBERON
anatomy ontology** (the `part_of` relationship, BFO:0000050). The conversion is
mechanical (fetch term → fetch part_of parents → emit card); no content was
added or rewritten by hand.

## Source

- **Ontology:** UBERON (Uberon Multi-species Anatomy Ontology)
- **Served by:** EMBL-EBI Ontology Lookup Service (OLS)
  `https://www.ebi.ac.uk/ols4/ontologies/uberon`
- **License:** CC-BY-3.0 (Attribution 3.0 Unported)
  https://creativecommons.org/licenses/by/3.0/
- **Term source:** each card's `source` is the UBERON term IRI
  (e.g. `http://purl.obolibrary.org/obo/UBERON_0000976`); `bok_references`
  carries the `UBERON:xxxx` id.

## Conversion record

- Tool: the learn_me pack builder in `learn_me_core`, `rdf-owl` adapter.
- Each term's `part_of` parents (BFO:0000050) become "X is part of Y" cards.
- Terms selected: the human skeletal bones (see the pack's card list).
- Deck id: `us-skeleton`.
- License: `CC0-1.0` (derived from CC-BY-3.0 UBERON, with attribution).

## Retired key, deliberately not re-emitted

Each card in this pack still carries a `shape` field from before the engine
retired that concept (a card declares no kind now: its options, or their absence,
are what it is). The importer ignores an unknown key, so the pack works as it is,
and it was left byte-identical on purpose: re-emitting it through the builder
keeps all 109 cards but **changes their ids** (measured 2026-10-22), and an id
change is how a re-import loses the review history the ids exist to preserve.

So the stale key stays until there is a reason to regenerate the pack properly —
which means rebuilding from the UBERON term list recorded above, not round-tripping
the file.

## License

The converted pack is `CC0-1.0` (public domain), derived from CC-BY-3.0 UBERON
with attribution. Full terms: [LICENSE.md](LICENSE.md).

## Status

Shipped. `packs/skeleton.json` holds 109 "X is part of Y" cards across 29
human skeletal bone terms. Each card's `id` is `UBERON:<term>-<parent-slug>`,
unique per (term, parent), so the JSON importer keeps every card (a bare
`obo_id` would collide across parents and be dropped as a duplicate). Verified
end-to-end: the pack imports cleanly through `JsonDeckParser` (109 cards, text
fronts present).
