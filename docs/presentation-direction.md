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

The playback integration is present but no approved spoken takes are bundled yet. An empty manifest
means silent dialogue; synthesized kitchen cues are not character voices. The voice control is shown
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
