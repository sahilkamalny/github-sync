# GitHub Sync

![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)

A highly polished, reliable, and OS-aware shell utility to effortlessly synchronize multiple local GitHub repositories at once.

## Features
- **Parallel Fetching:** Iterates and pulls repositories concurrently.
- **Dynamic Configuration:** Automatically rewrites HTTPS remotes to SSH to circumvent authentication limits and bypass hardcoded user parameters.
- **Fail-safes:** Detects and skips synchronization for repositories with uncommitted changes to prevent overwriting your work.
- **Native Notifications:** Displays OS-level graphical notifications upon completion (macOS and Linux).
- **Universal Installer:** Ships with an automated, one-step installer.

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
*(To remove it later, simply double-click `macOS-Uninstall.command`)*

**For Linux Desktop (One-Click):**
Open this folder in your file manager and double-click `Linux-Install.sh`.
*(To remove it later, simply double-click `Linux-Uninstall.sh`)*

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

By default, the script looks for repositories in `~/GitHub`, `~/Scripts`, and `~/Projects`. 

**Custom Paths & Configuration:**
During the 1-click installation sequence, a native desktop popup UI will prompt you to enter any custom repository folder paths. These paths will be securely saved into a configuration file. 

Alternatively, you can skip the installer and override configurations on the fly by trailing the parent directories via CLI arguments:

```bash
github-sync ~/CustomClientCode ~/SecondaryBackupDrive
```
