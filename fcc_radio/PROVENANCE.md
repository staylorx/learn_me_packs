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

## License

The converted packs are `CC0-1.0` (public domain). The underlying pool text is a
U.S. government work and also public domain. Full terms: [LICENSE.md](LICENSE.md).
