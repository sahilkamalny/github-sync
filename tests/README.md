# Test Suite Layout

This repository uses a small, repo-local shell test suite designed for fast local runs and CI visibility.

## Philosophy

- Prefer non-destructive tests (temporary `HOME`, local temp dirs, stubbed tools).
- Use real `git` only when it adds confidence (`tests/real-git-sync.sh` uses local bare remotes, no network).
- Keep tests executable and runnable directly.
- Keep a single local entrypoint (`tests/run-all.sh`) for developers and CI.

## File structure

- `tests/run-all.sh`: orchestrates all quality/smoke/integration tests and supports CI profiles.
- `tests/quality-checks.sh`: syntax, lint, and repo hygiene checks.
- `tests/smoke-integrations.sh`: fast launcher integration smoke tests.
- `tests/core-behavior.sh`: core `gh-msync` behavior tests (stubbed and interactive CLI scenarios).
- `tests/real-git-sync.sh`: real `git` integration tests against local bare remotes.
- `tests/configure-install-uninstall.sh`: temp-`HOME` lifecycle tests for config/install/uninstall paths.
- `tests/lib/testlib.sh`: shared assertions, temp helpers, PTY input helper, and git fixture helpers.

## Profiles

- `full` (default): runs the complete local suite.
- `ci-posix`: runs the full suite used by the macOS/Linux CI jobs.
- `windows-git-bash`: runs a Windows-compatible subset (skips POSIX-only lifecycle tests and PTY-only scenarios).
- `linux-compat`: runs a distro-portability subset used by Linux compatibility CI containers (Debian/Fedora/Alpine).

Examples:

- `tests/run-all.sh --require-shellcheck`
- `tests/run-all.sh --profile ci-posix --require-shellcheck`
- `tests/run-all.sh --profile windows-git-bash`
- `tests/run-all.sh --profile linux-compat`
- `tests/run-all.sh --list-profiles`

## Naming conventions

- Use lowercase, hyphen-separated shell script names (consistent with the rest of the repo).
- Name tests by scope/intent, not implementation details:
  - `smoke-*` for quick sanity checks
  - `quality-*` for lint/syntax/hygiene
  - behavior/integration scripts for feature-level coverage
- Keep helper code in `tests/lib/` (not mixed into runnable test scripts).

## Adding new tests

- Add a new executable script in `tests/` if it covers a new scope.
- Source `tests/lib/testlib.sh` for shared assertions/helpers.
- Make the script non-destructive by default.
- Add the script to `tests/run-all.sh` in a logical order:
  1. quality checks
  2. smoke tests
  3. behavior/integration tests
  4. installer/uninstaller lifecycle tests
- If a test is platform-specific, prefer capability checks and `SKIP` output over hard-failing on unsupported environments.
- Update `README.md` project structure/testing section if the suite layout changes.
