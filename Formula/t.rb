# frozen_string_literal: true

require "json"

class T < Formula
  include Language::Python::Shebang

  desc "Coding-agent sessions in isolated Git worktrees and tmux"
  homepage "https://github.com/agenthangar/t"
  url "https://github.com/agenthangar/t/releases/download/v0.6.1/t.tar.gz"
  sha256 "ee1e97aa32ef420da26aa9457eed9e0f71d4d5b748bbc8ba0a41bffa6fd48d92"
  license "MIT"

  depends_on "git"
  depends_on "python@3.14"
  depends_on "tmux"
  depends_on "zsh"

  def install
    libexec.install Dir["*"], ".t-install-version", ".t-release-version"
    rewrite_shebang detected_python_shebang, libexec/"bin/t"
    marker = {
      formula:     "agenthangar/tap/t",
      opt_libexec: opt_libexec.to_s,
      brew:        (HOMEBREW_PREFIX/"bin/brew").to_s,
    }
    (libexec/".t-homebrew").write("#{JSON.generate(marker)}\n")
    bin.install_symlink libexec/"bin/t"
  end

  def caveats
    <<~EOS
      Homebrew installed t without changing your shell or agent settings.
      Start t to review and complete setup:
        t

      Setup helps you choose agents, connect your shell, and find repositories.
    EOS
  end

  test do
    ENV["HOME"] = testpath.to_s
    ENV["XDG_CONFIG_HOME"] = (testpath/".config").to_s
    ENV["XDG_DATA_HOME"] = (testpath/".local/share").to_s
    ENV["XDG_CACHE_HOME"] = (testpath/".cache").to_s
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
    system bin/"t", "ls"
    system bin/"t", "integrate"
    assert_equal (opt_libexec/"bin/t").to_s, (testpath/"bin/t").readlink.to_s
    assert_equal (opt_libexec/"claude/commands/tpush.md").to_s,
                 (testpath/".claude/commands/tpush.md").readlink.to_s
  end
end
