# AgentHangar Homebrew tap

This tap distributes [t](https://github.com/agenthangar/t), a toolkit for coding-agent sessions in isolated Git worktrees and tmux.

```sh
brew install agenthangar/tap/t
$(brew --prefix agenthangar/tap/t)/bin/t integrate
```

The formula installs t's files under Homebrew without changing your shell or agent settings. `t integrate` explicitly links the command and prompt helpers into your home directory; its links use Homebrew's stable `opt` path so a routine `brew upgrade` does not leave them pointing at an old Cellar version. Follow the shell snippet printed by `t integrate` to load the zsh plugin.

To update, run `t update` or `brew upgrade agenthangar/tap/t`. The formula is sourced from t's versioned GitHub release archive and its published SHA-256 digest.

## Updating the formula

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
