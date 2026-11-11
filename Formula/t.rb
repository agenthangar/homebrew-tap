# frozen_string_literal: true

require "json"

class T < Formula
  include Language::Python::Shebang

  desc "Coding-agent sessions in isolated Git worktrees and tmux"
  homepage "https://github.com/agenthangar/t"
  url "https://github.com/agenthangar/t/releases/download/v0.6.12/t.tar.gz"
  sha256 "330154efba2c4c549a5b8b2a5363a0392ef5cc73129298f28d8e5590724d724a"
  license "MIT"

  depends_on "git"
  depends_on "python@3.14"
  depends_on "tmux"
  depends_on "zsh"

  def install
    libexec.install Dir["*"], ".t-install-version", ".t-release-version"
    rewrite_shebang detected_python_shebang, libexec/"bin/t", libexec/"bin/nosleep"
    marker = {
      formula:     "agenthangar/tap/t",
      opt_libexec: opt_libexec.to_s,
      brew:        (HOMEBREW_PREFIX/"bin/brew").to_s,
    }
    (libexec/".t-homebrew").write("#{JSON.generate(marker)}\n")
    bin.install_symlink libexec/"bin/t", libexec/"bin/nosleep"
  end

  def caveats
    <<~EOS
      Get started:
        t
    EOS
  end

  test do
    ENV["HOME"] = testpath.to_s
    ENV["XDG_CONFIG_HOME"] = (testpath/".config").to_s
    ENV["XDG_DATA_HOME"] = (testpath/".local/share").to_s
    ENV["XDG_CACHE_HOME"] = (testpath/".cache").to_s
    ENV["XDG_STATE_HOME"] = (testpath/".local/state").to_s
    # Homebrew permits Unix sockets inside its short sandbox temp directory.
    ENV["XDG_RUNTIME_DIR"] = ENV.fetch("HOMEBREW_TEMP")
    ENV["TMUX_TMPDIR"] = ENV.fetch("HOMEBREW_TEMP")
    ENV["CODEX_HOME"] = (testpath/".codex").to_s
    ENV["CLAUDE_CONFIG_DIR"] = (testpath/".claude").to_s
    ENV["T_NO_UPDATE_CHECK"] = "1"
    ENV["T_LOCAL_RC"] = (testpath/".config/t/local.zsh").to_s
    ENV["T_NO_MCP"] = "1"
    ENV["T_NO_CODEX_HOOKS"] = "1"
    ENV["T_NO_PERMISSIONS"] = "1"
    ENV["T_NO_TRUST"] = "1"
    ENV["TMUX"] = ""
    before = Dir.glob("#{testpath}/**/*", File::FNM_DOTMATCH).sort
    assert_match "USAGE", shell_output("#{bin}/t")
    assert_equal before, Dir.glob("#{testpath}/**/*", File::FNM_DOTMATCH).sort
    assert_match "t v#{version}", shell_output("#{bin}/t --version")
    assert_match "nosleep —", shell_output("#{bin}/nosleep --help")
    assert_match "nosleep defaults", shell_output("#{bin}/nosleep config --show")
    refute_path_exists testpath/".config/nosleep/config.json"
    system bin/"t", "session", "list", "--local"
    # The installer may offer instruction migration when stdin is a terminal.
    assert_match "Run t config setup", shell_output("#{bin}/t system integrate </dev/null")
    assert_equal (opt_libexec/"bin/t").to_s, (testpath/"bin/t").readlink.to_s
    assert_equal (opt_libexec/"bin/nosleep").to_s, (testpath/"bin/nosleep").readlink.to_s
    assert_equal (opt_libexec/"claude/commands/tpush.md").to_s,
                 (testpath/".claude/commands/tpush.md").readlink.to_s
  end
end
