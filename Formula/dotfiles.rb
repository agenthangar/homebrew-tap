# frozen_string_literal: true

# Complete runtime distribution; no user-side Git checkout is needed.
class Dotfiles < Formula
  desc "Set up AgentHangar shell configuration and utilities"
  homepage "https://github.com/agenthangar/dotfiles"
  url "https://github.com/agenthangar/dotfiles/archive/40974b821bd9ceb938e93a602a1f3bccd93ab8f6.tar.gz"
  version "0.4.0"
  sha256 "7d1d2a1fa623a30eb293e3b3f76e293d28fb75beb1d31a658749e2841865112a"
  license "MIT"

  depends_on "fzf"
  depends_on "gh"
  depends_on "git"
  depends_on "glow"
  depends_on "jq"
  depends_on "python@3.14"
  depends_on "tmux"
  depends_on "zsh"

  def install
    libexec.install "bin", "lib", "agents", "ssh", "launchd", "scripts",
                    "install.sh", "Brewfile", ".zshrc", ".tmux.conf", ".zshrc.local.example",
                    "pii-allowlist.txt", "pii-ignore-patterns.txt"
    (libexec/".dotfiles-package").write("#{opt_libexec}\n")
    (libexec/".dotfiles-version").write("#{version}\n")
    bin.install_symlink libexec/"bin/dots", libexec/"scripts/dotfiles-setup"
  end

  def caveats
    <<~EOS
      Apply the installed package to this account:
        #{opt_bin}/dots

      No Git checkout is required. Configuration and utilities come from
      Homebrew; your settings remain in ~/.zshrc.local.
      Existing checkout-based installs are migrated without deleting the checkout.

      Open a new shell or run: source ~/.zshrc
      Run dots to upgrade through Homebrew and apply the installed configuration.
      dots --relink reapplies it offline. dots install reruns full account setup.
      Uninstalling the package leaves your settings but removes its runtime.
    EOS
  end

  test do
    ENV["HOME"] = testpath.to_s
    ENV["XDG_CONFIG_HOME"] = (testpath/".config").to_s
    ENV["DOTFILES_NO_T"] = "1"
    ENV["DOTFILES_NO_TMUX"] = "1"
    ENV["DOTFILES_NO_CLIP_BRIDGE"] = "1"
    ENV["DOTFILES_NO_SUDO"] = "1"
    ENV["GIT_CONFIG_GLOBAL"] = File::NULL
    ENV["GIT_CONFIG_NOSYSTEM"] = "1"
    assert_match "Usage: dots", shell_output("#{bin}/dots --help")
    assert_match "Usage: dots install", shell_output("#{bin}/dotfiles-setup --help")
    (testpath/".zshrc.local").write "# keep local settings\n"
    system bin/"dots"
    refute_path_exists testpath/"code"
    refute_predicate testpath/".zshrc", :symlink?
    assert_path_exists testpath/".config/dotfiles/installed"
    assert_equal "# keep local settings\n", (testpath/".zshrc.local").read
    assert_equal (opt_libexec/"bin/sleep-manager").to_s, (testpath/"bin/sleep-manager").readlink.to_s
    system bin/"dots", "--relink"
    assert_match "nosleep", shell_output("zsh -f -c 'source ~/.zshrc; nosleep --help'")
  end
end
