# CHANGELOG — learn_me_packs / amateur_radio

Dated deliveries. Decisions and completed work live here; BACKLOG.md holds
only open/pending items.

## 2026-10-09 — anki adapter for pack_builder

Added `tools/anki_apkg.dart` (self-contained Anki `.apkg` adapter) to
`tools/pack_builder.dart` via the `anki` source format. Verbatim brief: *"if you
can find some gross anatomy anki decks, bring those over and use them to test
your imports after building out the anki stuff."*

- Extracts zip → sqlite (`collection.anki2`/`.anki21`), reads models/notes/cards,
  parses **basic 2-field** notes (front/back), embeds media (`<img>` and
  `[sound:...]`) as bytes in the card's `media`/`figure` fields.
- Skips cloze/complex notes (counted, logged), mirroring `parser-anki`'s
  existing skip behavior.
- **Smoke-tested on real apkg files:**
  - `US_Amateur_Radio_-_Technician_good_July_2022_-_June_2026.apkg` → 411 cards,
    12 with media.
  - `Amateur_Radio_Extra_Exam_2020-2024_Flash_Cards.apkg` → 622 cards, 26 with
    media (all 26 embedded bytes verified as real JPEG/PNG, 18–55KB).
  - Round-tripped the 622-card Extra pack through the real learn_me
    `JsonDeckParser` → imported cleanly.
  - `Gross_Anatomy_154.apkg` (82MB / 3315 notes / 6052 images) → parsed without
    crashing; correctly skipped 2,900+ cloze + image-occlusion notes (only 18
    Basic notes produce cards). Serves as a resilience + skip-count smoke test.
- Kept **decoupled from `learn_me`'s `parser-anki`**: the adapter shares only the
  pack tool's `RawCard`/`Figure` intermediate, so the pack tool does not couple
  to where the anki importer ultimately resides (see BACKLOG residency item).

Download route learned: AnkiWeb's `.apkg` is behind the SvelteKit SPA — clicking
the Download button issues
`GET /svc/shared/download-deck/<id>?t=<signed-JWT>`; a bare `curl` to it or to
`/shared/info/<id>.apkg` returns the SPA HTML shell or a 429. Anonymous fetch of
a large deck is rate-limited; the reliable path is a real browser click
(verified with headless Chrome via CDP).

**Residency note for the user's "one or the other" concern:** the anki adapter
is intentionally self-contained (does not import `parser-anki`). When the
residency decision is made — move `parser-anki` out of core *or* move these pack
tools into core — this adapter either rides with the tools or can later delegate
to the engine's importer; nothing forces the choice today.
