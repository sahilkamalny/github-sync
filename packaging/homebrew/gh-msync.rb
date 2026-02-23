# typed: false
# frozen_string_literal: true

# GitHub Multi-Sync: GitHub-oriented multi-repository sync utility.
class GhMsync < Formula
  desc "GitHub repository multi-sync utility"
  homepage "https://github.com/sahilkamalny/gh-msync"
  url "https://github.com/sahilkamalny/gh-msync/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"

  depends_on "git"
  depends_on "gh"

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

  def uninstall
    home = Dir.home
    path_line = 'export PATH="$HOME/.local/bin:$PATH"'

    # Config directory
    config_dir = File.join(home, ".config", "gh-msync")
    FileUtils.rm_rf config_dir if File.directory?(config_dir)

    # ~/.local/bin symlink/binary (from-source installs)
    local_bin = File.join(home, ".local", "bin", "gh-msync")
    FileUtils.rm_f local_bin if File.exist?(local_bin)

    # PATH line from shell rc files
    %w[.zshrc .bash_profile .bashrc .profile].each do |rc|
      rc_path = File.join(home, rc)
      next unless File.file?(rc_path)

      lines = File.readlines(rc_path)
      new_lines = lines.reject { |l| l.include?(path_line) }
      next if lines == new_lines

      File.write(rc_path, new_lines.join)
    end

    # macOS app (standard locations only; repo path unknown here)
    app_name = "GitHub Multi-Sync.app"
    [
      "/Applications/#{app_name}",
      File.join(home, "Applications", app_name),
      File.join(home, "Desktop", app_name)
    ].each do |path|
      FileUtils.rm_rf path if File.directory?(path)
    end

    # Linux desktop entry
    [
      File.join(home, ".local", "share", "applications", "gh-msync.desktop"),
      File.join(home, "Desktop", "gh-msync.desktop")
    ].each do |path|
      FileUtils.rm_f path if File.exist?(path)
    end

    # Legacy directory (if created in home or common location)
    legacy_dir = File.join(home, "GitHub Multi-Sync")
    FileUtils.rm_rf legacy_dir if File.directory?(legacy_dir)
  end

  caveats <<~EOS
    Run directly:
      gh-msync

    Configure which directories to sync (GUI or CLI):
      gh-msync --configure
      gh-msync --configure --cli   # terminal prompts only

    Optional: install as a GitHub CLI extension:
      gh extension install sahilkamalny/gh-msync
      gh msync

    You can also edit ~/.config/gh-msync/config (one path per line)
    or pass paths on the command line: gh-msync ~/GitHub ~/Projects
  EOS

  test do
    (testpath/"empty").mkdir
    assert_match "No Git repositories found", shell_output("#{bin}/gh-msync --cli #{testpath}/empty 2>&1", 0)
  end
end
