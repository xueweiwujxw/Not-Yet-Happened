# Not Yet Happened

A narrative puzzle game prototype about observation, memory, and realities that are not fixed until they are witnessed.

The project is intentionally starting small. The first technical goal is to validate one gameplay idea: **observations constrain possible realities, and confirmed facts cannot be silently rewritten**.

## Engine

- Godot 4.x
- GDScript

## Run

Open the repository with Godot 4.x and run the project.

### Playable chapters

The project opens **厨房的灯**, a Chinese text-first chapter with investigation, sequential
dialogue, an optional lamp repair and portrait, an evidence notebook, and chapter completion.
Read the recording, old photograph and letter in any supported order; optional interactions
do not block completion. The notebook distinguishes confirmed contents from testimony and keeps
the sister's fate unknown. Tab and Enter / Space support keyboard play.

The bundled Noto Sans CJK subset provides Chinese glyphs on all four platforms; the font license
is accessible from the chapter screen. See [font provenance and rebuild instructions](assets/fonts/README.md).
Automated tests cover glyph coverage, progression, scene controls and narrow-window layout.
Photo and recording contents are represented by text; there is no voice acting yet.
Use **探索 3D 老屋** to enter the first chapter's low-poly kitchen: WASD / arrow keys move,
E interacts or continues dialogue, and Tab returns to the notebook and manual save/load.
Walk near an object to reveal its available actions. The 3D view shares the exact chapter session;
moving the camera or seeing a prop does not confirm evidence. Character position is not saved.
See [art, controls and rendering checks](docs/kitchen-3d.md).
Manual Save/Load preserves dialogue,
progress and facts; Restart clears only the active attempt, not the disk save. See [save format and
recovery rules](docs/save-format.md). There are separate slots for chapter one, chapter two, and
the sequential chapters-three-to-six arc, each with a last-valid backup and no autosave.

Complete chapter one to enter **门后有人**, the second text-first chapter. Investigate the old
telephone and recording in the present, then explicitly enter a constrained historical window.
Calling before listening/opening secures the keeper's escort and cabinet-location information;
listening advances to the outage and closes the call opportunity. Footsteps do not identify a
person. Opening confirms the authored local outcome without random rolls: the children survive
in every route, and the sister's later fate remains unknown. The closed window cannot be replayed
within the same attempt. Chapter two does not fix later lighting/ladder preparations.

Return to the first-chapter record and resume without losing second-chapter progress. The initial
screen can also load chapter two directly: its save includes its matching first-chapter record.
See the [second-chapter script and acceptance checks](docs/chapter-02.md).

### Complete story arc

From chapter two, continue through the four remaining chapters:

- **没有寄出的信**: read the admission letter, distinguish a report from its truth, check patrol
  coverage, obtain the rescue diagram and respond to Shiori's refusal to hear her recording.
- **七分钟**: connect backup lighting before the outage and lower the ladder before boarding.
  Both are needed for the safe route. Early platform confirmation ends unfinished preparation;
  declining confirmation preserves the unknown. A witnessed fall is not a death confirmation.
- **有人在等她**: review sources, explicitly verify identity or seal the records, and decide
  whether to contact the living sister. Share dinner and preserve both the old report and correction.
- **下一班车**: write fact-appropriate memorial text, choose a farewell photograph and depart.
  Four endings follow from earlier history, identity and invitation choices, not four ending buttons.

The six-chapter Chinese text-first story is playable from start to finish. All four endings are
implemented; there is no random life/death selection. See [arc rules, routes and review](docs/chapters-03-06.md).
Directly load any saved point in the final arc from the initial screen, including pending dialogue
and completed endings. Its save carries both earlier chapters. Returning to earlier records is
read-only; explicitly loading/restarting an earlier attempt discards dependent live later progress,
not disk saves. Chapters two through six remain text-first; voice assets and human-validated
playtime are not yet available.

### Independent room prototype

Open the separate mechanic sandbox using the button below the chapter notebook; return without
changing chapter progress. It contains a short, text-first room puzzle. Use the buttons with a mouse,
or Tab / Shift+Tab and Enter / Space with a keyboard.

- Before the storm, telephone the keeper to arrange an escort for Shiori.
- Listening or opening the door advances time; the storm then cuts the telephone line.
- Listening confirms footsteps, not Shiori's safety. It filters histories without fully resolving them.
- Opening the door anchors one compatible history. A prior rescue call guarantees safety;
  without one, both safe and unsafe histories remain possible.
- Start a new attempt to reset all facts. The prototype uses a fixed seed (2026), so the same
  actions reproduce the same ending. Domain tests inject other seeds.

