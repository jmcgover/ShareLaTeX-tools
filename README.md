# ShareLaTeX Tools

- [install poetry ](https://python-poetry.org/docs/#installation)
- `poetry install` from repo root
- Set the following in a `.env` file:
    - `SAVE_DIR`: Path to an empty directory
    - `GIT_TOKEN`: Overleaf-provided git authorization token
- `just run-ls`
- `just run-list-projects`
- `just run-list-project-ids`
- `just run-clone` (clones projects down)
- `just run-commit-per-project-meta` (adds metadata to each repo)

TODO:
- [ ] `just run-merge-to-one` (merges all to one repo)

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
