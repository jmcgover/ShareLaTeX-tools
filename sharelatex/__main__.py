"""Executed when invoked directly on the CLI with the -m flag."""

import json

import click
import pyoverleaf


@click.group()
def main() -> None:
    """Define the main arguments group."""
    pass


def get_projects() -> list[pyoverleaf.Project]:
    """Sign into Overleaf and return the projects."""
    api = pyoverleaf.Api()
    api.login_from_browser()
    return api.get_projects()


@main.command("list-project-ids", help="List projects IDs only.")
def list_project_ids() -> None:
    """List projects and their details."""
    projects: list[pyoverleaf.Project] = get_projects()
    print(" ".join(f"{project.id}" for project in projects))
    return


@main.command("list-projects", help="List projects and their details.")
@click.option("--json", "to_json", is_flag=True, help="JSON output")
def list_projects(to_json: bool) -> None:
    """List projects and their details."""
    projects: list[pyoverleaf.Project] = get_projects()
    if to_json:
        print(json.dumps([p.to_dict() for p in projects], indent=2, sort_keys=True))
        return
    print("\n".join(f"{project.id} {project.name}" for project in projects))
    return


@main.command("ls", help="List projects or files in a project")
@click.argument("path", type=str, default=".")
def list_projects_and_files(path: str) -> None:
    """List projects (and its files) with ls-like semantics."""
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
