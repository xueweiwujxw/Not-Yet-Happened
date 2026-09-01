# AGENTS.md

This file defines the mandatory development rules for **Not Yet Happened**. Human contributors and coding agents must follow these rules unless the repository owner explicitly overrides them.

## Project direction

- Engine: Godot 4.x.
- Language: GDScript unless a change has a clear reason to use another language.
- Keep gameplay rules separate from presentation and scene code.
- The core concept is an observation-driven world-state system: observations constrain possible realities rather than merely revealing a fully simulated hidden state.
- Prefer small, testable systems over large scene scripts or tightly coupled prototypes.

## Branch policy

- `main` is the stable integration branch.
- After the initial repository bootstrap, do not develop features directly on `main`.
- Every feature, fix, refactor, documentation change, or experiment must use its own branch.
- Branch names **must not contain `/`**.
- Use lowercase kebab-case with a short type prefix.

Allowed examples:

- `feat-observation-system`
- `feat-dialogue-prototype`
- `fix-collapse-resolution`
- `refactor-fact-store`
- `docs-story-outline`
- `test-observer-rules`

Forbidden examples:

- `feat/observation-system`
- `user/foo`
- `Feature-Test`
- `tmp_branch`

## Commit policy

All commits must follow **Conventional Commits**:

```text
<type>(optional-scope): <short imperative description>
```

Allowed types:

- `feat`: user-visible gameplay or product capability
- `fix`: bug fix
- `refactor`: internal restructuring without behavior change
- `test`: tests only
- `docs`: documentation only
- `chore`: tooling, repository, dependency, or project maintenance
- `ci`: continuous integration changes
- `build`: build system or packaging changes
- `perf`: performance improvement

Examples:

```text
feat(observation): add partial evidence constraints
fix(world-state): reject contradictory facts
refactor(core): separate fact storage from collapse resolution
test(observation): cover repeated observations
docs: describe branching narrative rules
chore: bootstrap godot project
```

Requirements:

- Use imperative mood.
- Keep the subject concise and specific.
- Do not use vague messages such as `update`, `changes`, `fix stuff`, or `wip`.
- Do not mix unrelated changes in one commit.
- Breaking changes must use `!` and/or a `BREAKING CHANGE:` footer.

## Pull request policy

- Development branches merge into `main` through pull requests.
- Keep pull requests focused on one coherent change.
- PR titles should follow the same Conventional Commit style when practical.
- A PR description must explain:
  - what changed;
  - why it changed;
  - how it was tested;
  - any known limitations or follow-up work.
- Do not merge a PR with failing tests.
- Prefer squash merge for small focused branches unless preserving individual commits is useful.

## Testing policy

**Tests are mandatory for development changes.**

- Every new gameplay/system behavior must add or update automated tests.
- Every bug fix must include a regression test that fails before the fix when practical.
- Refactors must keep existing tests passing and add tests when coverage is insufficient.
- Documentation-only changes may omit tests.
- Pure visual/art changes may omit automated tests only when there is no meaningful behavior to test; the PR must state the manual verification performed.
- Never delete or weaken a test solely to make a failing change pass.

Current baseline test command:

```bash
godot --headless --path . --script tests/run_tests.gd
```

The exact command may evolve, but the repository must always keep a documented, non-interactive test path suitable for CI.

## Architecture rules

- `src/core/`: engine-light gameplay/domain logic. Prefer code here to be testable without loading full scenes.
- `src/game/`: game orchestration and runtime systems.
- `src/ui/`: UI behavior.
- `scenes/`: Godot scenes and scene-specific composition.
- `tests/`: automated tests.
- `docs/`: design, narrative, technical decisions, and ADRs.

Mandatory design principles:

1. **Facts are not presentation state.** A door animation, dialogue line, or sprite must not itself be the source of truth for world facts.
2. **Observations add constraints.** Observation logic should record what became known and let world-state logic decide which possibilities remain valid.
3. **Confirmed history is stable.** Once a fact is explicitly anchored by the rules, later systems must not silently rewrite it.
4. **Determinism where possible.** Core world-state tests should be deterministic. Random selection must accept an injected seed or RNG source.
5. **No giant scene scripts.** Extract reusable rules and state transitions into dedicated classes.
6. **No hidden coupling through node paths.** Prefer explicit references, signals, resources, or dependency injection.

## Code quality

- Use static typing in GDScript where practical.
- Keep functions small and single-purpose.
- Name domain concepts explicitly: `Fact`, `Observation`, `Observer`, `Evidence`, `Possibility`, `WorldState`, `CollapseResolver`.
- Avoid speculative abstractions before a real use case exists.
- Do not introduce dependencies or addons without documenting why they are needed.
- Treat warnings and test failures as issues to fix, not noise to suppress.

## Generated and imported files

- Do not commit `.godot/`, editor caches, local logs, export output, or machine-specific files.
- Commit source assets only when they are intentionally part of the project.
- Keep `.gitignore` updated when new tooling introduces generated files.

## Before committing

At minimum:

1. Review the diff for unrelated changes.
2. Run the relevant automated tests.
3. Ensure new behavior is covered by tests.
4. Check branch naming rules.
5. Check the commit message against Conventional Commits.
6. Update documentation when behavior or architecture changed.

## Agent behavior

Coding agents must:

- read this file before changing the repository;
- inspect existing architecture and tests before implementing;
- create a correctly named branch before development work after bootstrap;
- never create branch names containing `/`;
- never skip tests to save time;
- never commit directly to `main` after bootstrap unless the repository owner explicitly requests it;
- use Conventional Commit messages for every commit;
- report tests run and their result in the PR or final work summary;
- leave the working tree/repository in a coherent state with no knowingly broken intermediate implementation.
