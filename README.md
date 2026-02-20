# GitHub Sync

![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)

A highly polished, reliable, and OS-aware shell utility to effortlessly synchronize multiple local GitHub repositories at once.

## Features
- **Parallel Fetching:** Iterates and pulls repositories concurrently, falling back gracefully if errors occur.
- **Fail-safe Rebase Protections:** Intelligently runs `git rebase --abort` on background tasks that fail due to merge conflicts or network errors, protecting your repository from being stuck in a dirty state.
- **Dynamic System Integrations:** Native Notification alerts, AppleScript/Bash hybrid application wrappers on macOS, and `.desktop` launchers on Linux Desktop.
- **Interactive Configuration Menus:** Ships with a stateful GUI menu on both macOS and Linux that allows infinite folder selection, multi-directory tracking, and individual folder removal via checkbox lists.

## Requirements
- `git`
- `bash`

### SSH Configuration Required
Because this utility dynamically upgrades standard `https://` remotes to `git@github.com:` SSH remotes (bypassing strict authentication limits and hardcoded usernames), **you must have a GitHub SSH Key configured on your machine.**

If you do not have an SSH key set up for GitHub, follow GitHub's official universal guide for your specific OS:
1. [Generating a new SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
2. [Adding the SSH key to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)

## Installation
**For macOS (One-Click):**
Open this folder in your file manager and double-click `macOS-Install.command`.

**For Linux Desktop (One-Click):**
Open this folder in your file manager and double-click `Linux-Install.sh`.

**Terminal Users (All OS):**
Ensure you are in the root directory and run:

```bash
./scripts/install.sh
```

**The installer will automatically:**
1. Make the core script executable.
2. Link the CLI utility to your path (`~/.local/bin/github-sync`), allowing you to invoke it from anywhere.
3. Generate a Spotlight-searchable macOS wrapper (`GitHub Sync.app`) or a launcher `.desktop` shortcut on Linux.

## Usage

By default, the script looks for repositories in `~/GitHub`, `~/Projects`, `~/Scripts`, and `~/Repositories`.

**Custom Paths & Configuration:**
During the 1-click installation sequence, a native desktop popup menu will appear. This menu allows you to browse and select infinite directories via your OS file-picker, visually seeing what is currently being tracked. You can configure folders from entirely different root drives, and remove tracked items via a native checkbox UI.

Alternatively, you can override configurations on the fly by trailing the parent directories via CLI arguments:

```bash
github-sync ~/CustomClientCode ~/SecondaryBackupDrive
```

## Uninstallation

To completely remove the CLI link, desktop application, and wipe your repository configurations (`~/.config/github-sync`), you can utilize the provided centralized teardown scripts exactly how you installed the application:

1. **macOS:** Double-click `macOS-Uninstall.command`
2. **Linux:** Double-click `Linux-Uninstall.sh`
3. **Terminal:** `./scripts/uninstall.sh`
