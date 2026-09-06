# Quiet, non-pixel narrative presentation

The requested direction takes emotional pacing, pauses and character blocking as inspiration,
not the pixel art, characters, music or assets of To the Moon or A Bird Story. Keep original
soft-colored low-poly scenery and give each location a recognizable silhouette and lived-in props.

## Implemented pass

- All six 3D chapters share eased acceleration/braking, bounded turns and a blended walk-to-idle
  pose. Motion still uses CharacterBody3D collisions; dialogue immediately locks horizontal travel.
- Dialogue gently pushes the camera toward the player and nearest already-visible character.
  Both turn toward one another. Wide composition returns during exploration. Camera can be disabled;
  no camera movement, transition or audio callback confirms facts or advances narrative.
- Chapters 3–6 fade in at scene changes. Skipping dialogue remains under player control.
- Photo studio: drying photographs, darkroom curtain, window, work mat and books. Store: tile floor,
  striped canopy, shelves and warm evening lamps. Breakwater: concrete joints, tide-colored footing,
  distant lighthouse, islands and slow water streaks. Station: road, trees, waiting shelter, luggage
  and more detailed bus. Surrounding scenery remains outside playable collision bounds.
- The visual workflow records a fixed-frame actual Godot camera/movement reel and screenshots.
  The final-arc screenshot suite checks the refined sets and their story-dependent states.

## Voice handoff

Two Chinese audition takes cover the third-chapter opening's three spoken sentences. They are
generated samples, not approved final casting or a full dub. Stage directions remain unvoiced.
Missing manifest entries mean silent dialogue; kitchen cues are not character voices. The voice control is shown
only when a manifest has takes. It mutes locally; missing clips remain silent; advancing/stopping or
hiding the view stops old audio. Audio completion never advances the story.

Run `godot --headless --path . --script scripts/export_voice_lines.gd` to produce
`build/voice/lines.csv`: 154 unique authored dialogue blocks with source references and exact-text
SHA-256 identifiers. This is a recording worklist, not a complete validated dub: dynamically composed
chapter-two lines also need their final displayed strings checked when recording.

Put accepted original/licensed takes in `assets/voice/` and map the exact display-text SHA-256 to
`res://assets/voice/<take>.ogg` in `manifest.json`. Changing a subtitle intentionally invalidates its
old take. One file currently corresponds to one display block (which can contain multiple speakers).
For character casting, assemble the named performances with natural gaps before mapping the block.
Do not speak the character-name labels or stage directions unless they are intended narration.
Keep explicit pauses and background ambience separate from evidence sounds.

Suggested casting: Lin Che, restrained young adult male; Shiori, quiet adult female with dry humor;
Lin Yao, warm but independent adult female; the older keeper, hesitant and plain-spoken. Avoid
celebrity or game-character imitation. Audition ordinary conversation before emotional scenes.
Human listening, pronunciation (especially 栞), mix balance and distribution rights must be checked
before takes are treated as release assets. This pass does not claim a finished six-chapter dub,
custom facial rigs, full cinematic choreography or final production art.

## Sample provenance

Generated on 2026-09-06 with the user-connected AI Voice Generator from this project's original text:

- Shiori, delicate preset: https://www.aidocmaker.com/g0/audio?name=dc1faecaa2a54c348facd66ec8411ba9
- Lin Che, normal preset: https://www.aidocmaker.com/g0/audio?name=efc1132f715240958adf37c63ca35b25
- Shiori, delicate preset: https://www.aidocmaker.com/g0/audio?name=8ee2869a55774e03b44a75c6d76c40ff

Complete short-preview MP3 responses were converted to mono 24 kHz Ogg Vorbis. First block has
0.5 seconds lead-in and 0.2 seconds tail; second block joins Lin Che and Shiori with 0.45 seconds
between takes and 0.2 seconds tail. No voice cloning or soundtrack assets were used. The service's
preset names do not guarantee actor identity or gender. These demo takes need human listening and
final casting/distribution review before public release. Raw Ogg files are included in exports and
decoded directly so clean headless test runs do not depend on an editor import cache.

## Authored dialogue blocking

Selected chapter 3, 5 and 6 display blocks now name an on-stage actor instead of
choosing whichever person happens to be nearest. Shiori pauses before turning away
when refusing the recording, and faces the player again after that boundary is respected.
The studio admission reply targets Shen; dinner targets Xu; the shared station photo
targets Shiori. Missing or hidden actors are never revealed or replaced by bystanders.

These are visual pauses, not input locks or automatic dialogue advances. Repeated UI
refreshes preserve beat time; a new line or room resets it. Camera OFF disables the
turns. Other dialogue retains the existing proximity framing. This is a small authored
pass, not full chapter choreography or timed lip sync; no new voice takes are included.
