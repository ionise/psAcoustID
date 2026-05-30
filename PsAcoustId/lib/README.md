# PsAcoustId Compiled Dependencies

This folder contains compiled .NET assemblies and native libraries required for audio fingerprinting.

## Third-Party Attribution

This module redistributes binaries from the following third-party projects in this `lib` folder. Credit and thanks to the maintainers of these projects.

- **AcoustID.NET** (`AcoustID.dll`)
  - Project: [AcoustID.NET](https://github.com/wo80/AcoustID.NET)
  - Purpose in this module: .NET wrapper/API surface used to interact with Chromaprint.
  - License: See upstream repository license information.

- **NAudio** (`NAudio.Core.dll`, and optionally `NAudio.Mpeg.dll` / `NAudio.Flac.dll`)
  - Project: [NAudio](https://github.com/naudio/NAudio)
  - Purpose in this module: Audio decoding/reading for supported media formats.
  - License: See upstream repository license information.

- **Chromaprint** (`libchromaprint.dylib` on macOS, `Chromaprint.dll` on Windows, `libchromaprint.so` on Linux)
  - Project: [Chromaprint](https://acoustid.org/chromaprint)
  - Source code: [acoustid/chromaprint](https://github.com/acoustid/chromaprint)
  - Purpose in this module: Native fingerprint generation engine.
  - License: See upstream project/repository license information.

If you distribute this module, ensure third-party license terms are included and complied with according to the versions you bundle.

For packaged attribution details, binary versions, and upstream license links, see `../THIRD-PARTY-NOTICES.md`.
Full license texts included with the module are in `../licenses/`.

## Required Files

### Core (Always Required)

- **NAudio.Core.dll** - Cross-platform audio processing library (supports AIFF, WAV)
- **AcoustID.dll** - AcoustID fingerprinting wrapper
- **libchromaprint.dylib** (macOS) / **Chromaprint.dll** (Windows) - Native Chromaprint library

### Optional Format Support

- **NAudio.Mpeg.dll** - MP3 format support
- **NAudio.Flac.dll** - FLAC format support

## Supported Audio Formats

| Format | Extension | Status | Required DLL |
|--------|-----------|--------|--------------|
| AIFF | `.aiff`, `.aif` | ✅ Fully Supported | NAudio.Core |
| WAV | `.wav` | ✅ Fully Supported | NAudio.Core |
| MP3 | `.mp3` | ✅ Fully Supported | NAudio.Mpeg |
| FLAC | `.flac` | ✅ Fully Supported | NAudio.Flac |
| M4A/AAC | `.m4a` | ❌ Not Supported | - |

## Building from Source

Run `./Build-Dependencies.ps1` from repository root to rebuild all dependencies from scratch:

```powershell
cd /Users/david/source/psAcoustID
./Build-Dependencies.ps1 -Clean
```

This will automatically build all available NAudio packages and copy them to this folder.

## Prerequisites

- **macOS**: Homebrew (for installing Chromaprint native library)

```bash
brew install chromaprint
```

- **Windows**: Visual Studio Build Tools or .NET SDK with C++ support

- **Linux**: `libchromaprint-dev` via your package manager

```bash
sudo apt-get install libchromaprint-dev
```

## Distribution

When distributing the PsAcoustId module:

1. Include all compiled DLLs in this folder (NAudio.Core, AcoustID, format-specific readers)
2. Include platform-specific Chromaprint library:
   - macOS: libchromaprint.dylib
   - Windows: Chromaprint.dll  
   - Linux: libchromaprint.so

This way users don't need build tools; they get everything with the module.
