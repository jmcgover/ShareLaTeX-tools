set dotenv-load := true
set positional-arguments := true

[private]
_mypycmd := env("MYPY_CMD","mypy") # MYPY_CMD='dmypy run --'

# list all recipes
default:
    just --list

# lock dependencies to file
lock:
    poetry lock

# sync venv to exactly what's in lock file
sync:
    poetry sync

# typecheck python
types:
    poetry run {{ _mypycmd }} .

# lint python
lint:
    poetry run ruff check .

# lint python security-wise
lint-security:
    poetry run bandit --severity-level all -r src/

# check-only validation for crucial stuff
validate:
    poetry run ruff check . --select I # isort (check only)
    poetry run ruff format --check # 'compatible' with black (check only)
    poetry run ruff check .
    poetry run mypy .
    poetry run bandit --severity-level medium -r src/

# format python files
format:
    poetry run ruff check . --select I --fix # isort
    poetry run ruff format # 'compatible' with black

# fix python import statements
fix-imports:
    poetry run ruff check . --select UP035 --fix # deprecated-import
    poetry run ruff check . --select F401 --fix # unused-import
    poetry run ruff check . --select I --fix # isort

# clean the repo of any extraneous files
clean: format lint
    poetry run pyclean . --debris=all --verbose
    poetry run dmypy stop # delete .dmypy.json

# format justfile using just's fmt feature
format-justfile:
    just --fmt --unstable
