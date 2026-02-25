# psAcoustID

PowerShell module for generating AcoustID/Chromaprint fingerprints from local audio files.

This module exports one public function:

- `Get-AcoustIDFingerprint`

It decodes audio with NAudio and computes fingerprints via AcoustID/Chromaprint bindings.

## Repository Layout

- `PsAcoustId/PsAcoustId.psd1` - module manifest
- `PsAcoustId/PsAcoustId.psm1` - module loader (dot-sources functions and exports Public commands)
- `PsAcoustId/Public/` - user-facing functions (`{FunctionName}.ps1`)
- `PsAcoustId/Private/` - internal helper functions (`{FunctionName}.ps1`)
- `Build-Dependencies.ps1` - dependency bootstrap/build script (writes artifacts to `PsAcoustId/lib`)
- `PsAcoustId/lib/` - compiled managed/native dependencies

## Requirements

- PowerShell 7+
- .NET SDK (used by `Build-Dependencies.ps1`)
- Git (used by `Build-Dependencies.ps1` to clone dependency source)

Platform notes:

- **macOS**: Homebrew is required by the build script to install Chromaprint (`brew install chromaprint`).
- **Windows/Linux**: Build script attempts to fetch Chromaprint binaries from NuGet.

## Supported Audio Formats

- `.aiff`, `.aif` (AIFF)
- `.wav`
- `.mp3` (requires `NAudio.Mpeg.dll` in `lib/`)
- `.flac` (requires `NAudio.Flac.dll` in `lib/`)

Not supported:

- `.m4a` / AAC

## Installation

### 1) Clone the repository

```powershell
git clone https://github.com/<your-org>/psAcoustID.git
cd psAcoustID
```

### 2) Build/download module dependencies

From repository root:

```powershell
./Build-Dependencies.ps1 -Clean
```

This script:

- Builds `AcoustID.dll` and `NAudio.*.dll`
- Places binaries in `PsAcoustId/lib/`
- Installs/copies native Chromaprint library for your platform

### 3) Import the module

From repository root:

```powershell
Import-Module ./PsAcoustId/PsAcoustId.psd1 -Force
```

Verify:

```powershell
Get-Command -Module PsAcoustId
```

## Install as a Standard PowerShell Module

### Install locally to `$env:PSModulePath`

After building dependencies, copy the module folder into one of your module paths (current user scope shown):

```powershell
$dest = Join-Path $HOME "Documents/PowerShell/Modules/PsAcoustId"
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Copy-Item ./PsAcoustId/* $dest -Recurse -Force
Import-Module PsAcoustId -Force
```

### Publish to PowerShell Gallery (optional)

If you want others to install with `Install-Module`:

```powershell
# one-time (create API key in PSGallery account)
$NuGetApiKey = "<PSGallery API Key>"

# from repository root
Publish-Module -Path ./PsAcoustId -NuGetApiKey $NuGetApiKey
```

Users can then install it with:

```powershell
Install-Module PsAcoustId -Scope CurrentUser
```

## Usage

### Generate a fingerprint for a single file

```powershell
Get-AcoustIDFingerprint -Path ./samples/test.flac
```

### Process multiple files

```powershell
Get-AcoustIDFingerprint -Path ./a.wav, ./b.mp3, ./c.flac
```

### Pipeline usage

```powershell
Get-ChildItem ./music -File -Include *.wav,*.aif,*.aiff,*.mp3,*.flac -Recurse |
    Get-AcoustIDFingerprint
```

### Parallel processing

```powershell
Get-ChildItem ./music -File -Include *.flac -Recurse |
    Get-AcoustIDFingerprint -Parallel -ThrottleLimit 4
```

## Output

`Get-AcoustIDFingerprint` returns objects with:

- `Path` - input file path
- `Duration` - duration in seconds
- `Fingerprint` - generated Chromaprint fingerprint string

Example formatting:

```powershell
Get-AcoustIDFingerprint -Path ./samples/test.wav |
    Select-Object Path, Duration, Fingerprint |
    Format-List
```

## Command Reference

### `Get-AcoustIDFingerprint`

Parameters:

- `-Path <string[]>` (required, accepts pipeline input and `FullName` by property name)
- `-Parallel` (optional switch)
- `-ThrottleLimit <int>` (optional, default = processor count)

## Troubleshooting

- If you see missing DLL errors, re-run:

```powershell
./Build-Dependencies.ps1 -Clean
```

- If MP3/FLAC files fail to open, ensure the corresponding reader DLLs exist in `PsAcoustId/lib/`.
- On macOS, if native library loading fails, confirm `libchromaprint.dylib` exists in `PsAcoustId/lib/`.
- `.m4a` is currently not supported by this module.

## Notes

- The repository contains an `AccoustIDAPIKey` file, but the current module implementation only generates local fingerprints and does not call the AcoustID web API.
- Fingerprint generation currently supports 16-bit and 24-bit PCM decoding paths.

## Third-Party Notices

For attribution and upstream project links for bundled external binaries, see:

- `PsAcoustId/lib/README.md`
