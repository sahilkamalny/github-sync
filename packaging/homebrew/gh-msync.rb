# typed: false
# frozen_string_literal: true

# GitHub Multi-Sync: GitHub-oriented multi-repository sync utility.
class GhMsync < Formula
  desc "GitHub repository multi-sync utility"
  homepage "https://github.com/sahilkamalny/gh-msync"
  url "https://github.com/sahilkamalny/gh-msync/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "b5731501af3309f15e4e91e669ebac64c891cac3af7e6a72e4183bdfe70f3a82"
  license "MIT"

  depends_on "git"

  def install
    bin.install "scripts/gh-msync" => "gh-msync"
    libexec.install "scripts/configure-paths.sh" => "gh-msync-configure"
    FileUtils.chmod 0755, libexec/"gh-msync-configure"
  end

  def post_install
    config_dir = File.expand_path("~/.config/gh-msync")
    config_file = File.join(config_dir, "config")
    return if File.exist?(config_file)

    FileUtils.mkdir_p config_dir
    File.write(config_file, "~/GitHub\n")
  end

  caveats <<~EOS
    Run directly:
      gh-msync

    Configure which directories to sync (GUI or CLI):
      gh-msync --configure
      gh-msync --configure --cli   # terminal prompts only

    Optional: install GitHub CLI for missing-repo cloning and extension mode:
      brew install gh
      gh auth login

    Optional: install as a GitHub CLI extension (requires `gh`):
      gh extension install sahilkamalny/gh-msync
      gh msync

    Optional manual cleanup after `brew uninstall gh-msync`:
      rm -rf ~/.config/gh-msync
      rm -f ~/.local/bin/gh-msync
      rm -rf "/Applications/GitHub Multi-Sync.app" "$HOME/Applications/GitHub Multi-Sync.app" "$HOME/Desktop/GitHub Multi-Sync.app"
      rm -f "$HOME/.local/share/applications/gh-msync.desktop" "$HOME/Desktop/gh-msync.desktop"
      # If you previously added PATH manually, remove this line from your shell rc files:
      #   export PATH="$HOME/.local/bin:$PATH"

    You can also edit ~/.config/gh-msync/config (one path per line)
    or pass paths on the command line: gh-msync ~/GitHub ~/Projects
  EOS

  test do
    (testpath/"empty").mkdir
    assert_match "No Git repositories found", shell_output("#{bin}/gh-msync --cli #{testpath}/empty 2>&1", 0)
  end
end
