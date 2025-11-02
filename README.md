# ShareLaTeX Tools

- [install poetry ](https://python-poetry.org/docs/#installation)
- `poetry install` from repo root, then [activate the environment](https://python-poetry.org/docs/managing-environments/#activating-the-environment):
  - [`eval $(poetry env activate)`](http://python-poetry.org/docs/managing-environments/#bash-csh-zsh)
  - [`poetry shell`](https://github.com/python-poetry/poetry-plugin-shell?tab=readme-ov-file#installation)
- Set the following in a `.env` file:
    - `SAVE_DIR`: Path to an empty directory
    - `GIT_TOKEN`: Overleaf-provided git authorization token
- Log into ShareLaTeX / Overleaf on Google Chrome
- Sanity check that things are working:
  - `just run-ls`
  - `just run-list-projects`
  - `just run-list-project-ids`
- Do the thing(s):
  - `just run-clone` (clones projects down)
  - `just run-commit-per-project-meta` (adds full metadata to each repo)
  - `just run-merge-repos ${HOME}/Downloads/sharelatex-merge-$(date +'%Y-%m-%dT%H:%M:%S%Z' | tr -d ':')` (merges all to one repo)
- If you're feeling bold, there's one recipe that runs them all:
  - `just run-all`
- If you know your way around rebasing, use these:
  - `just run-rebase-repos ${HOME}/Downloads/sharelatex-rebase-$(date +'%Y-%m-%dT%H:%M:%S%Z' | tr -d ':')` (rebases all to one repo)
  - When you inevitably hit a conflict:
    - Resolve the conflict
    - `get rebase --continue`
    - `get checkout main` (you should already be on it)
    - `just run-rebase-repos-continue <rebase-dir>`
- Once you've set up your remote repo (e.g. on GitHub):
  1. `cd` into the local repo you created in `just run-merge-repos` of `just run-rebase-repos`
  1. Add the remote as `origin`:
     - `git remote add origin git@github.com:<GITHUB_USER/REPO_NAME>.git`
  1. `git push origin --mirror` to push all the branches to the remote


## References

- [jmcgover/pyoverleaf](https://github.com/jmcgover/pyoverleaf): A fork of [jkulhanek/pyoverleaf](https://github.com/jkulhanek/pyoverleaf) to fix:
    - [jkulhanek/pyoverleaf | Issues #9 | Tags don't have color attribute](https://github.com/jkulhanek/pyoverleaf/issues/9)
    - JSON serialization
    - Make type annotations work (you literally just need to a `py.typed` file

## Poetry

Initialized with:
```bash
poetry init --name="sharelatex-tools" --description="Tools to ShareLaTeX projects into git repos." --author='Jeffrey McGovern <jeff@jdmcg.org>' --python='>=3.11,<4.0' --no-interaction
```

Dependencies from my own fork of the package:
```bash
poetry add git+ssh://git@github.com:jmcgover/pyoverleaf.git
```

Dependencies for `dev`:
```bash
poetry add rust-just python-dotenv ruff mypy pylsp-mypy pyclean bandit --group=dev
```
