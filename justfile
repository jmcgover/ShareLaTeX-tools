# just: a handy way to save and run project-specific commands.
#
# dotenv-load: load a .env file, if present
# positional-arguments: pass recipe arguments as positional arguments to commands
#
# To use dmypy for the types recipe, add this to your .bashrc:
#   export MYPY_CMD='dmypy run --'

set dotenv-load := true
set positional-arguments := true

[private]
_mypycmd := env("MYPY_CMD", "mypy")

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

# run help
run-help:
    poetry run python -m sharelatex --help

# run with 'ls'
run-ls:
    poetry run python -m sharelatex ls

# obtain just project metadata, output josn
run-list:
    poetry run python -m sharelatex list-projects --json

# obtain ALL metadata
run-list-full:
    poetry run python -m sharelatex list-projects --full

# list all project IDs in a way that's bash-iterable
run-list-ids:
    poetry run python -m sharelatex list-project-ids

# extract individual project metadata into respective folder
run-extract-project-metadata:
    poetry run python -m sharelatex extract-project-metadata "${SAVE_DIR}"

# clone the projects locally
run-clone:
    #! /usr/bin/env bash
    set -o errexit
    set -o nounset

    if [[ ! -d ${SAVE_DIR} ]]; then
        echo "SAVE_DIR='${SAVE_DIR}' must be a directory"
        exit 22
    fi

    set -o xtrace
    # Time: 1min for 153 projects
    poetry run python -m sharelatex list-projects --json --full> "${SAVE_DIR}/projects.json"
    set +o xtrace

    # Time: 13min for 153 projects totaling 800MiB
    echo "=====START====="
    for id in $(poetry run python -m sharelatex list-project-ids); do
        echo "=====${id}"
        echo ${GIT_TOKEN} | git clone --progress --verbose https://git@git.overleaf.com/${id} "${SAVE_DIR}/${id}"
    done
    echo "=====COMPLETE====="

# extract individual project metadata into respective folder and commit
run-commit-per-project-meta:
    #! /usr/bin/env bash
    set -o errexit
    set -o nounset

    if [[ ! -d ${SAVE_DIR} ]]; then
        echo "SAVE_DIR='${SAVE_DIR}' must be a directory"
        exit 22
    fi

    set -o xtrace
    # Time: 1sec for 153 projects
    poetry run python -m sharelatex extract-project-metadata "${SAVE_DIR}"
    set +o xtrace

    echo "=====START====="
    for id_dir in $(ls -d "${SAVE_DIR}"/*/); do
        echo "=====${id_dir}"
        set -o xtrace
        cd "${id_dir}"
        git status
        git add project.json
        git commit -m "add project meta for project ID $(basename ${id_dir})"
        cd -
        set +o xtrace
    done
    echo "=====COMPLETE====="

# git status on each of the project directories
run-git-status:
    #! /usr/bin/env bash
    set -o errexit
    set -o nounset

    if [[ ! -d ${SAVE_DIR} ]]; then
        echo "SAVE_DIR='${SAVE_DIR}' must be a directory"
        exit 22
    fi

    echo "=====START====="
    for id_dir in $(ls -d "${SAVE_DIR}"/*/); do
        echo "=====${id_dir}"
        set -o xtrace
        cd "${id_dir}"
        git status
        cd -
        set +o xtrace
    done
    echo "=====COMPLETE====="
