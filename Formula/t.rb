# frozen_string_literal: true

require "json"

class T < Formula
  include Language::Python::Shebang

  desc "Coding-agent sessions in isolated Git worktrees and tmux"
  homepage "https://github.com/agenthangar/t"
  url "https://github.com/agenthangar/t/releases/download/v0.3.0/t.tar.gz"
  sha256 "8c2cad1b9bc96d886ae23efb847e59f679c921ed6f81620fcf355ed1a073d9ba"
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
      Run the Homebrew command explicitly to link its prompts and helpers:
        #{opt_bin}/t integrate

      Then add to your ~/.zshrc:
        export PATH="$HOME/bin:$PATH"
        source "${${:-$HOME/bin/t}:A:h:h}/t.plugin.zsh"
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
    assert_match "t v#{version}", shell_output("#{bin}/t --version")
    system bin/"t", "ls"
    system bin/"t", "integrate"
    assert_equal (opt_libexec/"bin/t").to_s, (testpath/"bin/t").readlink.to_s
    assert_equal (opt_libexec/"claude/commands/tpush.md").to_s,
                 (testpath/".claude/commands/tpush.md").readlink.to_s
  end
end
