# Not Yet Happened

A narrative puzzle game prototype about observation, memory, and realities that are not fixed until they are witnessed.

The project is intentionally starting small. The first technical goal is to validate one gameplay idea: **observations constrain possible realities, and confirmed facts cannot be silently rewritten**.

## Engine

- Godot 4.x
- GDScript

## Run

Open the repository with Godot 4.x and run the project.

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
