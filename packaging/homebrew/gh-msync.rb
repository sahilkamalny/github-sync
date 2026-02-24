# typed: false
# frozen_string_literal: true

# GitHub Multi-Sync: GitHub-oriented multi-repository sync utility.
class GhMsync < Formula
  desc "GitHub repository multi-sync utility"
  homepage "https://github.com/sahilkamalny/gh-msync"
  url "https://github.com/sahilkamalny/gh-msync/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "2c9035fd9fe7264721ae1e1fced351017d8d7570a8491ffe138994854c8fe728"
  license "MIT"

  depends_on "git"

  def install
    bin.install "scripts/gh-msync" => "gh-msync"
    libexec.install "scripts/configure-paths.sh" => "gh-msync-configure"
    libexec.install "scripts/system-integrations.sh"
    FileUtils.chmod 0755, libexec/"gh-msync-configure"
    FileUtils.chmod 0755, libexec/"system-integrations.sh"
  end

  def post_install
    config_dir = File.expand_path("~/.config/gh-msync")
    config_file = File.join(config_dir, "config")
    unless File.exist?(config_file)
      FileUtils.mkdir_p config_dir
      File.write(config_file, "~/GitHub\n")
    end

    helper = libexec/"system-integrations.sh"
    if helper.exist? && !quiet_system(helper, "install", "--quiet", "--preferred-script", bin/"gh-msync")
      opoo "Could not install GitHub Multi-Sync launcher integrations automatically. Run `gh-msync --install-launcher` manually."
    end
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

    Removes Homebrew-managed files:
      brew uninstall gh-msync

    Also remove the shared macOS/Linux app launcher integrations (same across install methods):
      gh-msync --uninstall-launcher

    Optional full user-data cleanup after that:
      rm -rf ~/.config/gh-msync
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
