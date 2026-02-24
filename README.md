<div align="center">

# GitHub Multi-Sync

**Parallel GitHub repo sync CLI for multi-folder local workflows, with safe failure handling and SSH/HTTPS control.**

[![CI](https://github.com/sahilkamalny/gh-msync/actions/workflows/ci.yml/badge.svg)](https://github.com/sahilkamalny/gh-msync/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-Supported-000000?style=flat-square&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/Linux-Supported-FCC624?style=flat-square&logo=linux&logoColor=black)](https://kernel.org/)
[![Windows](https://img.shields.io/badge/Windows-Git%20Bash%20%2F%20WSL-0078D6?style=flat-square&logo=windows&logoColor=white)](https://www.microsoft.com/windows/)
[![Bash](https://img.shields.io/badge/Bash-5+-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)

**Run modes:** `gh-msync` · `gh msync` (GitHub CLI extension)

**Proof points:** CI on macOS + Windows (Git Bash) + Linux (Ubuntu + pinned distro matrix) · non-destructive test suite · shell/docs/CI linting (`shellcheck`, `shfmt`, `actionlint`, `markdownlint`, `typos`) · Homebrew + `gh` extension support

**Built with:** Bash · GitHub CLI · AppleScript

[Portfolio](https://sahilkamal.dev) · [LinkedIn](https://linkedin.com/in/sahilkamalny) · [Contact](mailto:sahilkamal.dev@gmail.com)

</div>

---

<div align="center">
  <img src="assets/demo.gif" alt="GitHub Multi-Sync Terminal Demo" />
</div>

<p align="center">
  <strong>Demo:</strong> One command scans configured roots, syncs repositories in parallel, reports per-repo outcomes, and clones missing repos to configured roots.
</p>

---

## Engineering highlights

- **Portfolio-grade engineering signals**: repo-local automated tests, shell/CI/docs linting (`shellcheck`, `shfmt`, `actionlint`, `markdownlint`, `typos`), and GitHub Actions CI across macOS, Windows (Git Bash), Ubuntu, plus a pinned Linux distro compatibility matrix (Debian/Fedora/Alpine).
- **Branch-protection-ready governance**: CI lanes and check names are standardized for a protected `main` workflow with required PR + lint/test checks.
- **User-facing reliability**: failed pulls trigger `git rebase --abort`, and launcher fallbacks preserve real runtime errors (no masking).
- **Cross-install-method consistency**: Homebrew, from-source, and `gh` extension mode share the same launcher integration behavior.
- **Practical CLI UX**: interactive configuration, optional GUI flows, and explicit HTTPS/SSH mode control.

---

## Overview

GitHub Multi-Sync (`gh-msync`) syncs local Git repositories in parallel across one or more configured root folders. Run `gh-msync` directly or `gh msync` as a GitHub CLI extension. Across install methods, it can create a Spotlight-searchable **GitHub Multi-Sync** app on macOS and a Linux application launcher.

Platform support is tracked with explicit support tiers in [COMPATIBILITY.md](COMPATIBILITY.md).

---

## Features

- **Flexible invocation** — Run `gh-msync` directly, or as `gh msync` when installed as a GitHub CLI extension.
- **Parallel fetching** — Pulls all tracked repositories concurrently, with per-repo fallback on errors.
- **Fail-safe rebase protection** — Runs `git rebase --abort` on failed pulls so repositories are never left in a dirty state.
- **Auto SSH upgrades (optional)** — Detects `https://` remotes and upgrades them to `git@github.com:` SSH by default, with an HTTPS mode available.
- **Native OS integrations** — macOS `.app` and Linux `.desktop` launcher (both named **GitHub Multi-Sync**), with native notifications.
- **Interactive configuration** — GUI menu on macOS and Linux for multi-directory tracking.
- **Animated terminal UI** — Progress spinner and sequential result output.

---

## Prerequisites

- **Required:** `git`, `bash` (or Git Bash on Windows).
- **Optional (clone missing repos / `gh msync` extension mode):** GitHub CLI (`gh`), installed and authenticated (`gh auth login`).
- **Optional (recommended):** A [GitHub SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account) for passwordless/private-repo Git operations and automatic HTTPS→SSH remote upgrades.
- **No SSH key?** The tool still works in HTTPS mode (`--no-ssh-upgrade`). Public repos usually pull without prompts; private HTTPS repos may prompt unless your Git credential helper/PAT is already configured.

<details>
<summary>Optional SSH key setup (recommended)</summary>

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
# Accept default path, then add the public key to GitHub:
# macOS: pbcopy < ~/.ssh/id_ed25519.pub
# Linux:  cat ~/.ssh/id_ed25519.pub   (copy manually)
# Windows: clip < ~/.ssh/id_ed25519.pub
```

</details>

---

## Quick start

1. **Install** (choose one):
   - **Homebrew (macOS & Linux):** `brew install sahilkamalny/homebrew-tap/gh-msync`
   - **GitHub CLI extension:** `gh extension install sahilkamalny/gh-msync`
   - **From source:** Clone this repo and run `./scripts/install.sh` (or double-click `macOS-Install.command` / `Linux-Install.sh` on supported platforms).
2. **Configure repository root folders (recommended before first sync):**
   - **Homebrew / GitHub CLI extension:** run `gh-msync --configure` (or `gh msync --configure`) to set the folder(s) that contain your repos.
   - **From source:** `./scripts/install.sh`, `macOS-Install.command`, and `Linux-Install.sh` include this configuration step for you (or you can run `gh-msync --configure` later).
3. **Run sync:** `gh-msync` (or `gh msync` in extension mode).

Desktop integrations (optional app/launcher only, all install methods): the macOS app / Linux launcher is auto-created on the first interactive run, or managed explicitly with `--install-launcher` / `--uninstall-launcher` (long forms: `--install-integrations` / `--uninstall-integrations`).

Command by install method:

| Install method | Run command | Standalone `gh-msync` on PATH |
|---|---|---|
| Homebrew | `gh-msync` | Yes |
| From source installer | `gh-msync` | Yes (`~/.local/bin/gh-msync`) |
| GitHub CLI extension | `gh msync` | No |

For install-method details (PATH, launcher behavior, uninstall), see [Installation](#installation) and [Uninstallation](#uninstallation).

---

## Installation

### Shared desktop integrations (all install methods)

The macOS app (`~/Applications/GitHub Multi-Sync.app`) and Linux launcher (`~/.local/share/applications/gh-msync.desktop`) behave the same across install methods:

- These commands manage the optional app/launcher only (they do **not** run the full from-source installer/uninstaller scripts).
- They are auto-created on the first interactive run.
- You can create/update them manually with `gh-msync --install-launcher` (or `gh msync --install-launcher`; long form: `--install-integrations`).
- You can remove them with `gh-msync --uninstall-launcher` (or `gh msync --uninstall-launcher`; long form: `--uninstall-integrations`).

### Option A: Homebrew (macOS & Linux, recommended when available)

Homebrew works on **macOS and Linux**. Install formula `gh-msync`, then run `gh-msync`.

Install with one command (Homebrew taps the repo automatically):

```bash
brew install sahilkamalny/homebrew-tap/gh-msync
```

If you already tapped the repo:

```bash
brew install gh-msync
```

Notes:

- Installs `gh-msync` into your Homebrew prefix (for example `/opt/homebrew/bin` or `/usr/local/bin`).
- If `gh-msync` is not found immediately after install, initialize your shell with `brew shellenv`.
- Creates a default config at `~/.config/gh-msync/config` with `~/GitHub` if it does not exist.
- Before your first sync, run `gh-msync --configure` to set the folder(s) that contain your repos (unless `~/GitHub` is already the correct default).
- Auto-installs the same shared macOS/Linux launcher integrations (and supports `--install-launcher` / `--uninstall-launcher`, plus long forms `--install-integrations` / `--uninstall-integrations`).
- `gh` is optional; install/login only if you want missing-repository cloning prompts or extension mode (`gh msync`).

### Option B: From source (all platforms)

| Platform   | Method |
|-----------|--------|
| **macOS** | Double-click `macOS-Install.command` in the repo root. |
| **Linux** | Double-click `Linux-Install.sh` (or run it in a terminal). |
| **Any**   | From repo root: `./scripts/install.sh` |

The installer:

1. Creates `~/.config/gh-msync` and optionally prompts for repository paths (GUI or CLI).
2. Symlinks `scripts/gh-msync` to `~/.local/bin/gh-msync`.
3. Ensures `~/.local/bin` is on your `PATH` (appends to a shell rc file if needed).
4. Installs shared launcher integrations (macOS app / Linux launcher).

After installation, run `gh-msync` from any directory. On macOS/Linux, you can also launch **GitHub Multi-Sync** from Spotlight/Launchpad or the application menu.

### Option C: GitHub CLI extension (`gh msync`)

If you already use the GitHub CLI, install as an extension:

```bash
gh extension install sahilkamalny/gh-msync
```

Run it as:

```bash
gh msync
```

Extension mode uses the same core script and supports the same flags (for example `gh msync --configure`, `gh msync --cli`, `gh msync --install-launcher`, `gh msync --uninstall-launcher`; long forms also work). It does **not** install a standalone `gh-msync` binary on your `PATH`.

After installing the extension, run `gh msync --configure` before your first sync to set the folder(s) that contain your repos (unless `~/GitHub` is already correct).

---

## Configuration

The tool needs one or more repo root directories. These are used when you run `gh-msync` with no path arguments.

**Option 1 (recommended) — Path picker:** Run:

```bash
gh-msync --configure
```

This opens the same GUI (macOS/Linux) or terminal prompt used by the from-source installer. Use `gh-msync --configure --cli` to force terminal-only prompts. Paths are saved to `~/.config/gh-msync/config`.

**Option 2 — Edit the config file:** one path per line in `~/.config/gh-msync/config` (blank lines and `#` comments ignored).

**Option 3 — Pass paths each run:** `gh-msync ~/GitHub ~/Projects` (see [Usage](#usage)).

**Default:** `~/GitHub` if no config exists.

---

## Usage

### Common commands

```bash
gh-msync                      # sync using configured roots
gh-msync --help               # show flags and env toggles
gh-msync --configure          # GUI or CLI path picker
gh-msync --configure --cli    # terminal prompts only
```

Paths are saved to `~/.config/gh-msync/config`. Extension equivalent: replace `gh-msync` with `gh msync`.

### Desktop app / launcher integrations (all install methods)

```bash
gh-msync --install-integrations
gh-msync --uninstall-integrations
# explicit aliases (same launcher/app-only behavior)
gh-msync --install-launcher
gh-msync --uninstall-launcher
```

Extension equivalents: replace `gh-msync` with `gh msync`.

Creates/removes the shared macOS app (`~/Applications/GitHub Multi-Sync.app`) or Linux launcher (`~/.local/share/applications/gh-msync.desktop`) regardless of install method.

### Headless / CLI only

Disable GUI dialogs and use terminal prompts only:

```bash
gh-msync --cli
# or
gh-msync --headless
```

### SSH / HTTPS behavior (canonical)

By default, GitHub HTTPS remotes are upgraded to SSH (GitHub remotes only). This is a convenience default, not a requirement.

Use HTTPS mode (no SSH conversion):

```bash
gh-msync --no-ssh-upgrade
```

Or disable SSH upgrades for your shell session:

```bash
export GH_MSYNC_NO_SSH_UPGRADE=1
```

If you disabled upgrades globally, re-enable them for one run:

```bash
gh-msync --ssh-upgrade
```

What changes in HTTPS mode:

- Existing GitHub HTTPS remotes stay on HTTPS (SSH remotes are left unchanged).
- Missing-repo cloning (when using `gh`) also uses HTTPS clone URLs instead of SSH.
- Public repos usually pull without prompts.
- Private HTTPS repos may prompt for credentials unless Git already has a credential helper/token configured.

Benefits of using SSH (recommended, not required):

- Fewer credential prompts for private repos.
- Consistent GitHub remote URLs across your local repos.
- Better fit for long-term developer workflows (especially when switching machines/shells).

### Override paths

Use specific directories for one run (ignores config file):

```bash
gh-msync ~/ClientCode ~/SecondaryDrive
```

---

## Testing (repo-local)

Run the full non-destructive quality + behavior test suite:

```bash
tests/run-all.sh
```

Coverage includes:

- Shell syntax + `shellcheck` + Homebrew formula Ruby syntax checks
- GitHub Actions workflow linting (`actionlint`) plus docs/spelling linting (`markdownlint`, `typos`) in CI
- Shell formatting checks (`shfmt`) in local quality checks and CI
- Launcher integration smoke tests
- Core `gh-msync` behavior tests (flags, config parsing, SSH/HTTPS logic, clone URL selection)
- Real `git` integration tests using local bare remotes only (no network)
- Configure/install/uninstall lifecycle tests in a temporary `HOME`
- CI coverage across macOS, Windows (Git Bash), Ubuntu, plus a pinned Linux distro compatibility matrix (`debian-12`, `fedora-41`, `alpine-3.20`)

Optional:

- CI-parity local run (macOS/Ubuntu jobs): `tests/run-all.sh --profile ci-posix --require-shellcheck`
- List available test profiles (including the Windows Git Bash subset): `tests/run-all.sh --list-profiles`
- Windows Git Bash compatibility subset: `tests/run-all.sh --profile windows-git-bash`
- Linux distro compatibility subset (used in CI containers): `tests/run-all.sh --profile linux-compat`
- Optional local tooling lint (if installed): `shfmt`, `markdownlint-cli2`/`markdownlint`, `typos` are auto-detected by `tests/quality-checks.sh`
- Keep temporary test artifacts for debugging: `GH_MSYNC_TEST_KEEP_TEMP=1 tests/run-all.sh`
- WSL manual validation checklist (Tier 2 smoke): `docs/WSL-SMOKE-CHECKLIST.md`

---

## Uninstallation

Cleanup depends on install method, but macOS/Linux launcher cleanup is shared across all of them.

### Shared launcher cleanup (all install methods)

Before removing the package/extension (while the command still exists), remove shared launcher integrations if you want full UI cleanup:

```bash
gh-msync --uninstall-launcher
# or (extension mode)
gh msync --uninstall-launcher
```

Removes the macOS app and/or Linux launcher plus related desktop artifacts only (not the full `gh-msync` install).

### Homebrew installs

Remove Homebrew-managed files:

```bash
brew uninstall gh-msync
```

Optional full user-data cleanup after that:

```bash
rm -rf ~/.config/gh-msync
```

### GitHub CLI extension installs (`gh msync`)

Remove the extension entrypoint:

```bash
gh extension remove msync
```

Removes the GitHub CLI extension. `~/.config/gh-msync` is usually left in place (remove manually for full cleanup).

### From-source installs (install script / macOS/Linux installers)

Use the platform installer wrappers or the script directly:

- **macOS:** Double-click `macOS-Uninstall.command`
- **Linux:** Double-click `Linux-Uninstall.sh` (or run it in a terminal)
- **Any:** From repo root: `./scripts/uninstall.sh`

The from-source uninstaller removes the `gh-msync` symlink, PATH injection (if it added one), config, shared launcher integrations, and legacy app artifacts.

---

## Project structure

| Path | Purpose |
|------|--------|
| `scripts/gh-msync` | Main executable used by direct runs and installer-created app/desktop launchers. |
| `gh-msync` | GitHub CLI extension entrypoint (`gh msync`). |
| `scripts/install.sh` | From-source installer (symlink, config, PATH, shared app/desktop integrations). |
| `scripts/uninstall.sh` | From-source uninstaller (including shared app/desktop integration cleanup). |
| `scripts/system-integrations.sh` | Shared macOS/Linux app/launcher installer/uninstaller used across install methods. |
| `macOS-Install.command` | macOS entry point → runs `scripts/install.sh`. |
| `Linux-Install.sh` | Linux entry point → runs `scripts/install.sh`. |
| `macOS-Uninstall.command` / `Linux-Uninstall.sh` | Entry points → run `scripts/uninstall.sh`. |
| `packaging/homebrew/gh-msync.rb` | Homebrew formula (installs the binary + helper scripts, and auto-installs shared launcher integrations). |
| `COMPATIBILITY.md` | Platform support tiers, CI coverage scope, and compatibility roadmap. |
| `.markdownlint-cli2.yaml` | Markdown lint configuration (allows inline HTML/long lines used in README presentation). |
| `.typos.toml` | Spelling lint configuration (project-specific allowed words/exclusions). |
| `RELEASING.md` | Release checklist for tags/tarballs/Homebrew formula updates and final verification. |
| `tests/run-all.sh` | One-command local test runner (quality/smoke/integration suites via profiles). |
| `tests/*.sh` | Repo-local quality, smoke, behavior, real-git, and install/uninstall lifecycle test scripts. |
| `tests/lib/testlib.sh` | Shared test helpers (assertions, temp dirs, PTY input, git fixtures, platform capability checks). |
| `tests/README.md` | Test suite layout, naming conventions, profiles, and guidance for adding tests. |
| `assets/` | Demo assets (e.g. `demo.tape`, `demo.gif`). |
| `docs/WSL-SMOKE-CHECKLIST.md` | Manual WSL validation checklist (Tier 2 support smoke test). |

---

## Troubleshooting

- **`gh-msync` not found**  
  Ensure the directory containing `gh-msync` is on your `PATH` (usually `~/.local/bin` for from-source installs). Restart the terminal or source your shell rc after installing.

- **Repos not found**  
  Check that paths in `~/.config/gh-msync/config` exist and contain directories with a `.git` subdirectory. Or pass paths explicitly: `gh-msync /path/to/parent`.

- **Permission denied**  
  Ensure the script is executable: `chmod +x scripts/gh-msync`. The installer does this automatically.

- **Clone step not offered**  
  Install and log in to the GitHub CLI: `brew install gh && gh auth login`. `gh-msync` uses it to list and clone missing repos.

- **macOS app / Linux launcher missing**  
  Run `gh-msync --install-launcher` (or `gh msync --install-launcher`; long form `--install-integrations`) to create/refresh shared launcher integrations.

- **SSH errors**  
  SSH is optional. Configure a GitHub SSH key and keep the default behavior, or use `gh-msync --no-ssh-upgrade` (or `GH_MSYNC_NO_SSH_UPGRADE=1`) to keep HTTPS remotes/clones.

- **HTTPS prompts for credentials**  
  This is expected for private repos unless your Git credential helper/PAT is already configured. Use SSH (recommended) or configure Git credentials for HTTPS.

---

## Contributing

Pull requests and issues are welcome.

Before opening a PR, run `tests/run-all.sh` locally. For release steps (tagging, Homebrew formula SHA updates, final verification), see `RELEASING.md`.

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

<div align="center">

© 2026 Sahil Kamal

</div>
