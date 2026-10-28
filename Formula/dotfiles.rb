# frozen_string_literal: true

# Complete runtime distribution; no user-side Git checkout is needed.
class Dotfiles < Formula
  desc "Set up AgentHangar shell configuration and utilities"
  homepage "https://github.com/agenthangar/dotfiles"
  url "https://github.com/agenthangar/dotfiles/archive/7ddb9815804af1f671bf911b78121bb315a0f70d.tar.gz"
  version "0.9.3"
  sha256 "c376c6c153b44cd0fb8011c87f617a440323bcb7d19fee88b0c9691cef050eb3"
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
    help = shell_output("zsh -f -c 'source ~/.zshrc; nosleep -d dim -l off -c agent --require 1 -h'")
    assert_match "-d, --display MODE", help
    assert_match "-l, --lock MODE", help
    assert_match "-c, --checks MODE", help
    assert_match "all | agent | internet | none", help
    assert_match "--require N", help
    assert_match "SHORTCUTS", help
    assert_match "--hotspot MODE", help
    refute_match "--hotspot-after", help
    refute_match "--no-hotspot", help
    assert_path_exists libexec/"lib/nosleep-fallback.zsh"
    assert_path_exists libexec/"lib/nosleep_hotspot.py"
    system Formula["python@3.14"].opt_bin/"python3.14", libexec/"lib/nosleep_hotspot.py",
           "validate", "--ssid=Example Hotspot"
    assert_match "CHECK SETTINGS", help
    assert_match "CHECKS", shell_output("zsh -f -c 'source ~/.zshrc; nosleep -Lc=all -dMLh'")
    invalid = shell_output("zsh -f -c 'source ~/.zshrc; sudo() { echo unexpected-power; }; " \
                           "nosleep --require 2 --checks agent' 2>&1", 2)
    assert_match "--require exceeds the number of enabled checks", invalid
    refute_match "unexpected-power", invalid
    %w[all one].each do |value|
      invalid_requirement = shell_output("zsh -f -c 'source ~/.zshrc; sudo() { echo unexpected-power; }; " \
                                         "nosleep --require #{value}' 2>&1", 2)
      assert_match "--require takes a positive count", invalid_requirement
      refute_match "unexpected-power", invalid_requirement
    end
    invalid_hotspot = shell_output("zsh -f -c 'source ~/.zshrc; sudo() { echo unexpected-power; }; " \
                                   "nosleep --hotspot' 2>&1", 2)
    assert_match "--hotspot needs on or off", invalid_hotspot
    refute_match "unexpected-power", invalid_hotspot
    (testpath/".config/nosleep").mkpath
    (testpath/".config/nosleep/config.json").write('{"agent":false,"internet":true}')
    settings = shell_output("zsh -f -c 'source ~/.zshrc; nosleep config --show'")
    assert_match "Internet checks only", settings
    assert_match "Agents    Off", settings
    assert_match "Internet  On", settings
    assert_match "\nChecks\n", settings
    assert_match "\nCheck settings\n", settings
    assert_match "\nHotspot fallback\n", settings
    assert_match "Hotspot   off", settings
  end
end
