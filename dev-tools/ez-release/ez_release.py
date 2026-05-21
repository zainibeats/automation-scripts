#!/usr/bin/env python3
"""
Build a small Python project into a GitHub-ready release folder.

ez-release intentionally does only a few things:
  1. Build one executable with PyInstaller.
  2. Stage the executable with common project files.
  3. Optionally create GPG detached signatures.
  4. Write SHA256 checksums and create a zip archive.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import shutil
import subprocess
import sys
import zipfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover - Python < 3.11 fallback
    tomllib = None


DEFAULT_DOCS = ("README.md", "LICENSE", "LICENSE.md", "CHANGELOG.md")
DEFAULT_ENTRY_FILES = ("main.py", "app.py", "cli.py")


@dataclass
class DataFile:
    src: str
    dest: str


@dataclass
class ReleaseConfig:
    project_root: Path
    name: str | None = None
    entry: str | None = None
    version: str | None = None
    icon: str | None = None
    include: list[str] = field(default_factory=list)
    data: list[DataFile] = field(default_factory=list)
    hidden_imports: list[str] = field(default_factory=list)
    gpg_key: str | None = None
    release_dir: str = "release"
    dist_dir: str = "dist"
    build_dir: str = "build"


def main() -> int:
    args = parse_args()
    root = args.project_root.resolve()
    config = load_config(root, args.config)
    apply_cli_overrides(config, args)
    fill_defaults(config)
    validate_config(config)

    if args.clean:
        remove_path(root / config.dist_dir)
        remove_path(root / config.build_dir)
        remove_path(root / config.release_dir)

    exe_path = build_executable(config)
    staged_files = stage_release(config, exe_path)

    if config.gpg_key and not args.no_sign:
        staged_files.extend(sign_files(config, [exe_path_for_stage(config, exe_path)]))

    checksums_path = write_checksums(config, staged_files)
    staged_files.append(checksums_path)
    archive_path = create_archive(config)

    print()
    print("Release ready:")
    print(f"  Executable: {exe_path_for_stage(config, exe_path)}")
    print(f"  Checksums:  {checksums_path}")
    print(f"  Archive:    {archive_path}")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build and package a simple Python project release."
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path.cwd(),
        help="Project root to release. Defaults to the current directory.",
    )
    parser.add_argument(
        "--config",
        default="ez-release.toml",
        help="Optional config file relative to project root.",
    )
    parser.add_argument("--name", help="Application name used for the executable and zip.")
    parser.add_argument("--entry", help="Python entry file, such as main.py.")
    parser.add_argument("--version", help="Release version. Overrides detected version.")
    parser.add_argument("--icon", help="Optional icon file passed to PyInstaller.")
    parser.add_argument(
        "--include",
        action="append",
        default=[],
        help="Extra file or folder to include in the release folder. Repeatable.",
    )
    parser.add_argument(
        "--data",
        action="append",
        default=[],
        metavar="SRC:DEST",
        help="Extra PyInstaller data mapping. Repeatable.",
    )
    parser.add_argument(
        "--hidden-import",
        action="append",
        default=[],
        help="Hidden import passed to PyInstaller. Repeatable.",
    )
    parser.add_argument("--gpg-key", help="GPG key id used for detached signatures.")
    parser.add_argument("--no-sign", action="store_true", help="Skip signing.")
    parser.add_argument("--clean", action="store_true", help="Remove build outputs first.")
    return parser.parse_args()


def load_config(project_root: Path, config_name: str) -> ReleaseConfig:
    config = ReleaseConfig(project_root=project_root)
    config_path = project_root / config_name
    if not config_path.exists():
        return config

    if tomllib is None:
        fail("Reading TOML config requires Python 3.11 or newer.")

    with config_path.open("rb") as handle:
        raw = tomllib.load(handle)

    project = raw.get("project", {})
    release = raw.get("release", {})
    signing = raw.get("signing", {})

    config.name = project.get("name")
    config.entry = project.get("entry")
    config.version = project.get("version")
    config.icon = project.get("icon")
    config.include = list(project.get("include", []))
    config.hidden_imports = list(project.get("hidden_imports", []))
    config.data = parse_data_config(project.get("data", []))
    config.gpg_key = signing.get("gpg_key")
    config.release_dir = release.get("dir", config.release_dir)
    config.dist_dir = release.get("dist_dir", config.dist_dir)
    config.build_dir = release.get("build_dir", config.build_dir)
    return config


def parse_data_config(items: Any) -> list[DataFile]:
    data_files: list[DataFile] = []
    for item in items:
        if not isinstance(item, dict) or "src" not in item or "dest" not in item:
            fail("Each project.data item must contain src and dest.")
        data_files.append(DataFile(src=str(item["src"]), dest=str(item["dest"])))
    return data_files


def apply_cli_overrides(config: ReleaseConfig, args: argparse.Namespace) -> None:
    for attr in ("name", "entry", "version", "icon"):
        value = getattr(args, attr)
        if value:
            setattr(config, attr, value)

    if args.gpg_key:
        config.gpg_key = args.gpg_key

    config.include.extend(args.include)
    config.hidden_imports.extend(args.hidden_import)
    config.data.extend(parse_data_args(args.data))


def parse_data_args(items: list[str]) -> list[DataFile]:
    data_files: list[DataFile] = []
    for item in items:
        if ":" not in item:
            fail(f"Invalid --data value '{item}'. Use SRC:DEST.")
        src, dest = item.split(":", 1)
        data_files.append(DataFile(src=src, dest=dest))
    return data_files


def fill_defaults(config: ReleaseConfig) -> None:
    pyproject = read_pyproject(config.project_root)
    project_table = pyproject.get("project", {})

    if not config.name:
        config.name = project_table.get("name") or config.project_root.name

    if not config.version:
        config.version = project_table.get("version") or detect_version(config.project_root)

    if not config.entry:
        config.entry = detect_entry(config.project_root)

    if not config.include:
        config.include = [doc for doc in DEFAULT_DOCS if (config.project_root / doc).exists()]


def read_pyproject(project_root: Path) -> dict[str, Any]:
    path = project_root / "pyproject.toml"
    if not path.exists() or tomllib is None:
        return {}
    with path.open("rb") as handle:
        return tomllib.load(handle)


def detect_version(project_root: Path) -> str:
    version_files = [
        project_root / "version.txt",
        *project_root.glob("*/__init__.py"),
        project_root / "__init__.py",
    ]
    pattern = re.compile(r"__version__\s*=\s*['\"]([^'\"]+)['\"]")

    for path in version_files:
        if not path.exists() or not path.is_file():
            continue
        text = path.read_text(encoding="utf-8", errors="ignore").strip()
        if path.name == "version.txt" and text:
            return text.splitlines()[0].strip()
        match = pattern.search(text)
        if match:
            return match.group(1)

    return "0.0.0"


def detect_entry(project_root: Path) -> str | None:
    for name in DEFAULT_ENTRY_FILES:
        if (project_root / name).exists():
            return name
    return None


def validate_config(config: ReleaseConfig) -> None:
    assert config.name is not None
    assert config.version is not None

    if not config.entry:
        fail("No entry file found. Pass --entry main.py or set project.entry in ez-release.toml.")

    entry_path = config.project_root / config.entry
    if not entry_path.is_file():
        fail(f"Entry file not found: {entry_path}")

    if config.icon and not (config.project_root / config.icon).is_file():
        fail(f"Icon file not found: {config.project_root / config.icon}")

    for item in config.include:
        if not (config.project_root / item).exists():
            fail(f"Included path not found: {config.project_root / item}")

    for item in config.data:
        if not (config.project_root / item.src).exists():
            fail(f"Data path not found: {config.project_root / item.src}")


def build_executable(config: ReleaseConfig) -> Path:
    assert config.name is not None
    assert config.entry is not None

    command = [
        sys.executable,
        "-m",
        "PyInstaller",
        "--noconfirm",
        "--clean",
        "--onefile",
        "--name",
        config.name,
        "--distpath",
        str(config.project_root / config.dist_dir),
        "--workpath",
        str(config.project_root / config.build_dir / "ez-release"),
        "--specpath",
        str(config.project_root / config.build_dir / "ez-release"),
    ]

    if config.icon:
        command.extend(["--icon", str(config.project_root / config.icon)])

    for item in config.hidden_imports:
        command.extend(["--hidden-import", item])

    for item in config.data:
        mapping = f"{config.project_root / item.src}{os.pathsep}{item.dest}"
        command.extend(["--add-data", mapping])

    command.append(str(config.project_root / config.entry))
    run(command, config.project_root)

    executable = config.project_root / config.dist_dir / executable_name(config)
    if not executable.exists():
        fail(f"PyInstaller finished, but the executable was not found: {executable}")
    return executable


def stage_release(config: ReleaseConfig, exe_path: Path) -> list[Path]:
    assert config.name is not None
    assert config.version is not None

    release_root = config.project_root / config.release_dir
    stage_dir = stage_path(config)
    remove_path(stage_dir)
    stage_dir.mkdir(parents=True, exist_ok=True)

    staged_files: list[Path] = []
    target_exe = exe_path_for_stage(config, exe_path)
    shutil.copy2(exe_path, target_exe)
    staged_files.append(target_exe)

    for item in config.include:
        source = config.project_root / item
        target = stage_dir / source.name
        copy_path(source, target)
        staged_files.extend(path_files(target))

    release_root.mkdir(parents=True, exist_ok=True)
    return staged_files


def sign_files(config: ReleaseConfig, paths: list[Path]) -> list[Path]:
    assert config.gpg_key is not None
    signatures: list[Path] = []
    for path in paths:
        run(
            [
                "gpg",
                "--batch",
                "--yes",
                "--default-key",
                config.gpg_key,
                "--detach-sign",
                str(path),
            ],
            config.project_root,
        )
        signatures.append(path.with_suffix(path.suffix + ".sig"))
    return signatures


def write_checksums(config: ReleaseConfig, files: list[Path]) -> Path:
    checksums_path = stage_path(config) / "SHA256SUMS.txt"
    with checksums_path.open("w", encoding="utf-8") as handle:
        for path in sorted(files):
            if not path.is_file():
                continue
            digest = sha256(path)
            relative = path.relative_to(stage_path(config))
            handle.write(f"{digest}  {relative.as_posix()}\n")
    return checksums_path


def create_archive(config: ReleaseConfig) -> Path:
    assert config.name is not None
    assert config.version is not None

    archive_path = config.project_root / config.release_dir / f"{config.name}-{config.version}.zip"
    remove_path(archive_path)

    base = stage_path(config)
    with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in path_files(base):
            archive.write(path, path.relative_to(base.parent))
    return archive_path


def executable_name(config: ReleaseConfig) -> str:
    assert config.name is not None
    suffix = ".exe" if sys.platform.startswith("win") else ""
    return f"{config.name}{suffix}"


def stage_path(config: ReleaseConfig) -> Path:
    assert config.name is not None
    assert config.version is not None
    return config.project_root / config.release_dir / f"{config.name}-{config.version}"


def exe_path_for_stage(config: ReleaseConfig, exe_path: Path) -> Path:
    return stage_path(config) / exe_path.name


def copy_path(source: Path, target: Path) -> None:
    if source.is_dir():
        if target.exists():
            shutil.rmtree(target)
        shutil.copytree(source, target)
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)


def path_files(path: Path) -> list[Path]:
    if path.is_file():
        return [path]
    return [item for item in path.rglob("*") if item.is_file()]


def remove_path(path: Path) -> None:
    if path.is_dir():
        shutil.rmtree(path)
    elif path.exists():
        path.unlink()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def run(command: list[str], cwd: Path) -> None:
    print("+ " + " ".join(quote(part) for part in command))
    try:
        subprocess.run(command, cwd=cwd, check=True)
    except FileNotFoundError:
        fail(f"Command not found: {command[0]}")
    except subprocess.CalledProcessError as error:
        fail(f"Command failed with exit code {error.returncode}: {command[0]}")


def quote(value: str) -> str:
    if re.search(r"\s", value):
        return f'"{value}"'
    return value


def fail(message: str) -> None:
    raise SystemExit(f"ez-release: {message}")


if __name__ == "__main__":
    raise SystemExit(main())
