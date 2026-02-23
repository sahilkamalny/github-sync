# Homebrew formula

This directory holds the Homebrew formula for GitHub Multi-Sync (`gh-msync`). The formula is used by the project’s tap so users can install with:

```bash
brew install sahilkamalny/homebrew-tap/gh-msync
```

For GitHub CLI extension mode, users install from the main repo:

```bash
gh extension install sahilkamalny/gh-msync
```

See the main [README](../../README.md) for installation and usage.

## Maintainer note

Before publishing a new release, update `packaging/homebrew/gh-msync.rb` with:

1. The new tag URL (if version changed).
2. The exact tarball SHA256 for that tag.

## Release checklist (manual)

1. Ensure working tree is clean on `main`.
2. Create or update the tag (example: `v1.0.0`) and push it.
3. Create/update the GitHub release for that tag.
4. Download the tag tarball and compute SHA256.
5. Update `packaging/homebrew/gh-msync.rb` with the SHA.
6. Commit and push the formula change.
