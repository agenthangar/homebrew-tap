# AgentHangar Homebrew tap

This tap distributes [t](https://github.com/agenthangar/t), a toolkit for coding-agent sessions in isolated Git worktrees and tmux.

```sh
brew install agenthangar/tap/t
$(brew --prefix agenthangar/tap/t)/bin/t integrate
```

The formula installs t's files under Homebrew without changing your shell or agent settings. `t integrate` explicitly links the command and prompt helpers into your home directory; its links use Homebrew's stable `opt` path so a routine `brew upgrade` does not leave them pointing at an old Cellar version. Follow the shell snippet printed by `t integrate` to load the zsh plugin.

To update, run `t update` or `brew upgrade agenthangar/tap/t`. The formula is sourced from t's versioned GitHub release archive and its published SHA-256 digest.

## Updating the formula

After a new `agenthangar/t` release has been published with both `t.tar.gz` and
`SHA256SUMS`, a maintainer updates the tap with:

```sh
python3 scripts/bump.py --version v0.3.0 --dry-run
python3 scripts/bump.py --version v0.3.0
python3 -m unittest discover -s tests
git diff -- Formula/t.rb
```

Omit `--version` to use the latest published release. The bump command downloads
both assets, verifies the archive against its SHA-256 digest, checks the release
and installer markers inside it, and changes only the formula's release URL and
digest. Review the diff, run the formula CI, then open a normal PR to `main` and
enable squash auto-merge. Publish the `t` release before merging the tap PR so
Homebrew never points to missing assets.
