# Developer Tools

Scripts that support software development and release workflows.

## Release Packaging

### `ez-release/ez_release.py`

Small Python release helper for small Python projects. It builds one PyInstaller
executable, stages release files, optionally signs the binary with GPG, writes
SHA256 checksums, and creates a zip archive for upload to GitHub Releases.

Detailed usage lives in [ez-release/README.md](ez-release/README.md).
