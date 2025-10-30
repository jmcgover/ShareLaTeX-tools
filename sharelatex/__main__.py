"""Executed when invoked directly on the CLI with the -m flag."""

from dataclasses import dataclass
import difflib
import json
import pathlib
import sys
from typing import Self

import click
from dataclasses_json import DataClassJsonMixin
import pyoverleaf


@dataclass
class ProjectMeta(DataClassJsonMixin):
    """Node for capturing full project (including dir/file) metadata."""

    project: pyoverleaf.Project
    root: pyoverleaf.ProjectFolder

    @classmethod
    def from_project(
        cls,
        api: pyoverleaf.Api,
        project: pyoverleaf.Project,
    ) -> Self:
        """Use a logged in API to obtain the all dir/file metadata."""
        return cls(
            project=project,
            root=api.project_get_files(
                project_id=project.id,
            ),
        )


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
    projects: list[ProjectMeta]
    # Read Prefetched Projects
    prefetched_projects: pathlib.Path = work_dir.joinpath("projects.json")
    with prefetched_projects.open("r") as json_file:
        _projects = json.load(json_file)
        if not isinstance(_projects, list):
            raise ValueError(f"Expected {prefetched_projects=!s} to be a list, but found {type(_projects)}")
        projects = [ProjectMeta.from_dict(p) for p in _projects]

    # Ensure that IDs are accounted for on both sides
    dirs = [i for i in work_dir.iterdir() if i.is_dir()]
    ids_expected: list[str] = sorted([p.project.id for p in projects])
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
@click.option("--full", "full", is_flag=True, help="include all dir/file metadata")
def list_projects(to_json: bool, full: bool) -> None:
    """List projects and their details."""
    # Obtain each Project from logged in account
    api = pyoverleaf.Api()
    api.login_from_browser()
    projects: list[pyoverleaf.Project] = api.get_projects()
    if not full:
        if to_json:
            print(json.dumps([p.to_dict() for p in projects], indent=2, sort_keys=True))
            return
        print("\n".join(f"{project.id} {project.name}" for project in projects))
        return

    # Obtain all the metadata for each Project
    project_metas: list[ProjectMeta] = [ProjectMeta.from_project(api=api, project=p) for p in projects]

    # Output (always to JSON for full output)
    print(json.dumps([p.to_dict() for p in project_metas], indent=2, sort_keys=True))
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
