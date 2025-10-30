# ShareLaTeX Tools

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
