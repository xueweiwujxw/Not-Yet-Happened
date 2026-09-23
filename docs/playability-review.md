# Guided play review — 2026-09-23

Problem: the shipping game opened a development-style text control sheet, concealed spatial
interaction targets, executed the first nearby choice with the primary button, and enabled
unreviewed voice auditions without persisting presentation preferences.

## Changes

- Shipping entry opens the kitchen. Notebook and manual save/load remain available.
- Objectives and interactable labels appear in the scene; chapter-two hints follow its time window.
- Q/F and controller shoulders select; primary input confirms. Multiple choices have no automatic default.
- Guided spatial play previews consequences before the keeper door, platform commitment and refusal override.
- Chapter-one/two completion continues into the next scene. Later chapters retain their existing transitions.
- Auditions default off; camera/voice preferences persist separately from narrative saves.
- Bundled font includes new interface glyphs. Preview CI captures the actual shipping entry.

## Completion review

Reviewed final changes for progression, shared-session ownership, input focus, stale selection,
confirmation cancellation, chapter navigation, preference failure handling and font coverage.
Resolved findings:

1. A subclassed entry was inherited by child chapters through `get_script().new()`: explicitly
   construct the chapter screen and test the real entry's chapter transition.
2. Screen stretching changed notebook fixture dimensions: configure the shipping window only.
3. Nested second-chapter HUD labels used viewport coordinates: transform into HUD coordinates.
4. New copy lacked bundled glyphs: regenerate from the documented upstream font, verify its SHA,
   and test guide/HUD coverage.
5. Rapid scene creation/disposal could start retiring ambience playback: defer initial playback
   and reject queued scene disposal. Retain mute assertions after the deferred start.
6. Confirmation was initially tied to preference injection: use an explicit guided-play flag.

Validation: all 27 Godot test suites pass on Godot 4.5.1; process-guard shell tests pass.
Real Mesa/OpenGL screenshots inspected at 1280x720 for entry, exploration, selected alternatives
and the keeper consequence prompt; existing kitchen renders also exercised 1600x1000.
No blocking local review findings remain. Cross-platform CI must pass before merge; use a merge
commit only, never squash or rebase.

## Limits

This is a playability pass, not a completed voice/art overhaul. Existing 55 audition blocks are
unchanged and still need casting, performance and pronunciation review. No human gamepad/device
playtest or measured full-story playtime is claimed. Saves remain manual and do not store position.
