# Chapter-one manual saves

Implemented: one manual slot at `user://chapter-one.json`, plus `.bak` containing the previous
valid save. Godot resolves `user://` to its per-user application data directory on each platform;
the executable directory need not be writable. The chapter screen offers explicit Save and Load
buttons. There is no autosave, cloud sync, sandbox save or multi-slot selection.

Loading replaces the active attempt with the saved attempt. Restart creates a fresh in-memory
attempt but does not erase or overwrite the slot. Failed loading leaves the live session untouched.
A recovered backup is reported explicitly because it may be older than the lost primary.

## Schema

```json
{"version":1,"chapter":"kitchen-light-v1","events":["advance","advance","photo","advance"]}
```

Only these three fields are accepted. Events are successful chapter actions or `advance`, in order.
The loader replays them into a new session, validating every transition. It never deserializes
executable objects, trusts an injected fact dictionary, or mutates the live session during validation.
Pending evidence, NPC arrival, lamp state and dialogue position are reconstructed by the same rules
used in play. The existing session is replaced only when the entire log is valid.

Limits: 8,192 events and 256 KiB per file. An over-limit attempt remains playable but cannot be saved
in this format; the UI reports failure rather than silently dropping events. Normal chapter play is
well below these limits. This validates a legal history, not its authenticity: a user can edit a save
into another legal action sequence. Saves are not encrypted or tamper-proof.

`version` identifies the storage schema; `chapter` identifies the exact replay-compatible story.
Bump the story revision when changing action rules, dialogue steps/order or confirmed fact meanings.
Unsupported schema/story revisions are rejected, including an incompatible backup when the primary
is missing or corrupt. No migration or silent downgrade is implemented yet.

## Write and recovery protocol

1. Validate the session's event log, serialize JSON to `.tmp`, flush, close, and validate it again.
2. If the existing primary is valid, copy it to `.bak.tmp` and rename that to `.bak`.
3. Rename `.tmp` over the primary only after those steps succeed. A failed write leaves the primary
   untouched; leftover staging files are ignored by Load and may be overwritten by a later Save.
4. Load the primary if valid. If it is missing, unreadable, oversized or malformed, attempt the
   backup. Do not write during recovery or silently read `.tmp` as a completed save.

Rename replacement is exercised on Fedora, Ubuntu, Windows and macOS by CI file tests. These are
single-process local saves: simultaneous game instances writing the same slot are unsupported.
Flush/rename reduce interruption risk but are not a guarantee against storage hardware failure,
power loss or filesystems with different durability semantics. No filesystem permission changes
or automatic deletion of a player's corrupted save are performed.

## Validation and completion review

Tests cover JSON replay at every dialogue step in two complete routes, preserved pending evidence,
invalid events/headers/extra fields, immutable save snapshots, backup recovery, oversized files,
future-version refusal, staging-write failure, UI replacement/failure behavior and restart semantics.
All test files use a uniquely named directory, never the player's default save slot.

Review found an edge case where an incompatible backup was hidden behind a missing-primary error
and a new save could be written over that situation. Regression tests reproduced it; both Load and
Save now surface the version error and leave those files alone.

Further malformed-header tests caught GDScript comparison errors for boolean/object chapter IDs
and object schema versions. Header types are now checked before comparison; the process-error
guard correctly failed the pre-fix test run even though the engine returned zero.
