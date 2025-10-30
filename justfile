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

# run with 'ls'
run-ls:
    poetry run python -m sharelatex ls

# run with 'list-projects'
run-list:
    poetry run python -m sharelatex list-projects --json

# run with 'list-project-ids'
run-list-ids:
    poetry run python -m sharelatex list-project-ids

# clone the projects locally
run-clone:
    #! /usr/bin/env bash
    set -o errexit
    set -o nounset

    if [[ ! -d ${WORK_DIR} ]]; then
        echo "WORK_DIR='${WORK_DIR}' must be a directory"
        exit 22
    fi

    set -o xtrace
    poetry run python -m sharelatex list-projects --json > "${WORK_DIR}/projects.json"
    set +o xtrace
    echo "=====START====="
    for id in $(poetry run python -m sharelatex list-project-ids); do
        echo "=====${id}"
        echo ${GIT_TOKEN} | git clone --progress --verbose https://git@git.overleaf.com/${id} "${WORK_DIR}/${id}"
    done
    echo "=====COMPLETE====="
