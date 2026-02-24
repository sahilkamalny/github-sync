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

**Proof points:** macOS/Linux CI · non-destructive test suite · `shellcheck` clean · Homebrew + `gh` extension support

**Built with:** Bash · GitHub CLI · AppleScript

[Portfolio](https://sahilkamal.dev) · [LinkedIn](https://linkedin.com/in/sahilkamalny) · [Contact](mailto:sahilkamal.dev@gmail.com)

</div>

---

<div align="center">
  <img src="assets/demo.gif" width="800" alt="GitHub Multi-Sync Terminal Demo" />
</div>

<p align="center">
  Demo: one command scans configured roots, syncs repositories in parallel, and reports per-repo outcomes.
</p>

---

## Table of contents

- [Engineering highlights](#engineering-highlights)
- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Testing (repo-local)](#testing-repo-local)
- [Uninstallation](#uninstallation)
- [Project structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Engineering highlights

- **Portfolio-grade engineering signals**: repo-local automated test suite, `shellcheck` coverage, and GitHub Actions CI on macOS + Linux.
- **User-facing reliability**: failed pulls trigger `git rebase --abort` protection and launcher fallbacks preserve real runtime errors.
- **Cross-install-method consistency**: Homebrew, from-source, and `gh` extension mode share the same launcher integration behavior.
- **Practical CLI UX**: interactive configuration, optional GUI flows, and HTTPS/SSH mode control for different developer environments.

---

## Overview

GitHub Multi-Sync (`gh-msync`) is a cross-platform utility for syncing local Git repositories in parallel. Run `gh-msync` from any directory to discover and pull repositories under your configured folders. If you install it as a GitHub CLI extension, run `gh msync`. Across install methods, it can create a Spotlight-searchable **GitHub Multi-Sync** app on macOS and a **GitHub Multi-Sync** launcher on Linux.

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
2. **Run:** `gh-msync` (or `gh msync` in extension mode).
3. **Configure paths (optional):** `gh-msync --configure` (or `gh msync --configure`).

Desktop integration (all install methods): the macOS app / Linux launcher is auto-created on first interactive run, or you can create it explicitly with `gh-msync --install-integrations` (or `gh msync --install-integrations`).

Command by install method:

| Install method | Run command | Standalone `gh-msync` on PATH |
|---|---|---|
| Homebrew | `gh-msync` | Yes |
| From source installer | `gh-msync` | Yes (`~/.local/bin/gh-msync`) |
| GitHub CLI extension | `gh msync` | No |

For install-method details (PATH behavior, app/launcher behavior, uninstall steps), see [Installation](#installation) and [Uninstallation](#uninstallation).

---

## Installation

### Shared desktop integrations (all install methods)

The macOS app (`~/Applications/GitHub Multi-Sync.app`) and Linux launcher (`~/.local/share/applications/gh-msync.desktop`) are managed the same way across install methods:

- They are auto-created on the first interactive run.
- You can create/update them manually with `gh-msync --install-integrations` (or `gh msync --install-integrations`).
- You can remove them with `gh-msync --uninstall-integrations` (or `gh msync --uninstall-integrations`).

### Option A: Homebrew (macOS & Linux, recommended when available)

Works on **macOS and Linux** (Homebrew supports both). Install with the formula name `gh-msync`, then run the command as `gh-msync`.

Install with one command (Homebrew taps the repo automatically):

```bash
brew install sahilkamalny/homebrew-tap/gh-msync
```

If you already tapped the repo:

```bash
brew install gh-msync
```

Notes:

- Installs `gh-msync` into your Homebrew prefix (for example `/opt/homebrew/bin` on Apple Silicon, `/usr/local/bin` on Intel Macs, or your Linux Homebrew prefix).
- If `gh-msync` is not found immediately after install, initialize your shell with Homebrew's environment (for example `eval "$('/opt/homebrew/bin/brew' shellenv)"` on Apple Silicon, or use the path printed by `brew shellenv`).
- Creates a default config at `~/.config/gh-msync/config` with `~/GitHub` if it does not exist.
- Supports the same GUI/CLI path picker as other install methods via `gh-msync --configure` (or `gh-msync --configure --cli`).
- Auto-installs the same macOS/Linux launcher integrations used by other install methods (and supports `gh-msync --install-integrations` / `gh-msync --uninstall-integrations`).
- `gh` is optional. Install and log in (`brew install gh && gh auth login`) only if you want missing-repository cloning prompts or extension mode (`gh msync`).

### Option B: From source (all platforms)

| Platform   | Method |
|-----------|--------|
| **macOS** | Double-click `macOS-Install.command` in the repo root. |
| **Linux** | Double-click `Linux-Install.sh` (or run it in a terminal). |
| **Any**   | From repo root: `./scripts/install.sh` |

The installer will:

1. Create `~/.config/gh-msync` and optionally prompt for repository paths (GUI or CLI).
2. Make `scripts/gh-msync` executable and symlink it to `~/.local/bin/gh-msync`.
3. Ensure `~/.local/bin` is on your `PATH` (by appending to your shell rc file if needed).
4. Install the same shared launcher integrations used by all install methods:
   - macOS app: `~/Applications/GitHub Multi-Sync.app`
   - Linux launcher: `~/.local/share/applications/gh-msync.desktop`

After installation, run `gh-msync` from any directory. You can also launch **GitHub Multi-Sync** from Spotlight/Launchpad (macOS) or the application menu (Linux).

### Option C: GitHub CLI extension (`gh msync`)

If you already use the GitHub CLI, install as an extension:

```bash
gh extension install sahilkamalny/gh-msync
```

Run it as:

```bash
gh msync
```

Extension mode uses the same core script and supports the same flags (for example `gh msync --configure`, `gh msync --cli`, `gh msync --install-integrations`, and `gh msync --uninstall-integrations`). It does **not** install a standalone `gh-msync` binary onto your `PATH`.

---

## Configuration

The tool needs to know which **directory (or directories)** hold your Git repos. Those paths are used whenever you run `gh-msync` with no arguments.

**Option 1 — Path picker (recommended):** Run:

```bash
gh-msync --configure
```

This opens the same GUI (macOS/Linux) or a terminal prompt you get with the from-source installer. Use `gh-msync --configure --cli` to force terminal-only prompts. The chosen paths are saved to `~/.config/gh-msync/config`.

**Option 2 — Edit the config file:** `~/.config/gh-msync/config` — one path per line (e.g. `~/GitHub` or `~/Projects`). Blank lines and lines starting with `#` are ignored.

**Option 3 — Pass paths each time:** `gh-msync ~/GitHub ~/Projects` (see [Usage](#usage)).

**Default:** If no config exists, `~/GitHub` is used.

---

## Usage

### Basic

```bash
gh-msync
```

Uses paths from `~/.config/gh-msync/config` (or `~/GitHub` if unset), pulls all repos in parallel, and optionally prompts to clone missing repositories if `gh` is installed and authenticated.

### Help

```bash
gh-msync --help
```

Shows all supported flags and environment toggles.

### Configure paths

```bash
gh-msync --configure          # GUI or CLI path picker
gh-msync --configure --cli    # terminal prompts only
```

Saves chosen directories to `~/.config/gh-msync/config` so future `gh-msync` runs use them automatically.

Extension equivalent: `gh msync --configure`.

### Desktop app / launcher integrations (all install methods)

```bash
gh-msync --install-integrations
gh-msync --uninstall-integrations
```

Extension equivalents:

```bash
gh msync --install-integrations
gh msync --uninstall-integrations
```

These create/remove the shared macOS app (`~/Applications/GitHub Multi-Sync.app`) or Linux launcher (`~/.local/share/applications/gh-msync.desktop`) regardless of how you installed the tool.

### Headless / CLI only

Disable GUI dialogs and use terminal prompts only:

```bash
gh-msync --cli
# or
gh-msync --headless
```

### SSH / HTTPS behavior (canonical)

By default, GitHub HTTPS remotes are upgraded to SSH **if they are GitHub remotes**. This is a convenience default, not a hard requirement.

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
- Launcher integration smoke tests
- Core `gh-msync` behavior tests (flags, config parsing, SSH/HTTPS logic, clone URL selection)
- Real `git` integration tests using local bare remotes only (no network)
- Configure/install/uninstall lifecycle tests in a temporary `HOME`

Optional:

- CI-parity local run that requires `shellcheck`: `tests/run-all.sh --require-shellcheck`
- Keep temporary test artifacts for debugging: `GH_MSYNC_TEST_KEEP_TEMP=1 tests/run-all.sh`

---

## Uninstallation

Cleanup depends on install method, but the macOS/Linux launcher cleanup is shared across all of them.

### Shared launcher cleanup (all install methods)

Before removing the package/extension (while the command still exists), remove the shared launcher integrations if you want a full UI cleanup:

```bash
gh-msync --uninstall-integrations
# or (extension mode)
gh msync --uninstall-integrations
```

This removes the macOS app (`~/Applications/GitHub Multi-Sync.app`) and/or Linux launcher (`~/.local/share/applications/gh-msync.desktop`) plus related desktop artifacts.

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

This removes the GitHub CLI extension. Your config at `~/.config/gh-msync` is typically left in place (remove it manually if you want a full cleanup).

### From-source installs (install script / macOS/Linux installers)

Use the platform installer wrappers or the script directly:

- **macOS:** Double-click `macOS-Uninstall.command`
- **Linux:** Double-click `Linux-Uninstall.sh` (or run it in a terminal)
- **Any:** From repo root: `./scripts/uninstall.sh`

The from-source uninstaller removes the `gh-msync` symlink, PATH injection (if it added one), config, shared launcher integrations, and legacy app artifacts from older installs.

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
| `RELEASING.md` | Release checklist for tags/tarballs/Homebrew formula updates and final verification. |
| `tests/run-all.sh` | One-command local test runner (quality checks + all repo-local smoke/integration tests). |
| `tests/README.md` | Test suite structure, naming conventions, and guidance for adding new tests. |
| `tests/quality-checks.sh` | Syntax/lint/hygiene checks (`bash -n`, `shellcheck`, Ruby syntax, wrapper/help smoke). |
| `tests/smoke-integrations.sh` | Non-destructive smoke tests for shared launcher integration creation/removal and launcher fallback behavior. |
| `tests/core-behavior.sh` | Non-destructive core `gh-msync` behavior tests (flags, sync-flow stubs, interactive clone URL selection). |
| `tests/real-git-sync.sh` | Real `git` integration tests against local bare remotes (pull/update/skip behavior). |
| `tests/configure-install-uninstall.sh` | Temp-`HOME` tests for configuration, from-source install/uninstall lifecycle, and Linux wrapper fallback dispatch. |
| `tests/lib/testlib.sh` | Shared test helpers for assertions, temp dirs, PTY input, and git fixture setup. |
| `assets/` | Demo assets (e.g. `demo.tape`, `demo.gif`). |

---

## Troubleshooting

- **`gh-msync` not found**  
  Ensure the directory containing `gh-msync` is on your `PATH`. For from-source installs, that is usually `~/.local/bin`. Restart the terminal or run `source ~/.zshrc` (or your shell rc) after installing.

- **Repos not found**  
  Check that paths in `~/.config/gh-msync/config` exist and contain directories with a `.git` subdirectory. Or pass paths explicitly: `gh-msync /path/to/parent`.

- **Permission denied**  
  Ensure the script is executable: `chmod +x scripts/gh-msync`. The installer does this automatically.

- **Clone step not offered**  
  Install and log in to the GitHub CLI: `brew install gh && gh auth login`. GitHub Multi-Sync uses it to list and clone missing repos.

- **macOS app / Linux launcher missing**  
  Run `gh-msync --install-integrations` (or `gh msync --install-integrations` in extension mode) to create or refresh the shared launcher integrations.

- **SSH errors**  
  SSH is optional. If you want SSH mode, configure a GitHub SSH key and keep the default behavior. If you do not want SSH, run with `gh-msync --no-ssh-upgrade` (or set `GH_MSYNC_NO_SSH_UPGRADE=1`) to keep HTTPS remotes/clones.

- **HTTPS prompts for credentials**  
  This is expected for private repos unless your Git credential helper/PAT is already configured. Use SSH (recommended) or configure Git credentials for HTTPS.

---

## Contributing

Pull requests and issues are welcome. For bugs or feature requests, please open an issue.

Before opening a PR, run `tests/run-all.sh` locally. For release steps (tagging, Homebrew formula SHA updates, final verification), see `RELEASING.md`.

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

<div align="center">

*© 2026 Sahil Kamal*

</div>
