<div align="center">

# GitHub Multi-Sync

**GitHub-focused CLI utility to sync multiple repositories in parallel — run `gh-msync` directly or `gh msync` as a GitHub CLI extension.**

[![Bash](https://img.shields.io/badge/Bash-5+-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![macOS](https://img.shields.io/badge/macOS-Supported-000000?style=flat-square&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/Linux-Supported-FCC624?style=flat-square&logo=linux&logoColor=black)](https://kernel.org/)
[![Windows](https://img.shields.io/badge/Windows-Git%20Bash%20%2F%20WSL-0078D6?style=flat-square&logo=windows&logoColor=white)](https://www.microsoft.com/windows/)

**Built with** Bash · GitHub CLI · AppleScript

[Portfolio](https://sahilkamal.dev) · [LinkedIn](https://linkedin.com/in/sahilkamalny) · [Contact](mailto:sahilkamal.dev@gmail.com)

</div>

---

<div align="center">
  <img src="assets/demo.gif" width="800" alt="GitHub Multi-Sync Terminal Demo" />
</div>

---

## Table of contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Optional Git Alias](#optional-git-alias)
- [Uninstallation](#uninstallation)
- [Project structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

GitHub Multi-Sync (`gh-msync`) is a cross-platform utility for syncing local Git repositories in parallel. Run `gh-msync` from any directory to discover and pull repositories under your configured folders. If you install it as a GitHub CLI extension, run `gh msync`. It ships with a Spotlight-searchable **GitHub Multi-Sync** app on macOS and a **GitHub Multi-Sync** launcher on Linux.

---

## Features

- **Flexible invocation** — Run `gh-msync` directly, or as `gh msync` when installed as a GitHub CLI extension.
- **Parallel fetching** — Pulls all tracked repositories concurrently, with per-repo fallback on errors.
- **Fail-safe rebase protection** — Runs `git rebase --abort` on failed pulls so repositories are never left in a dirty state.
- **Auto SSH upgrades** — Detects `https://` remotes and upgrades them to `git@github.com:` SSH (optional per run).
- **Native OS integrations** — macOS `.app` and Linux `.desktop` launcher (both named **GitHub Multi-Sync**), with native notifications.
- **Interactive configuration** — GUI menu on macOS and Linux for multi-directory tracking.
- **Animated terminal UI** — Progress spinner and sequential result output.

---

## Prerequisites

- **Required:** `git`, `bash` (or Git Bash on Windows).
- **Optional (clone missing repos):** GitHub CLI (`gh`), installed and authenticated (`gh auth login`).
- **Required for remote access:** A [GitHub SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account) — GitHub Multi-Sync upgrades remotes to SSH.

<details>
<summary>SSH key setup (click to expand)</summary>

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
2. **Run:** `gh-msync` from any directory (or `gh msync` if installed as a GitHub CLI extension).
3. **Configure paths (optional):** Run `gh-msync --configure` to pick directories in a GUI or at the terminal. You can also edit `~/.config/gh-msync/config` (one path per line). Default is `~/GitHub`.

Command by install method:

| Install method | Command to run | Installs standalone `gh-msync` on PATH |
|---|---|---|
| Homebrew | `gh-msync` | Yes |
| From source installer | `gh-msync` | Yes (`~/.local/bin/gh-msync`) |
| GitHub CLI extension | `gh msync` | No |

---

## Installation

### Option A: Homebrew (macOS & Linux, recommended when available)

Works on **macOS and Linux** (Homebrew supports both). Install with the formula name `gh-msync`, then run the command as `gh-msync`.

Install with one command (Homebrew taps the repo automatically):

```bash
brew install sahilkamalny/homebrew-tap/gh-msync
```

If they have already run `brew tap sahilkamalny/homebrew-tap`, they can use:

```bash
brew install gh-msync
```

- The binary is installed to your Homebrew prefix (e.g. `/opt/homebrew/bin` on Apple Silicon, `/usr/local/bin` on Intel, or Linux Homebrew’s prefix) as `gh-msync`.
- If `gh-msync` is not found right after install, initialize your shell with Homebrew’s environment first (for example: `eval "$(/opt/homebrew/bin/brew shellenv)"` on Apple Silicon, or the path printed by `brew shellenv` on your system).
- A default config is created at `~/.config/gh-msync/config` with `~/GitHub` if it doesn’t exist. To choose your directories the same way as the from-source installer (GUI or CLI), run **`gh-msync --configure`** (or `gh-msync --configure --cli` for terminal-only). See [Configuration](#configuration).
- Homebrew does not create the **GitHub Multi-Sync** macOS app or Linux desktop launcher; use the from-source installer (Option B) if you want those. Path configuration is identical: `gh-msync --configure`.
- `gh` is optional for Homebrew installs. Install and log in (`brew install gh && gh auth login`) only if you want missing-repository cloning prompts or extension mode (`gh msync`).

To uninstall Homebrew-managed files:

```bash
brew uninstall gh-msync
```

This removes the Homebrew-installed binary/formula files. If you also want user-data/artifact cleanup, remove `~/.config/gh-msync` and any from-source artifacts manually (or run `./scripts/uninstall.sh` from a clone of this repo).

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
4. On macOS: create **GitHub Multi-Sync.app** in the repo directory (you can move it to Applications or the Desktop).
5. On Linux: create a **GitHub Multi-Sync** desktop entry in `~/.local/share/applications`.

After installation, run `gh-msync` from any directory. You can also launch **GitHub Multi-Sync** from Spotlight (macOS) or the application menu (Linux).

### Option C: GitHub CLI extension (`gh msync`)

If you already use the GitHub CLI, install as an extension:

```bash
gh extension install sahilkamalny/gh-msync
```

Run it as:

```bash
gh msync
```

Extension mode uses the same core script and supports the same flags (for example `gh msync --configure` and `gh msync --cli`).
It does **not** install a standalone `gh-msync` binary onto your PATH.

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
gh-msync --configure --cli   # terminal prompts only
```

Saves chosen directories to `~/.config/gh-msync/config` so future `gh-msync` runs use them automatically.

### Headless / CLI only

Disable GUI dialogs and use terminal prompts only:

```bash
gh-msync --cli
# or
gh-msync --headless
```

### SSH remote behavior

By default, GitHub HTTPS remotes are upgraded to SSH.

```bash
gh-msync --no-ssh-upgrade
```

Or disable globally for your shell session:

```bash
export GH_MSYNC_NO_SSH_UPGRADE=1
```

If you have disabled upgrades globally, you can re-enable them for one run:

```bash
gh-msync --ssh-upgrade
```

### Override paths

Use specific directories for one run (ignores config file):

```bash
gh-msync ~/ClientCode ~/SecondaryDrive
```

## Optional Git Alias

If you want `git msync` muscle memory, add a Git alias explicitly (opt-in):

```bash
git config --global alias.msync '!f(){ gh msync "$@" 2>/dev/null || gh-msync "$@"; }; f'
```

Notes:
- This is optional and is not configured automatically by installers.
- This forwards all flags/arguments (for example `git msync --cli`).
- This tries extension mode first (`gh msync`) and falls back to standalone mode (`gh-msync`).

---

## Uninstallation

Cleanup behavior depends on install method:

- **If you installed via Homebrew (removes Homebrew-managed files):**  
  ```bash
  brew uninstall gh-msync
  ```  
  Optional manual cleanup after that: remove `~/.config/gh-msync`, any old `~/.local/bin/gh-msync` symlink, and any app/desktop files created by from-source installs.

- **If you installed from source (install script or macOS/Linux installers, complete cleanup):**  
  - **macOS:** Double-click `macOS-Uninstall.command`.  
  - **Linux:** Double-click `Linux-Uninstall.sh` or run it in a terminal.  
  - **Any:** From repo root: `./scripts/uninstall.sh`.

The from-source uninstaller removes the same set of items (including the app in the repo directory if it still exists there).

---

## Project structure

| Path | Purpose |
|------|--------|
| `scripts/gh-msync` | Main executable used by direct runs and installer-created app/desktop launchers. |
| `gh-msync` | GitHub CLI extension entrypoint (`gh msync`). |
| `scripts/install.sh` | From-source installer (symlink, config, app/desktop). |
| `scripts/uninstall.sh` | From-source uninstaller. |
| `macOS-Install.command` | macOS entry point → runs `scripts/install.sh`. |
| `Linux-Install.sh` | Linux entry point → runs `scripts/install.sh`. |
| `macOS-Uninstall.command` / `Linux-Uninstall.sh` | Entry points → run `scripts/uninstall.sh`. |
| `packaging/homebrew/gh-msync.rb` | Homebrew formula (installs only the binary; does not run `install.sh`). |
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

- **SSH errors**  
  Configure a GitHub SSH key and add it to your account. GitHub Multi-Sync upgrades HTTPS remotes to SSH.

- **Don’t want remotes auto-converted to SSH**  
  Run with `gh-msync --no-ssh-upgrade`, or set `GH_MSYNC_NO_SSH_UPGRADE=1` in your shell environment.

---

## Contributing

Pull requests and issues are welcome. For bugs or feature requests, please open an issue.

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

<div align="center">

*© 2026 Sahil Kamal*

</div>
