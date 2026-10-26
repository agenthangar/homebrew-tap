# AgentHangar Homebrew tap

This tap distributes [t](https://github.com/agenthangar/t), a toolkit for coding-agent sessions in isolated Git worktrees and tmux, and [dotfiles](https://github.com/agenthangar/dotfiles), shell configuration and utilities.

## t

```sh
brew install agenthangar/tap/t
t
```

The formula installs t's files under Homebrew without changing your shell or agent settings. Run `t` in a terminal for guided first-run setup: choose agents, review shell and agent integrations, discover existing repositories, and optionally clone selected GitHub organization repositories or add Tailscale hosts. Setup reviews changes before applying them. Open a new terminal afterward to load the shell integration.

You can also add this tap once with `brew tap agenthangar/tap`, then use `brew install t`. Rerun discovery with `t config onboard` when you add repositories or hosts. Noninteractive `t` prints help without changing settings.

To update, run `t system update` or `brew upgrade agenthangar/tap/t`. The formula is sourced from t's versioned GitHub release archive and its published SHA-256 digest.

## dotfiles

```sh
brew tap agenthangar/tap
brew install dots
dots
```

`dots` is an alias for the `dotfiles` formula. The package contains the complete
configuration, utilities, and templates; no Git checkout is required. The first
`dots` applies that package to your account. Later runs upgrade through Homebrew
and reapply the installed configuration. `dots --relink` reconciles it offline.
`dots install` reruns full account setup, including optional sudo trust.

Existing checkout users should run the Homebrew command explicitly once:

```sh
"$(brew --prefix agenthangar/tap/dotfiles)/bin/dots" install
source ~/.zshrc
```

Setup preserves private settings and existing repositories. It replaces the old
shell symlink with a real loader and uses Homebrew's stable opt path for runtime
files. `brew upgrade dots` updates the same runtime; `brew uninstall dots` removes
it while leaving private settings intact. `dotfiles-setup` aliases `dots install`.

Every runtime release needs a formula version/commit URL/SHA-256 update. The
formula must ship all runtime assets and dependencies. Tests install the real
payload in a sandbox account without cloning or fetching any repository.

## Updating the t formula

After a new `agenthangar/t` release has both `t.tar.gz` and `SHA256SUMS`, [Update t formula](.github/workflows/update-t-formula.yml) runs when the `agenthangar/t` release workflow dispatches an event after verifying or uploading both assets. It runs `scripts/bump.py` to verify the archive and digest, then opens a PR for a changed formula and enables squash auto-merge after formula CI passes. The workflow can also be run on demand from the Actions tab. It makes no change when the formula is current.

The workflow authenticates as a GitHub App installed only on this tap, with Contents and Pull requests write permissions. Its client ID is stored in the `T_FORMULA_APP_CLIENT_ID` repository variable; its private key is stored in the `T_FORMULA_APP_PRIVATE_KEY` repository secret. The workflow's own `GITHUB_TOKEN` has read-only access.

For a failed run or manual recovery, verify a specific release before opening a PR:

```sh
python3 scripts/bump.py --version v0.3.1 --dry-run
python3 scripts/bump.py --version v0.3.1
python3 -m unittest discover -s tests
git diff -- Formula/t.rb
```

The bump script checks the release and installer markers and changes only the formula URL and digest. Publish the release assets before updating the formula so Homebrew never points to missing files.
