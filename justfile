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

    if [[ ! -d "${SAVE_DIR}" ]]; then
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

    if [[ ! -d "${SAVE_DIR}" ]]; then
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

    if [[ ! -d "${SAVE_DIR}" ]]; then
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

# merge the repos into a single repo
run-merge-repos destination-dir:
    #! /usr/bin/env bash
    set -o errexit
    set -o nounset

    if [[ ! -d "${SAVE_DIR}" ]]; then
        echo "SAVE_DIR='${SAVE_DIR}' must be a directory"
        exit 22
    fi

    if [[ -e "{{ destination-dir }}" ]]; then
        echo destination-dir='{{ destination-dir }}' cannot already exist
        exit 22
    fi

    SRC_DIR="${SAVE_DIR}"
    DST_DIR="{{ destination-dir }}"

    set -o xtrace
    mkdir -vp "${DST_DIR}"
    cd "${DST_DIR}"
    cp -v "${SRC_DIR}/projects.json" ./
    git init
    git add ./
    git commit -m "add ShareLaTeX projects metadata"
    set +o xtrace

    # Time (merge): ~4min for 153 projects totaling 800MiB
    echo "=====START====="
    for id_dir in $(ls -d "${SRC_DIR}"/*/); do
        set -o xtrace

        # Grab this project's files
        id=$(basename "${id_dir}")
        echo "${id}: id_dir='${id_dir}'"
        git remote add --fetch "${id}" "${id_dir}"
        git branch

        # Checkout the ShareLaTeX default branch (master for all of my projects)
        git checkout "${id}/master"  # results in headless mode

        # Move all files to a subdir for just this project's files
        mkdir -v "${id}"
        set +o xtrace
        for file in {./*,./.*}; do  # globbing handles spaces in filenames
            echo "=====${file}"
            if [[ "${file}" != "./${id}" && "${file}" != "./.git" && "${file}" != "./.DS_Store" ]]; then
                mv -v "${file}" "./${id}/${file}"
            else
                echo SKIPPING "${file}"
            fi
        done

        set -o xtrace

        # Commit the move to a new branch
        git add .
        git commit -m "move files for ${id} into their own folder"
        git switch -C "${id}/main"  # create new branch to retain commits (main removes an ambiguity git complains about )

        # Merge the branch into the 
        git checkout main
        # Merge:
        # - main will only have merge commits
        git merge "${id}/main" --allow-unrelated-histories --no-edit
        set +o xtrace
    done
    echo "=====COMPLETE====="

# rebase the repos into a single repo
run-rebase-repos destination-dir:
    #! /usr/bin/env bash
    set -o errexit
    set -o nounset

    if [[ ! -d "${SAVE_DIR}" ]]; then
        echo "SAVE_DIR='${SAVE_DIR}' must be a directory"
        exit 22
    fi

    if [[ -e "{{ destination-dir }}" ]]; then
        echo destination-dir='{{ destination-dir }}' cannot already exist
        exit 22
    fi

    SRC_DIR="${SAVE_DIR}"
    DST_DIR="{{ destination-dir }}"

    set -o xtrace
    mkdir -vp "${DST_DIR}"
    cd "${DST_DIR}"
    cp -v "${SRC_DIR}/projects.json" ./
    git init
    git add ./
    git commit -m "add ShareLaTeX projects metadata"
    set +o xtrace

    # Time (rebase): ??min for 153 projects totaling 800MiB
    echo "=====START====="
    for id_dir in $(ls -d "${SRC_DIR}"/*/); do
        set -o xtrace

        # Grab this project's files
        id=$(basename "${id_dir}")
        echo "${id}: id_dir='${id_dir}'"
        git remote add --fetch "${id}" "${id_dir}"
        git branch

        # Checkout the ShareLaTeX default branch (master for all of my projects)
        git checkout "${id}/master"  # results in headless mode

        # Move all files to a subdir for just this project's files
        mkdir -v "${id}"
        set +o xtrace
        for file in {./*,./.*}; do  # globbing handles spaces in filenames
            echo "=====${file}"
            if [[ "${file}" != "./${id}" && "${file}" != "./.git" && "${file}" != "./.DS_Store" ]]; then
                mv -v "${file}" "./${id}/${file}"
            else
                echo SKIPPING "${file}"
            fi
        done

        set -o xtrace

        # Commit the move to a new branch
        git add .
        git commit -m "move files for ${id} into their own folder"
        git switch -C "${id}/main"  # create new branch to retain commits (main removes an ambiguity git complains about )

        # Rebase the branch into the 
        git checkout main
        # Rebase:
        # - main will have the commits interleaved
        # - likely requires resolving conflicts
        git rebase "${id}/main" --strategy ort --strategy-option=ours --rerere-autoupdate --committer-date-is-author-date
        set +o xtrace
    done
    echo "=====COMPLETE====="

# continue rebasing the repos after resolving conflicts and checking out main
run-rebase-repos-continue destination-dir:
    #! /usr/bin/env bash
    set -o errexit
    set -o nounset

    if [[ ! -d "${SAVE_DIR}" ]]; then
        echo "SAVE_DIR='${SAVE_DIR}' must be a directory"
        exit 22
    fi

    if [[ ! -d "{{ destination-dir }}" ]]; then
        echo destination-dir='{{ destination-dir }}' must be a directory
        exit 22
    fi

    SRC_DIR="${SAVE_DIR}"
    DST_DIR="{{ destination-dir }}"

    remaining_ids=$(comm -2 -3 <(for i in $(ls -d "${SRC_DIR}"/*/); do echo $(basename $i); done | sort) <(for i in $(ls -d "${DST_DIR}"/*/); do echo $(basename $i); done | sort) | tr '\n' ' ' | awk '{$1=$1;print}')
    echo "remaining_ids: ${remaining_ids}"

    set -o xtrace
    cd "${DST_DIR}"
    set +o xtrace

    echo "=====START====="
    for id in ${remaining_ids}; do
        set -o xtrace

        id_dir=$(ls -d "${SRC_DIR}"/${id}/)
        if [[ ! -d "${id_dir}" ]]; then
            echo "id_dir='${id_dir}' must be a directory"
            exit 22
        fi

        # Grab this project's files
        id=$(basename "${id_dir}")
        echo "${id}: id_dir='${id_dir}'"
        git remote add --fetch "${id}" "${id_dir}"
        git branch

        # Checkout the ShareLaTeX default branch (master for all of my projects)
        git checkout "${id}/master"  # results in headless mode

        # Move all files to a subdir for just this project's files
        mkdir -v "${id}"
        set +o xtrace
        for file in {./*,./.*}; do  # globbing handles spaces in filenames
            echo "=====${file}"
            if [[ "${file}" != "./${id}" && "${file}" != "./.git" && "${file}" != "./.DS_Store" ]]; then
                mv -v "${file}" "./${id}/${file}"
            else
                echo SKIPPING "${file}"
            fi
        done

        set -o xtrace

        # Commit the move to a new branch
        git add .
        git commit -m "move files for ${id} into their own folder"
        git switch -C "${id}/main"  # create new branch to retain commits (main removes an ambiguity git complains about )

        # Rebase the branch into the 
        git checkout main
        # Rebase:
        # - If used on all, then main will have the commits interleaved
        # - There may be issues resolving some commits, possibly with cloned projects or very similar looking projects.
        git rebase "${id}/main" --strategy ort --strategy-option=ours --rerere-autoupdate --committer-date-is-author-date
        set +o xtrace
    done
    echo "=====COMPLETE====="

# do ALL the things
run-all: run-clone run-commit-per-project-meta run-git-status (run-merge-repos "${HOME}/Downloads/sharelatex-original-$(date +'%Y-%m-%dT%H:%M:%S%Z' | tr -d ':')")
