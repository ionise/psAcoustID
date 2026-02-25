# Copilot Architecture Brief Prompt

Use this as a shorter architecture-focused prompt for an AI coding agent.

---

Build a PowerShell 7+ module called **PsAcoustId** for generating local AcoustID/Chromaprint fingerprints.

## Source Layout Convention (Mandatory)

- `PsAcoustId/Classes` → class files (`{ClassName}.ps1`, one class per file)
- `PsAcoustId/Private` → internal helper functions (`{FunctionName}.ps1`)
- `PsAcoustId/Public` → exported commands (`{FunctionName}.ps1`)

`PsAcoustId.psm1` must:

- Be a loader file (no inline function/class bodies)
- Dot-source `.ps1` files in sorted order
- Use load order: `Classes` → `Private` → `Public`
- Export only functions from `Public`

## Architecture

### 1) Public API Layer

- Export a single command: `Get-AcoustIDFingerprint`
- API should support:

  - `-Path [string[]]` with pipeline input
  - `-Parallel` and `-ThrottleLimit`

- Return a typed object with:

  - `Path`, `Duration`, `Fingerprint`

### 2) Dependency/Interop Layer

- Internal function to load managed/native dependencies from `PsAcoustId/lib`
- Load managed DLLs: `AcoustID.dll`, `NAudio.Core.dll`
- On macOS, validate `libchromaprint.dylib` and set process `DYLD_LIBRARY_PATH`
- Resolve Chromaprint context/methods defensively (type/method fallback names)

### 3) Audio Decode + Fingerprint Layer

- Use NAudio readers selected by extension:

  - AIFF/AIF, WAV, MP3 (optional), FLAC (optional)

- Stream data in chunks
- Convert samples to Int16 for Chromaprint feed

  - Handle both 16-bit and 24-bit inputs

- Finish context and return fingerprint string

### 4) Parallel Execution Layer

- For `-Parallel`, use `ForEach-Object -Parallel`
- Ensure module/dependencies are loaded inside each runspace before fingerprinting

### 5) Build/Packaging Layer

- Add `Build-Dependencies.ps1` to clone/build/copy third-party binaries into `lib`
- macOS: install/copy Chromaprint dylib via Homebrew
- Windows/Linux: attempt to retrieve Chromaprint DLL from NuGet
- Keep script idempotent and include `-Clean`, `-SkipClone`, `-RebuildOnly` switches

## Deliverables

- `PsAcoustId/PsAcoustId.psm1`
- `PsAcoustId/PsAcoustId.psd1`
- `Build-Dependencies.ps1`
- `README.md`
- `PsAcoustId/lib/README.md` with third-party notices

## Constraints

- No AcoustID network API integration (fingerprint generation only)
- No extra exported commands
- Keep implementation minimal, robust, and cross-platform aware

## Done Criteria

- Module imports successfully after dependency build
- `Get-AcoustIDFingerprint` works for WAV/AIFF and handles MP3/FLAC availability gracefully
- Documentation covers install, standard module installation, publish flow, usage, and troubleshooting
- Third-party attribution includes project links for bundled binaries