This is a mechanic test, not the final story or 3D presentation. Five authored outcomes, English
placeholder text, and a diagnostic candidate count are included. Footsteps are an authored partial
observation, not procedurally generated audio. The independent sandbox is not saved.
The scene UI delegates rules to `src/game/room_session.gd`; it does not mutate core facts.

## Tests

Run the headless test suite from the repository root:

```bash
godot --headless --path . --script tests/run_tests.gd
```

The command exits with a non-zero status when a test fails.

CI additionally runs commands through `bash scripts/check-godot.sh` to reject Godot runtime/error
logs even when the engine exits zero. Test that guard with `bash tests/test_check_godot.sh`.

GitHub Actions runs the same suite and a project startup smoke test on Fedora 43, Ubuntu,
Windows, and macOS. The workflow pins Godot 4.5.1 so all target environments use the same engine
version.

## Desktop packages

The **Desktop exports** workflow tests and exports release builds on every PR and `main` push.
Download `not-yet-happened-linux`, `not-yet-happened-windows`, or `not-yet-happened-macos`
from the successful run's Artifacts section. These are development builds, retained for 14 days,
not signed public releases.

- Fedora / Ubuntu: extract the Linux x86-64 artifact, run `chmod +x NotYetHappened.x86_64`,
  then launch it. The same binary is smoke-tested on both distributions.
- Windows: extract the artifact and launch `NotYetHappened.exe`. The console executable is for
  diagnostics. Windows builds are x86-64 and are not code-signed.
- macOS: extract the artifact and then `NotYetHappened.zip` to obtain the universal `.app`
  (Intel and Apple Silicon). It is ad-hoc signed, not notarized; Gatekeeper may require approval
  through System Settings for this trusted development build. CI tests the runner's architecture,
  not both architectures.

CI launches each exported binary headlessly without the editor. This checks packaging/startup,
not GPU rendering, audio, or interactive usability on physical machines.

**Render kitchen previews** additionally renders actual 1600×1000 and default 1280×720 Godot screenshots on
Ubuntu with Mesa software OpenGL and Xvfb. Download the `kitchen-previews` artifact (14 days).
This is a reproducible visual-review aid, not physical-GPU coverage of all four platforms.

To export locally, install Godot **4.5.1** and its matching export templates, create the output
directory, then run `godot --headless --path . --export-release Linux` (or `Windows` / `macOS`).
Default destinations are in `build/` and are ignored by Git.

## Story and remaining production work

The Chinese [story bible](docs/story-bible.md) defines the six-chapter narrative, characters,
fixed-history rules and four endings. The [chapter-one script](docs/chapter-01.md) specifies the
first playable slice and its acceptance tests. All six chapters now have text-first implementations,
with constrained historical revisits, evidence separation, persistent choices and four endings.
Next production work is human playtesting/pacing, presentation, scene art and audio, not additional
unimplemented mainline chapters. The original 2–3 hour target is unmeasured, not a duration claim.
The current room puzzle remains a separate mechanic sandbox; its uncertain child-safety outcomes
must not be reused as canon in a story where Shiori's survival is already established.

## Development workflow

Read [`AGENTS.md`](AGENTS.md) before making changes.

Key rules:

- `main` is the stable integration branch.
- Development work uses dedicated branches after the initial bootstrap.
- Branch names use lowercase kebab-case and **must not contain `/`**.
- Commits follow Conventional Commits.
- Behavioral changes require automated tests.

Example branch names:

```text
feat-observation-system
fix-world-state-conflict
docs-story-outline
```

## Initial structure

```text
scenes/       Godot scenes
src/core/     gameplay/domain logic intended to stay easy to test
tests/        headless automated tests
docs/         design and narrative documentation
```

The architecture will evolve only as concrete gameplay requirements appear.

## Core model

An `Observation` identifies its observer and carries one or more fact constraints. Applying it to
`WorldState` is atomic: either every constraint is compatible with confirmed history, or none of
them are recorded. Observation IDs are idempotent and cannot be reused for different contents.

A `Possibility` is a candidate reality containing the facts it explicitly decides. Observations
remove candidates with contradictory values while preserving candidates where the observed fact
is still unknown. An observation is rejected atomically if it would eliminate every remaining
candidate reality.

A `CollapseResolver` makes the final weighted choice from the remaining candidates. It requires an
injected `RandomNumberGenerator`, iterates candidates in deterministic order, and delegates the
actual state transition to `WorldState`. Once collapsed, the selected possibility and its explicit
facts are anchored, alternatives cannot be added, and repeated resolution is idempotent.
