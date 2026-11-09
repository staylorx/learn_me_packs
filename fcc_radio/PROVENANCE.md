# Provenance — fcc_radio packs

Every card in these packs traces to a public FCC/NCVEC question pool. The
conversion is mechanical (parse → dedupe → sort → emit); no content was added or
rewritten by hand.

## Source corpus

| Pool | Level | Period | Source (parsed JSON) |
|------|-------|--------|----------------------|
| Technician | 2018–2022 | 423 cards | BaksiLi/RadioExamToolkit `data/us/generated/US-Technician-2018-2022.json` |
| General | 2019–2023 | 454 cards | BaksiLi/RadioExamToolkit `data/us/generated/US-General-2019-2023.json` |
| Extra | 2020–2024 | 622 cards | BaksiLi/RadioExamToolkit `data/us/generated/US-Extra-2020-2024.json` |

- Primary source project: [BaksiLi/RadioExamToolkit](https://github.com/BaksiLi/RadioExamToolkit)
  — exports the FCC/NCVEC question pools to JSON, and carries the figure images
  in `data/us/images/`.
- Cross-checked against: [itinerarium/amateur-radio-licensing-study-decks](https://github.com/itinerarium/amateur-radio-licensing-study-decks)
  and [jrf/anki_amateur_radio](https://github.com/jrf/anki_amateur_radio) (the
  latter embeds the same figures in SVG for the newer pools).
- Authoritative pool authority: [NCVEC Amateur Question Pools](https://www.ncvec.org/index.php/amateur-question-pools).
  NCVEC rotates pools on a 4-year cycle (July 1).

## Figures

The 44 figure-dependent cards (12 Technician, 5 General, 27 Extra) embed figure
bytes from the BaksiLi `data/us/images/` directory (`E5-1.png`, `G7-1.png`, …).
The question text always carries the figure reference (e.g. "Figure E5-1"); the
bytes ride as a sibling `figure` media object.

## Conversion record

- Tool: the learn_me pack builder in `learn_me_core`, `fcc-pool` adapter.
- Deck ids are content-derived from the pool filename
  (`us-technician-2018-2022`, …), so re-importing reuses cards and keeps review
  history.
- Each pack record: `source_license`, `license_url`, `source`, `provenance`.
  See [LICENSE.md](LICENSE.md).

## Re-emission record

- 2026-10-22: re-emitted all three packs from the same BaksiLi pools after the
  engine's option format changed — an option states whether it answers the
  question (`correct`) instead of the points it earned (`score`). Card counts,
  ids, order, figures and the manifest rows are unchanged; the diff is the option
  key alone. The reader no longer accepts a `score`, so an un-rebuilt pack would
  import with no option marked correct.
- 2026-10-22 (second re-emission): the pool's meta-answer. Twenty-two Technician
  cards answer with "All of these choices are correct" (T0A02 among them — the
  health hazard of current through the body). Emitted as multiple-choice items,
  each marked three true statements false and left a flip that named none of them:
  the option list *was* the answer. They are answer cards now — no options, the
  branches listed one per line. Card counts, ids, order, domains and figures are
  unchanged, and General and Extra came out byte-identical, their pools not using
  the family.
- 2026-11-05 (third re-emission): the entry above was wrong about General and
  Extra — their pools use the same meta-answer, spelled "All these choices are
  correct" (no "of"). The builder recognised the family by a list of exact
  spellings that held Technician's wording but not this one, so sixteen General
  cards (G0A02, G0A03, G1A10, G1B08, G1E04, G2E03, G2E14, G3B02, G4A15, G4D03,
  G4E07, G5A10, G6A08, G6A13, G8A06, G9C10) and fifteen Extra cards shipped as
  ordinary choices whose answer read "D. All these choices are correct" and named
  none of the true statements. The check is a pattern now
  (`all (of) these/the (choices/above) [are correct]`), not a spelling list, and
  all three packs are re-emitted from the same BaksiLi pools. Technician is
  byte-identical; General and Extra change on those 31 cards alone — each is an
  answer card with the branches one per line, and no meta-option is marked
  correct anywhere in the corpus. Card counts, ids, order, domains, figures and
  the manifest rows are unchanged.
- 2026-11-05 (fourth re-emission): the deck-level `domain` is gone. It was the
  *first* card's domain written at the top of the file — an artifact of arrival
  order, read by nothing on either side, and the one key in the deck-level block
  the learn_me engine did not model. That mattered beyond tidiness: the engine's
  reader and writer each keep their own list of deck-level keys, so a key no
  reader modelled could not survive an import-then-export at all, and the block
  as a whole was being dropped (`source`, `license_url` and `provenance` too).
  The engine now models the block (a `DeckProvenance` on the deck, read on
  import and written back on export), so what is left here is exactly what a
  reader knows, and the README's promise — the terms travel with the data even
  when the engine re-exports it — holds. All three packs change on that one
  removed line; counts, ids, order, cards, figures and the manifest rows are
  unchanged.
- 2026-11-09 (fifth re-emission): two beta card flags on the Technician pack.
  (1) `T0C02` — *"it's a multiple choice but the choices aren't shown. They
  shouldn't be either in cards. This isn't a quiz."* A pool item is written for a
  paper choice form; on a recall card the flip shows only the answer, so a
  "which of the following …?" stem names a list the student never sees. All 345
  such fronts across the three packs are now direct questions — "Which of the
  following frequencies has …?" becomes "What frequency has …?", with the noun
  made singular only where deleting the phrase would leave it disagreeing with
  its verb (the pool's own typo, "What of the following instruments" on `E8A05`,
  is handled the same way). (2) `T6C08` — *"it references a diagram or image that
  isn't shown."* The 44 figure cards carried their bytes in a card-level `figure`
  key the learn_me reader never read, so the diagram never reached the served
  card. The figure now rides on the front side (`front.media`), the shape the
  engine's reader and writer already use, so a media-capable surface draws it.
  Card counts, ids, order, options, domains, `figure_dependent` and the manifest
  rows are unchanged; the diff is the rewritten fronts and the relocated figure
  bytes alone.

## License

The converted packs are `CC0-1.0` (public domain). The underlying pool text is a
U.S. government work and also public domain. Full terms: [LICENSE.md](LICENSE.md).
