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

## License

The converted pack is `CC0-1.0` (public domain), derived from CC-BY-3.0 UBERON
with attribution. Full terms: [LICENSE.md](LICENSE.md).
