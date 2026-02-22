# ☯︎ GitHub Sync

![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)

Cross-platform Git repository synchronizer with Bash and Powershell backends. Built for macOS, Linux, and Windows.

## Features
- **Parallel Fetching:** Iterates and pulls repositories concurrently, falling back gracefully if errors occur.
- **Fail-safe Rebase Protections:** Runs `git rebase --abort` on background tasks that fail due to merge conflicts or network errors, protecting your repository from being stuck in a dirty state.
- **Dynamic System Integrations:** Native Notification alerts, AppleScript/Bash hybrid application wrappers on macOS, and `.desktop` launchers on Linux Desktop.
- **Interactive Configuration Menus:** Ships with a stateful GUI menu on both macOS and Linux that allows infinite folder selection, multi-directory tracking, and individual folder removal via checkbox lists.
- **Auto SSH Upgrades:** Dynamically detects and upgrades standard `https://` remotes to `git@github.com:` SSH remotes, bypassing strict token authentication limits and avoiding hardcoded usernames.
- **Clean, Animated UI:** Provides a beautiful, easy-to-read progress spinner and sequentially resolves concurrent background jobs for a premium terminal experience.

## Requirements
- `git`
- `bash`

### Optional: Cloning Missing Repositories
This utility allows you to seamlessly detect and clone repositories you own on GitHub that are missing from your local machine. Because this action taps into your GitHub account directly, it strictly requires the official **GitHub CLI (`gh`)** to be installed and authenticated.

1. **Install `gh`:** Follow the [official installation instructions](https://cli.github.com/manual/installation) for your OS (e.g. `brew install gh` on macOS, or `sudo apt install gh` on Debian/Ubuntu).
2. **Authenticate:** Open your terminal and run the following command to securely link your machine:
   
   ```bash
   gh auth login
   ```
   
4. Follow the interactive prompts to log in via your web browser. Once finished, this utility will automatically discover your account on its next run and offer a GUI or Terminal prompt to clone any missing repositories!

### SSH Configuration Required
Because this utility dynamically upgrades all remotes to secure SSH connections (as noted in Features), **you must have a GitHub SSH Key configured on your machine.**

If you do not have an SSH key set up, you can generate one quickly. Open your terminal (or Git Bash on Windows) and run this universal command:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Press **Enter** to accept the default file location, and optionally set a secure passphrase.

Once generated, you will need to link it to your GitHub account:
1. Copy your new public key to your clipboard:
   - **macOS:** `pbcopy < ~/.ssh/id_ed25519.pub`
   - **Linux:** `cat ~/.ssh/id_ed25519.pub` *(then copy the output)*
   - **Windows:** `clip < ~/.ssh/id_ed25519.pub`
2. Go to **Settings > SSH and GPG keys > New SSH key** on GitHub and paste your key. *(See the [official guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account) for more details).*

*(For advanced troubleshooting or managing the ssh-agent, refer to GitHub's [official SSH generation guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent).)*

## Installation
**macOS**
Open this folder in your file manager and double-click `macOS-Install.command`.

**Linux:**
Open this folder in your file manager and double-click `Linux-Install.sh`.

**Terminal:**
Ensure you are in the root directory and run:

```bash
./scripts/install.sh
```

**The installer will automatically:**
1. Make the core scripts executable.
2. Link the `github-sync` CLI utility and `ghsync` alias to your designated local binaries folder (`~/.local/bin/`).
3. Safely configure your active shell environment (`~/.zshrc`, `~/.bashrc`, or `~/.bash_profile`) to natively export this folder to your `$PATH`, allowing you to seamlessly invoke the commands globally.
4. Generate a Spotlight-searchable macOS wrapper (`GitHub Sync.app`) or a launcher `.desktop` shortcut on Linux.

## Usage

**Launching the Application:**
Once installed, you can trigger the synchronization process anytime by:
1. Searching for **GitHub Sync** via macOS Spotlight Search (or Launchpad).
2. Launching **GitHub Sync** from your Linux Desktop application menu.
3. Typing `github-sync` (or the `ghsync` command alias) from any directory in your terminal.

By default, the script looks for repositories in `~/GitHub`.

**Headless CLI Mode:**
If you wish to run the synchronization, installation, or uninstallation scripts in a purely headless Terminal environment (bypassing all graphical Pop-up UIs), simply append the `--cli` (or `--headless`) flag to your command:

```bash
ghsync --cli
```
*This flag optimally bypasses AppleScript, Zenity, and kdialog checks across all operating systems, enforcing a standard generic Bash prompt fallback natively.*

**Custom Paths & Configuration:**
During the double-click installation sequence, a native desktop popup menu will appear. This menu allows you to browse and select multiple directories via your OS file-picker. You can configure folders from entirely different root drives, and remove tracked items via a native checkbox UI.

Alternatively, you can override configurations on the fly by trailing the parent directories via CLI arguments:

```bash
ghsync ~/CustomClientCode ~/SecondaryBackupDrive
```

## Uninstallation

To completely remove the CLI link, desktop application, and wipe your repository configurations (`~/.config/github-sync`), you can utilize the provided centralized teardown scripts exactly how you installed the application:

1. **macOS:** Double-click `macOS-Uninstall.command`
2. **Linux:** Double-click `Linux-Uninstall.sh`
3. **Terminal:** `./scripts/uninstall.sh`

#
*© 2026 Sahil Kamal*
