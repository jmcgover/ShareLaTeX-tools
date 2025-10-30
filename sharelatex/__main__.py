"""Executed when invoked directly on the CLI with the -m flag."""

import difflib
import json
import pathlib
import sys

import click
import pyoverleaf


@click.group()
def main() -> None:
    """Define the main arguments group."""
    pass


def get_projects() -> list[pyoverleaf.Project]:
    """Sign into Overleaf via pyoverleaf and return account projects."""
    api = pyoverleaf.Api()
    api.login_from_browser()
    return api.get_projects()


@main.command("extract-project-metadata")
@click.argument(
    "work_dir",
    type=click.Path(
        exists=True,
        dir_okay=True,
        file_okay=False,
        writable=True,
        readable=True,
        executable=False,
        resolve_path=True,  # resolve symlinks (not ~)
        path_type=pathlib.Path,
    ),
)
def extract_project_metadata(work_dir: pathlib.Path) -> None:
    """Extract project metadata to specific project folders."""
    projects: list[pyoverleaf.Project]
    # Read Prefetched Projects
    prefetched_projects: pathlib.Path = work_dir.joinpath("projects.json")
    with prefetched_projects.open("r") as json_file:
        _projects = json.load(json_file)
        if not isinstance(_projects, list):
            raise ValueError(f"Expected {prefetched_projects=!s} to be a list, but found {type(_projects)}")
        projects = [pyoverleaf.Project.from_dict(p) for p in _projects]

    # Ensure that IDs are accounted for on both sides
    dirs = [i for i in work_dir.iterdir() if i.is_dir()]
    ids_expected: list[str] = sorted([p.id for p in projects])
    ids_dirnames: list[str] = sorted([d.name for d in dirs])
    if ids_dirnames != ids_expected:
        # Unified diffs can pipe into something like Delta for pretty output.
        # No, I don't know why I need to do all this.
        sys.stdout.writelines(
            difflib.unified_diff(
                fromfile=str(prefetched_projects),
                a=("\n".join(ids_expected) + "\n").splitlines(keepends=True),
                tofile=str(work_dir),
                b=("\n".join(ids_dirnames) + "\n").splitlines(keepends=True),
                lineterm="\n",
                n=3,
            )
        )
        raise ValueError("Mismatched project IDs and directories with project files.")
    return


@main.command("list-project-ids")
def list_project_ids() -> None:
    """List projects IDs only."""
    projects: list[pyoverleaf.Project] = get_projects()
    print(" ".join(f"{project.id}" for project in projects))
    return


@main.command("list-projects")
@click.option("--json", "to_json", is_flag=True, help="JSON output")
def list_projects(to_json: bool) -> None:
    """List projects and their details."""
    projects: list[pyoverleaf.Project] = get_projects()
    if to_json:
        print(json.dumps([p.to_dict() for p in projects], indent=2, sort_keys=True))
        return
    print("\n".join(f"{project.id} {project.name}" for project in projects))
    return


@main.command("ls")
@click.argument("path", type=str, default=".")
def list_projects_and_files(path: str) -> None:
    """List projects (or its files) with ls-like semantics."""
    api = pyoverleaf.Api()
    api.login_from_browser()
    projects: list[pyoverleaf.Project] = api.get_projects()
    if not path or path in {".", "/"}:
        print("\n".join(project.name for project in projects))
    else:
        path = path.removeprefix("/")
        project: str
        _path: list[str]
        project, *_path = path.split("/", 1)
        if not _path:
            path = ""
        else:
            path = _path[0]
        project_id = None
        for p in projects:
            if p.name == project:
                project_id = p.id
                break
        if project_id is None:
            raise FileNotFoundError(f"Project '{project}' not found.")
        io = pyoverleaf.ProjectIO(api, project_id)
        files = io.listdir(path)
        print("\n".join(files))


if __name__ == "__main__":
    main()
