# Chapter manual saves

Implemented: one manual slot at `user://chapter-one.json`, plus `.bak` containing the previous
valid save. Chapter two has a separate slot at `user://chapter-two.json` using the same protocol.
Chapters three through six share `user://story-finale.json`: one sequential arc slot, not four
independent chapter slots. It can be loaded directly from the initial chapter screen.
Godot resolves `user://` to its per-user application data directory on each platform;
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

Chapter two uses four fields: `version: 1`, `chapter: "keeper-room-v1"`, `events` and `prologue`.
The prologue is a full chapter-one save and must replay to completion before chapter-two input
is applied. All first-chapter facts are inherited. Limits apply to each event log, and the whole
file must remain within 256 KiB. Unsupported nested prologue revisions also block loading and
overwriting; they are not treated as ordinary corruption. Changing only chapter-one's idle
completion message to advertise chapter two does not change the action log or revision.

The initial chapter screen can load chapter two directly, restoring its matching chapter-one
record as well. Returning to chapter one only views that completed record; continuing chapter two
does not restart its revisit. Explicit first-chapter restart/load discards dependent in-memory
chapter two, not the saved slot. A new second-chapter attempt retains its prologue.

## Final arc (chapters three through six)

The four fields are `version: 1`, `chapter: "summer-finale-v1"`, `events` and `prologue`.
The prologue is a complete chapter-two save, itself containing chapter one. The bounded, fixed-depth
replay validates both earlier chapters before applying arc events. The arc's current chapter is
derived from valid transitions, never trusted as an injected chapter index. All three headers are
checked for compatibility; an unsupported inner version cannot be downgraded or overwritten.

Pending observations, closed preparation windows, sealed identities, invitations and endings all
restore through the same rules. Limits remain 8,192 events per log and 256 KiB for the whole file.
The stored event log commits a choice when selected; its evidence is recorded only when its final
dialogue line is read. Loading halfway through a decision cannot expose other actions or reroll it.

Returning from the arc restores the matching earlier records, even if a different arc save was
loaded inside its screen. Continuing resumes the live arc. Explicit restart/load of either earlier
chapter clears dependent live arc progress. Restart within the arc begins at chapter three while
preserving its earlier chapters. No such action deletes or automatically writes any disk slot.

Only chapter-two's idle completion message changed to advertise the remaining story; its actions,
dialogue steps and fact meanings are unchanged, so `keeper-room-v1` saves remain compatible.

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
