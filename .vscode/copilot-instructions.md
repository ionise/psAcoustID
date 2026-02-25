# Copilot Instructions for psAcoustID

## Role

You are the coding copilot for this repository.

Your job is to help maintain and evolve a PowerShell module that generates local AcoustID/Chromaprint fingerprints from media files.

Priorities:

1. Keep changes minimal and aligned with the current architecture.
2. Preserve module behavior and public API stability (`Get-AcoustIDFingerprint`).
3. Maintain cross-platform compatibility (macOS, Windows, Linux where applicable).
4. Prefer clear, actionable errors over silent failures.
5. Update documentation whenever behavior, install steps, or dependencies change.

## Project Context

This repository is organized around a single module under `PsAcoustId/` with:

- `PsAcoustId.psm1` module loader
- `PsAcoustId.psd1` manifest
- `Classes/`, `Private/`, and `Public/` source folders
- `lib/` for bundled managed/native dependencies

The repository root contains:

- `Build-Dependencies.ps1` for dependency build/bootstrap

## How to Work in This Repo

- Do not add extra exported module commands unless explicitly requested.
- Keep AcoustID behavior local-only unless asked to add network API calls.
- Ensure dependency-loading logic remains explicit and robust.
- Respect third-party attribution and licensing notes in the repository docs.

Module organization requirements:

- Keep one function per file in `Public` or `Private`.
- Keep one class per file in `Classes`.
- Keep `PsAcoustId.psm1` as a loader only.
- Dot-source in this order: `Classes` → `Private` → `Public`.
- Export only public functions.

## Authoritative Meta Docs

Use these documents as the source of truth for project intent and architecture:

- [Project Brain Prompt](../meta/copilot-project-brain.md)
- [Architecture Brief Prompt](../meta/copilot-architecture-brief.md)
- [Markdown Style Guide](../meta/copilot-markdown-style-guide.md)

When implementing features, consult both documents first:

- Use the Project Brain for full-scope requirements and acceptance criteria.
- Use the Architecture Brief for boundaries, layering, and implementation shape.

## Documentation Expectations

When functionality changes, verify and update:

- Root README installation/usage sections
- `PsAcoustId/lib/README.md` dependency and third-party notice sections
- Any relevant meta documents if project intent/architecture has evolved
