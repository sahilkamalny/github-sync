# Releasing gh-msync

This checklist is for publishing a new tagged release and keeping the Homebrew formula in sync.

## Pre-release checks

1. Ensure the working tree is clean (`git status`).
2. Run the full local suite:
   - `tests/run-all.sh --require-shellcheck`
3. Review README changes (install/uninstall docs, flags, examples) for accuracy.
4. If CLI UX changed, update demo assets (`assets/demo.tape`, `assets/demo.gif`) if needed.

## Version/tag preparation

1. Choose the release version (for example `v1.0.1`).
2. Confirm the Homebrew formula source URL in `packaging/homebrew/gh-msync.rb` points to the intended tag archive.
3. Update the formula `url` (tag tarball) if it changed.

## Publish the GitHub release

1. Commit release-related changes.
2. Create and push the tag:
   - `git tag vX.Y.Z`
   - `git push origin vX.Y.Z`
3. Create the GitHub release (notes/changelog) for that tag.

## Update Homebrew formula SHA

After the GitHub tag archive is available:

1. Download/calculate the tarball SHA256 for `https://github.com/sahilkamalny/gh-msync/archive/refs/tags/vX.Y.Z.tar.gz`.
2. Update `sha256` in `packaging/homebrew/gh-msync.rb`.
3. If needed, update the formula `url` version tag to the same `vX.Y.Z`.
4. Run:
   - `ruby -c packaging/homebrew/gh-msync.rb`
   - `tests/run-all.sh --require-shellcheck`

## Final verification (recommended)

1. Fresh install path checks:
   - From source: `./scripts/install.sh --cli` (temp machine or disposable environment)
   - Extension mode: `gh extension install sahilkamalny/gh-msync`
2. Confirm:
   - `gh-msync --help` shows expected flags
   - `gh-msync --install-integrations` / `--uninstall-integrations` work
   - README commands/examples still match behavior
3. Push the formula update commit (if the formula lives in this repo/tap workflow for your release process).

## Post-release follow-up

1. Verify GitHub Actions CI passed on `main` and/or release PR.
2. Verify the pinned repo README badge is green.
3. Update portfolio/resume/project links only after the public release is accessible.
