# typed: false
# frozen_string_literal: true

# Git Multi-Sync: native Git subcommand to sync multiple repositories in parallel.
class GitMsync < Formula
  desc "Native Git subcommand to sync multiple repositories in parallel"
  homepage "https://github.com/sahilkamalny/git-msync"
  url "https://github.com/sahilkamalny/git-msync/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"

  depends_on "git"
  depends_on "gh"

  def install
    bin.install "scripts/git-msync" => "git-msync"
    libexec.install "scripts/configure-paths.sh" => "git-msync-configure"
    FileUtils.chmod 0755, libexec/"git-msync-configure"
  end

  def post_install
    config_dir = File.expand_path("~/.config/git-msync")
    config_file = File.join(config_dir, "config")
    return if File.exist?(config_file)

    FileUtils.mkdir_p config_dir
    File.write(config_file, "~/GitHub\n")
  end

  def uninstall
    home = Dir.home
    path_line = 'export PATH="$HOME/.local/bin:$PATH"'

    # Config directory
    config_dir = File.join(home, ".config", "git-msync")
    FileUtils.rm_rf config_dir if File.directory?(config_dir)

    # ~/.local/bin symlink/binary (from-source installs)
    local_bin = File.join(home, ".local", "bin", "git-msync")
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
    app_name = "Git Multi-Sync.app"
    [
      "/Applications/#{app_name}",
      File.join(home, "Applications", app_name),
      File.join(home, "Desktop", app_name)
    ].each do |path|
      FileUtils.rm_rf path if File.directory?(path)
    end

    # Linux desktop entry
    [
      File.join(home, ".local", "share", "applications", "git-msync.desktop"),
      File.join(home, "Desktop", "git-msync.desktop")
    ].each do |path|
      FileUtils.rm_f path if File.exist?(path)
    end

    # Legacy directory (if created in home or common location)
    legacy_dir = File.join(home, "Git Multi-Sync")
    FileUtils.rm_rf legacy_dir if File.directory?(legacy_dir)
  end

  caveats <<~EOS
    Run as a Git subcommand:
      git msync

    Configure which directories to sync (GUI or CLI):
      git msync --configure
      git msync --configure --cli   # terminal prompts only

    You can also edit ~/.config/git-msync/config (one path per line)
    or pass paths on the command line: git msync ~/GitHub ~/Projects
  EOS

  test do
    (testpath/"empty").mkdir
    assert_match "No Git repositories found", shell_output("#{bin}/git-msync --cli #{testpath}/empty 2>&1", 0)
  end
end
