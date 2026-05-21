# ez-release

`ez-release` is a small Python release helper for small Python projects.

It builds one PyInstaller executable, stages release files, optionally signs the
binary with GPG, writes SHA256 checksums, and creates a zip archive that can be
uploaded to GitHub Releases.

It does not create installers, publish to GitHub, manage changelogs, bump
versions, build Rust code, or replace your package manager.

## Requirements

- Python 3.11 or newer
- PyInstaller installed in the project environment
- GPG installed and configured, only if signing is enabled

Install PyInstaller in the project you are releasing:

```bash
python -m pip install pyinstaller
```

## Quick Use

From the Python project you want to release:

```bash
python /path/to/automation-scripts/dev-tools/ez-release/ez_release.py --entry main.py --name my-app --version 1.0.0 --clean
```

This creates:

```text
release/
  my-app-1.0.0/
    my-app
    README.md
    LICENSE
    SHA256SUMS.txt
  my-app-1.0.0.zip
```

On Windows, the executable will be named `my-app.exe`.

## Optional Config

For repeated use, add `ez-release.toml` to the project you are releasing:

```toml
[project]
name = "my-app"
entry = "main.py"
version = "1.0.0"
icon = "assets/app.ico"
include = ["README.md", "LICENSE", "CHANGELOG.md"]
hidden_imports = []
data = [
  { src = "assets", dest = "assets" }
]

[signing]
gpg_key = ""

[release]
dir = "release"
dist_dir = "dist"
build_dir = "build"
```

Then run:

```bash
python /path/to/automation-scripts/dev-tools/ez-release/ez_release.py --clean
```

Command-line options override the config.

## Common Commands

Build using detected name and version from `pyproject.toml`:

```bash
python /path/to/automation-scripts/dev-tools/ez-release/ez_release.py --entry main.py
```

Add PyInstaller data files:

```bash
python /path/to/automation-scripts/dev-tools/ez-release/ez_release.py --entry main.py --data assets:assets
```

Sign the staged executable with GPG:

```bash
python /path/to/automation-scripts/dev-tools/ez-release/ez_release.py --entry main.py --gpg-key YOUR_KEY_ID
```

Skip signing even when `ez-release.toml` has a signing key:

```bash
python /path/to/automation-scripts/dev-tools/ez-release/ez_release.py --no-sign
```

## Version Detection

If `--version` and `project.version` are not set, `ez-release` tries:

1. `pyproject.toml` `[project].version`
2. `version.txt`
3. `__version__ = "..."` in a top-level package `__init__.py`
4. `0.0.0`

## Notes

Keep project-specific build logic in the project itself. If a project needs a
custom pre-build step, run that step before `ez-release`.
