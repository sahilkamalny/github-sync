<div align="center">

# Git Multi-Sync

**Native Git subcommand to sync multiple repositories in parallel — `git msync` with automatic SSH upgrades and native OS integrations.**

[![Bash](https://img.shields.io/badge/Bash-5+-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![macOS](https://img.shields.io/badge/macOS-Supported-000000?style=flat-square&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/Linux-Supported-FCC624?style=flat-square&logo=linux&logoColor=black)](https://kernel.org/)
[![Windows](https://img.shields.io/badge/Windows-Supported-0078D6?style=flat-square&logo=windows&logoColor=white)](https://www.microsoft.com/windows/)

**Built with** Bash · GitHub CLI · AppleScript

[Portfolio](https://sahilkamal.dev) · [LinkedIn](https://linkedin.com/in/sahilkamalny) · [Contact](mailto:sahilkamal.dev@gmail.com)

</div>

---

<div align="center">
  <img src="assets/demo.gif" alt="Git Multi-Sync Terminal Recording" width="800">
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
- [Uninstallation](#uninstallation)
- [Project structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

Git Multi-Sync (`git-msync`) is a cross-platform utility that runs as a **native Git subcommand**. Run `git msync` from any directory to discover and pull all your local Git repositories in parallel. It ships with a Spotlight-searchable **Git Multi-Sync** app on macOS and a **Git Multi-Sync** launcher on Linux. Automatic HTTPS→SSH remote upgrades, fail-safe rebase protection, and an interactive configuration menu are included.

---

## Features

- **Native Git subcommand** — Install once; run `git msync` from anywhere. No aliases required.
- **Parallel fetching** — Pulls all tracked repositories concurrently, with per-repo fallback on errors.
- **Fail-safe rebase protection** — Runs `git rebase --abort` on failed pulls so repositories are never left in a dirty state.
- **Auto SSH upgrades** — Detects `https://` remotes and upgrades them to `git@github.com:` SSH.
- **Native OS integrations** — macOS `.app` and Linux `.desktop` launcher (both named **Git Multi-Sync**), with native notifications.
- **Interactive configuration** — GUI menu on macOS and Linux for multi-directory tracking.
- **Animated terminal UI** — Progress spinner and sequential result output.

---

## Prerequisites

- **Required:** `git`, `bash` (or Git Bash on Windows).
- **Optional (clone missing repos):** GitHub CLI (`gh`), installed and authenticated (`gh auth login`).
- **Required for remote access:** A [GitHub SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account) — Git Multi-Sync upgrades remotes to SSH.

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
   - **Homebrew (macOS & Linux):** `brew install sahilkamalny/homebrew-tap/git-msync`
   - **From source:** Clone this repo and run `./scripts/install.sh` (or double-click `macOS-Install.command` / `Linux-Install.sh` on supported platforms).
2. **Run:** `git msync` from any directory.
3. **Configure paths (optional):** Run `git msync --configure` to pick directories in a GUI or at the terminal. You can also edit `~/.config/git-msync/config` (one path per line). Default is `~/GitHub`.

---

## Installation

### Option A: Homebrew (macOS & Linux, recommended when available)

Works on **macOS and Linux** (Homebrew supports both). The install command is **`brew install git-msync`** (one token). There is no `brew install git msync` — the formula name is always `git-msync`; after install, users run the Git subcommand as **`git msync`** (with a space).

Install with one command (Homebrew taps the repo automatically):

```bash
brew install sahilkamalny/homebrew-tap/git-msync
```

If they have already run `brew tap sahilkamalny/homebrew-tap`, they can use:

```bash
brew install git-msync
```

- The binary is installed to your Homebrew prefix (e.g. `/opt/homebrew/bin` on Apple Silicon, `/usr/local/bin` on Intel, or Linux Homebrew’s prefix) as `git-msync`.
- Git invokes it for `git msync` automatically.
- A default config is created at `~/.config/git-msync/config` with `~/GitHub` if it doesn’t exist. To choose your directories the same way as the from-source installer (GUI or CLI), run **`git msync --configure`** (or `git msync --configure --cli` for terminal-only). See [Configuration](#configuration).
- Homebrew does not create the **Git Multi-Sync** macOS app or Linux desktop launcher; use the from-source installer (Option B) if you want those. Path configuration is identical: `git msync --configure`.

To **uninstall** (complete cleanup: binary, config, any from-source symlink/PATH/app/desktop):

```bash
brew uninstall git-msync
```

This removes the binary, `~/.config/git-msync`, any `~/.local/bin/git-msync` symlink, the PATH line the from-source installer may have added, and the Git Multi-Sync app/desktop launcher from standard locations.

### Option B: From source (all platforms)

| Platform   | Method |
|-----------|--------|
| **macOS** | Double-click `macOS-Install.command` in the repo root. |
| **Linux** | Double-click `Linux-Install.sh` (or run it in a terminal). |
| **Any**   | From repo root: `./scripts/install.sh` |

The installer will:

1. Create `~/.config/git-msync` and optionally prompt for repository paths (GUI or CLI).
2. Make `scripts/git-msync` executable and symlink it to `~/.local/bin/git-msync`.
3. Ensure `~/.local/bin` is on your `PATH` (by appending to your shell rc file if needed).
4. On macOS: create **Git Multi-Sync.app** in the repo directory (you can move it to Applications or the Desktop).
5. On Linux: create a **Git Multi-Sync** desktop entry in `~/.local/share/applications`.

After installation, run `git msync` from any directory. You can also launch **Git Multi-Sync** from Spotlight (macOS) or the application menu (Linux).

---

## Configuration

The tool needs to know which **directory (or directories)** hold your Git repos. Those paths are used whenever you run `git msync` with no arguments.

**Option 1 — Path picker (recommended):** Run:

```bash
git msync --configure
```

This opens the same GUI (macOS/Linux) or a terminal prompt you get with the from-source installer. Use `git msync --configure --cli` to force terminal-only prompts. The chosen paths are saved to `~/.config/git-msync/config`.

**Option 2 — Edit the config file:** `~/.config/git-msync/config` — one path per line (e.g. `~/GitHub` or `~/Projects`). Blank lines and lines starting with `#` are ignored.

**Option 3 — Pass paths each time:** `git msync ~/GitHub ~/Projects` (see [Usage](#usage)).

**Default:** If no config exists, `~/GitHub` is used.

---

## Usage

### Basic

```bash
git msync
```

Uses paths from `~/.config/git-msync/config` (or `~/GitHub` if unset), pulls all repos in parallel, and optionally prompts to clone missing repositories if `gh` is installed and authenticated.

### Configure paths

```bash
git msync --configure          # GUI or CLI path picker
git msync --configure --cli   # terminal prompts only
```

Saves chosen directories to `~/.config/git-msync/config` so future `git msync` runs use them automatically.

### Headless / CLI only

Disable GUI dialogs and use terminal prompts only:

```bash
git msync --cli
# or
git msync --headless
```

### Override paths

Use specific directories for one run (ignores config file):

```bash
git msync ~/ClientCode ~/SecondaryDrive
```

### Direct binary

If the binary is on your `PATH`, you can also run:

```bash
git-msync
```

Behavior is the same; `git msync` is the preferred interface.

---

## Uninstallation

Both methods give you a **complete uninstall** (binary, config, PATH, app/desktop).

- **If you installed via Homebrew:**  
  ```bash
  brew uninstall git-msync
  ```  
  This removes the formula binary, `~/.config/git-msync`, any `~/.local/bin/git-msync` symlink, the PATH line the from-source installer may have added, and the **Git Multi-Sync** app/desktop launcher from standard locations.

- **If you installed from source (install script or macOS/Linux installers):**  
  - **macOS:** Double-click `macOS-Uninstall.command`.  
  - **Linux:** Double-click `Linux-Uninstall.sh` or run it in a terminal.  
  - **Any:** From repo root: `./scripts/uninstall.sh`.

The from-source uninstaller removes the same set of items (including the app in the repo directory if it still exists there).

---

## Project structure

| Path | Purpose |
|------|--------|
| `scripts/git-msync` | Main executable (no extension; Git runs it as `git msync`). |
| `scripts/install.sh` | From-source installer (symlink, config, app/desktop). |
| `scripts/uninstall.sh` | From-source uninstaller. |
| `macOS-Install.command` | macOS entry point → runs `scripts/install.sh`. |
| `Linux-Install.sh` | Linux entry point → runs `scripts/install.sh`. |
| `macOS-Uninstall.command` / `Linux-Uninstall.sh` | Entry points → run `scripts/uninstall.sh`. |
| `packaging/homebrew/git-msync.rb` | Homebrew formula (installs only the binary; does not run `install.sh`). |
| `assets/` | Demo assets (e.g. `demo.tape`, `demo.gif`). |

---

## Troubleshooting

- **`git msync` not found**  
  Ensure the directory containing `git-msync` is on your `PATH`. For from-source installs, that is usually `~/.local/bin`. Restart the terminal or run `source ~/.zshrc` (or your shell rc) after installing.

- **Repos not found**  
  Check that paths in `~/.config/git-msync/config` exist and contain directories with a `.git` subdirectory. Or pass paths explicitly: `git msync /path/to/parent`.

- **Permission denied**  
  Ensure the script is executable: `chmod +x scripts/git-msync`. The installer does this automatically.

- **Clone step not offered**  
  Install and log in to the GitHub CLI: `brew install gh && gh auth login`. Git Multi-Sync uses it to list and clone missing repos.

- **SSH errors**  
  Configure a GitHub SSH key and add it to your account. Git Multi-Sync upgrades HTTPS remotes to SSH.

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
