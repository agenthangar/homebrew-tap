# frozen_string_literal: true

# Install the explicit bootstrap command, leaving configuration in a Git clone.
class Dotfiles < Formula
  desc "Set up AgentHangar shell configuration and utilities"
  homepage "https://github.com/agenthangar/dotfiles"
  url "https://github.com/agenthangar/dotfiles/archive/5040ecd4dca58a7c7cc1fe93d2e10ed5fa34556c.tar.gz"
  version "0.1.0"
  sha256 "987dfb97224f94028c32cf318a781aeaddbdaf8b265a5ff3fd7139310fca0675"
  license "MIT"

  depends_on "git"
  depends_on "python@3.14"
  depends_on "zsh"

  def install
    bin.install "scripts/dotfiles-setup"
  end

  def caveats
    <<~EOS
      Run dotfiles-setup to clone dotfiles into ~/code/dotfiles and configure
      your shell. To choose another location: dotfiles-setup /path/to/dotfiles

      Setup runs the dotfiles installer, which backs up existing shell files,
      links configuration into your home directory, and installs dependencies.
      Existing destinations must be clean canonical dotfiles clones on main.

      Use dots to update your configuration. Homebrew upgrades only the setup
      command. Uninstalling this formula leaves your checkout and shell intact.
    EOS
  end

  test do
    ENV["HOME"] = testpath.to_s
    ENV["GIT_CONFIG_GLOBAL"] = File::NULL
    ENV["GIT_CONFIG_NOSYSTEM"] = "1"
    assert_match "Usage: dotfiles-setup", shell_output("#{bin}/dotfiles-setup --help")
    refute_path_exists testpath/"code"

    # Reuse a local fixture; no network or real shell configuration is needed.
    checkout = testpath/"checkout with spaces"
    checkout.mkpath
    (checkout/".zshrc").write "# test shell\n"
    (checkout/"install.sh").write <<~SH
      #!/bin/sh
      touch "$HOME/setup-ran"
    SH
    system "git", "init", "-b", "main", checkout
    system "git", "-C", checkout, "add", "."
    system "git", "-C", checkout, "-c", "user.name=Test", "-c", "user.email=test@example.com",
           "-c", "core.hooksPath=/dev/null", "commit", "-m", "fixture"
    system "git", "-C", checkout, "remote", "add", "origin", "https://github.com/agenthangar/dotfiles.git"
    system bin/"dotfiles-setup", checkout
    assert_path_exists testpath/"setup-ran"
  end
end
