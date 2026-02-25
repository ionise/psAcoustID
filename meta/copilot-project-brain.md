# Copilot Project Brain Prompt

Use the following prompt when asking an AI coding agent to recreate this project from scratch.

---

You are building a PowerShell 7+ module named **PsAcoustId** that generates AcoustID/Chromaprint fingerprints for local audio files.

## Objective

Create a repository with:

- A distributable PowerShell module
- A dependency build/bootstrap script
- Clear README docs for install, usage, and troubleshooting
- Third-party attribution notes for bundled binaries

## Required Repository Structure

Create exactly this structure:

```text
LICENSE
README.md
Build-Dependencies.ps1
PsAcoustId/
  AccoustIDAPIKey
  PsAcoustId.psd1
  PsAcoustId.psm1
  Classes/
    {ClassName}.ps1
  Public/
    Get-AcoustIDFingerprint.ps1
  Private/
    *.ps1
  lib/
    README.md
```

## Functional Requirements

1. Export exactly one public function:

   - `Get-AcoustIDFingerprint`

1. `Get-AcoustIDFingerprint` requirements:

   - Parameters:
     - `-Path [string[]]` (mandatory, accepts pipeline input and `FullName` alias)
     - `-Parallel [switch]`
     - `-ThrottleLimit [int]` defaulting to processor count

   - Output objects with properties:
     - `Path` (string)
     - `Duration` (double, seconds)
     - `Fingerprint` (string)

   - Support pipeline patterns such as:
     - `Get-ChildItem ... | Get-AcoustIDFingerprint`

   - Optional parallel processing using `ForEach-Object -Parallel`

1. Audio format handling:

   - Supported: `.aiff`, `.aif`, `.wav`, `.mp3`, `.flac`
   - Not supported: `.m4a` / AAC (return a clear error message)
   - For `.mp3`, use `NAudio.Mpeg` if available
   - For `.flac`, use `NAudio.Flac` if available

1. Dependency loading:

   - Implement internal helper `Import-AcoustIdDependencies` that loads assemblies from `PsAcoustId/lib`
   - Require and load:
     - `NAudio.Core.dll`
     - `AcoustID.dll`
   - On macOS, verify `libchromaprint.dylib` exists and set `DYLD_LIBRARY_PATH` for process scope

1. Fingerprint pipeline behavior:

   - Open audio file using appropriate NAudio reader
   - Read samples in chunks
   - Support 16-bit PCM and 24-bit PCM conversion to `Int16`
   - Feed data into Chromaprint context
   - Finish and retrieve fingerprint string

## Module/Manifest Requirements

In `PsAcoustId.psd1`:

- `RootModule = 'PsAcoustId.psm1'`
- `PowerShellVersion = '7.0'`
- `FunctionsToExport = @('Get-AcoustIDFingerprint')`
- Include standard metadata: version, author, description, tags

In `PsAcoustId.psm1`:

- Keep one exported function and internal helper functions/classes for processing
- Keep loader logic only in the module file; store classes/functions in `Classes`, `Private`, and `Public` folders
- Dot-source files in this order: `Classes` → `Private` → `Public`
- Export only public functions discovered from `Public/*.ps1`
- Include comment-based help for the public function

## Build Script Requirements (`Build-Dependencies.ps1`)

Implement a build script that:

- Clones upstream source repos into a temporary folder:
  - `https://github.com/wo80/AcoustID.NET.git`
  - `https://github.com/naudio/NAudio.git`
- Builds projects with `dotnet build -c Release`
- Copies compiled binaries to `PsAcoustId/lib`
- Attempts to build/copy optional `NAudio.Mpeg.dll` and `NAudio.Flac.dll`
- Handles Chromaprint:
  - On macOS: install via Homebrew and copy `libchromaprint.dylib`
  - On non-macOS: attempt NuGet download/extraction for `Chromaprint.dll`
- Supports switches:
  - `-Clean`
  - `-SkipClone`
  - `-RebuildOnly` (may be placeholder if not fully implemented)

## Documentation Requirements

1. Root `README.md` must include:

- Project overview
- Requirements/prerequisites
- Supported formats
- Install steps (clone, build dependencies, import module)
- Standard module install to `$env:PSModulePath`
- Optional PowerShell Gallery publish/install commands
- Usage examples (single file, multiple files, pipeline, parallel)
- Output object description
- Troubleshooting notes
- Pointer to third-party notices in `PsAcoustId/lib/README.md`

1. `PsAcoustId/lib/README.md` must include:

- Required and optional binaries
- Supported format table
- Build-from-source note
- Third-party attribution for:
  - AcoustID.NET
  - NAudio
  - Chromaprint
- Links to upstream projects and note to respect upstream licenses

## Non-Goals

- Do not implement AcoustID web API lookups/submissions
- Do not add GUI, web UI, or unrelated features
- Do not add additional exported commands

## Quality Bar

- Keep code straightforward and maintainable
- Use clear, actionable error messages
- Ensure module imports cleanly after dependencies are present
- Keep implementation cross-platform aware (macOS + Windows/Linux paths)

## Acceptance Checklist

- [ ] `Import-Module ./PsAcoustId/PsAcoustId.psd1 -Force` succeeds when dependencies exist
- [ ] `Get-Command -Module PsAcoustId` shows only `Get-AcoustIDFingerprint`
- [ ] Fingerprints are returned for at least WAV/AIFF inputs
- [ ] MP3/FLAC behavior is graceful when optional decoders are missing
- [ ] README documents installation and usage end-to-end
- [ ] `PsAcoustId/lib/README.md` includes third-party attribution and links

## Definition of Done (PR Structure Checks)

- [ ] `PsAcoustId.psm1` remains a loader-only file (no inline function/class bodies)
- [ ] Source files are split correctly: classes in `Classes/`, helpers in `Private/`, exports in `Public/`
- [ ] Dot-sourcing order in `PsAcoustId.psm1` is `Classes` → `Private` → `Public`
- [ ] Only Public functions are exported from the module
- [ ] `Build-Dependencies.ps1` is at repository root and outputs artifacts to `PsAcoustId/lib`

When implementing, create all files with production-quality content, not placeholders.
