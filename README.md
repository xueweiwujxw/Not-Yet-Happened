# Not Yet Happened

A narrative puzzle game prototype about observation, memory, and realities that are not fixed until they are witnessed.

The project is intentionally starting small. The first technical goal is to validate one gameplay idea: **observations constrain possible realities, and confirmed facts cannot be silently rewritten**.

## Engine

- Godot 4.x
- GDScript

## Run

Open the repository with Godot 4.x and run the project.

### Playable room prototype

The startup scene now contains a short, text-first room puzzle. Use the buttons with a mouse,
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
observation, not procedurally generated audio. There are no saves or packaged exports yet.
The scene UI delegates rules to `src/game/room_session.gd`; it does not mutate core facts.

## Tests

Run the headless test suite from the repository root:

```bash
godot --headless --path . --script tests/run_tests.gd
```

The command exits with a non-zero status when a test fails.

GitHub Actions runs the same suite and a project startup smoke test on Fedora 43, Ubuntu,
Windows, and macOS. The workflow pins Godot 4.5.1 so all target environments use the same engine
version.

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
