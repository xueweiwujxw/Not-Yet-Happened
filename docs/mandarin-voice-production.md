# Mandarin dialogue production

The old audition provider exposed generic styles rather than an explicit language/cast.
This pass uses `zh-CN` Mandarin voices for every spoken turn. It does not certify native-like
acting by counting clips or running automated tests; final listening approval is still pending.

## Runtime

- `dialogue_beats.gd` separates known speaker labels and explicitly authored embedded dialogue.
  Unrecognised prose/documents remain silent; narration is never guessed to be a character.
- `dialogue_cursor.gd` owns the local reading turn. One speaker's words appear at a time, with
  a separate nameplate. Primary input advances that turn; only the last turn advances the
  original session block and can commit its pending facts.
- Exact `(speaker, text)` hashes select independent clips. No stitched multi-person track and
  no fixed half-second inter-speaker silence. Replaying affects only the visible spoken turn.
- Original chapter blocks, event logs and save versions are unchanged. Returning from the
  notebook or loading a save restarts the current block; individual turn position is not saved.
- `turn-manifest.json` is the spatial UI's catalog. `manifest.json` and legacy recordings remain
  as archived compatibility/reference assets; there is no fallback from a missing new turn to
  an old accent or a full multi-person block.

## Reproduce auditions

Development-only requirements: Godot 4.5.1, Python, `edge-tts==7.2.8`, ffmpeg and ffprobe.
The optional adapter was chosen to address explicit Mandarin selection unavailable in the old
connected generator. It is not used by the shipped game or CI. The public speech service may
change; retaining source assets is essential. Generated assets remain available offline even if the provider changes.

```bash
godot --headless --path . --script scripts/export_voice_turns.gd
python -m pip install edge-tts==7.2.8
python scripts/build_mandarin_voice.py
```

Generation sends only the catalog's spoken text to Microsoft's Edge Read Aloud service. It
never sends save files, repository credentials, speaker names or stage directions. The script
respects the configured HTTPS proxy and CA; TLS verification remains enabled.

`mandarin-cast.json` pins a voice/rate for each character. There are only two available standard
female voices in this source, so adult roles share voices. The child roles are also auditions,
not confirmed child casting. No pitch-shifting trick is used to claim a different performer.

Candidates and resumable per-take checksums go to `build/voice/candidate/`. A changed speaker,
transcript, voice, rate or production recipe invalidates the cached take. The manifest is written
only after every requested take succeeds. Review candidate text, duration, decode and checksum
before copying `mandarin-*.ogg`, `turn-manifest.json` and `mandarin-provenance.json` into
`assets/voice/`. Encoding: mono 24 kHz Ogg Vorbis q5, loudness target -20 LUFS and true peak -2 dB.
No internal silence is removed and no fixed inter-speaker gap is inserted.

## Listening acceptance

Check ordinary conversation (ice pops), refusal (chapter three), apology (keeper), and the long
phone call (chapter five), not just the shortest greeting. Listen for Mandarin stress, neutral
tones, names, missing/duplicated syllables, questions versus statements and emotional restraint.
Do not promote a take to approved because it decodes, has the right duration, or transcribes
correctly. Keep transcripts source-faithful; factual quotations must not be silently paraphrased.
