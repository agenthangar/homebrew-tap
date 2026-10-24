# frozen_string_literal: true

# Install the explicit bootstrap command, leaving configuration in a Git clone.
class Dotfiles < Formula
  desc "Set up AgentHangar shell configuration and utilities"
  homepage "https://github.com/agenthangar/dotfiles"
  url "https://github.com/agenthangar/dotfiles/archive/cb7f068d1cfe37ab57b7dc6ebbd873b58bee7522.tar.gz"
  version "0.2.0"
  sha256 "0a747ad36e45f149e18a7bb87911ffa8f0adc166653f5e25e7490deea9923940"
  license "MIT"

  depends_on "git"
  depends_on "python@3.14"
  depends_on "zsh"

  def install
    (libexec/"bin").install "bin/dots"
    (libexec/"scripts").install "scripts/dotfiles-setup"
    bin.install_symlink libexec/"bin/dots", libexec/"scripts/dotfiles-setup"
  end

  def caveats
    <<~EOS
      Run the Homebrew command explicitly to configure this account:
        #{opt_bin}/dots install

      This clones into ~/code/dotfiles by default. To choose another location:
        #{opt_bin}/dots install /path/to/dotfiles

      Setup runs the dotfiles installer, which backs up existing shell files,
      links configuration into your home directory, and installs dependencies.
      Existing destinations must be clean canonical dotfiles clones on main.

      Then open a new shell or run: source ~/.zshrc
      Use dots update to update your configuration. Homebrew upgrades the
      packaged CLI; your writable checkout and its command update with dots.
      Uninstalling this formula leaves your checkout and shell intact.
      The old dotfiles-setup command remains an alias for dots install.
    EOS
  end

  test do
    ENV["HOME"] = testpath.to_s
    ENV["GIT_CONFIG_GLOBAL"] = File::NULL
    ENV["GIT_CONFIG_NOSYSTEM"] = "1"
    assert_match "Usage: dots", shell_output("#{bin}/dots --help")
    assert_match "Usage: dots install", shell_output("#{bin}/dots install --help")
    assert_match "Usage: dots install", shell_output("#{bin}/dotfiles-setup --help")
    assert_match "run dots install first", shell_output("#{bin}/dots update 2>&1", 1)
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
    system bin/"dots", "install", checkout
    assert_path_exists testpath/"setup-ran"
  end
end
