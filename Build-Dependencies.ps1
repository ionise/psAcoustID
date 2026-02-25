#!/usr/bin/env pwsh
<#
.SYNOPSIS
Build script to compile AcoustID.NET and NAudio DLLs and copy them to lib folder.

.DESCRIPTION
This script automates:
1. Cloning AcoustID.NET and NAudio repositories to tmp folder
2. Building the projects using dotnet CLI
3. Copying the compiled DLLs to PsAcoustId/lib
4. On macOS, installing Chromaprint via Homebrew

.PARAMETER Clean
Remove tmp folder before building (does a fresh download/build).

.PARAMETER SkipClone
Skip cloning repos; use existing repos in tmp folder.

.PARAMETER RebuildOnly
Only rebuild from existing sources; skip Chromaprint installation.

.EXAMPLE
./Build-Dependencies.ps1 -Clean
#>

[CmdletBinding()]
param(
    [switch]$Clean,
    [switch]$SkipClone,
    [switch]$RebuildOnly
)

$ErrorActionPreference = 'Stop'

$scriptRoot = $PSScriptRoot
$tmpDir = Join-Path $scriptRoot 'tmp'
$libDir = Join-Path $scriptRoot 'PsAcoustId/lib'

$acoustIdRepo = 'https://github.com/wo80/AcoustID.NET.git'
$naudioRepo = 'https://github.com/naudio/NAudio.git'

$acoustIdDir = Join-Path $tmpDir 'AcoustID.NET'
$naudioDir = Join-Path $tmpDir 'NAudio'

# Clean tmp folder if requested
if ($Clean -and (Test-Path $tmpDir)) {
    Write-Host "Cleaning tmp folder..." -ForegroundColor Yellow
    Remove-Item -Path $tmpDir -Recurse -Force
}

# Create directories
if (-not (Test-Path $tmpDir)) {
    New-Item -Path $tmpDir -ItemType Directory | Out-Null
}

if (-not (Test-Path $libDir)) {
    New-Item -Path $libDir -ItemType Directory | Out-Null
}

# Clone repositories
if (-not $SkipClone) {
    Write-Host "`nCloning AcoustID.NET..." -ForegroundColor Cyan
    if (Test-Path $acoustIdDir) {
        Write-Host "Repository already exists, pulling latest..." -ForegroundColor Yellow
        Push-Location $acoustIdDir
        git pull
        Pop-Location
    } else {
        git clone $acoustIdRepo $acoustIdDir
    }

    Write-Host "`nCloning NAudio..." -ForegroundColor Cyan
    if (Test-Path $naudioDir) {
        Write-Host "Repository already exists, pulling latest..." -ForegroundColor Yellow
        Push-Location $naudioDir
        git pull
        Pop-Location
    } else {
        git clone $naudioRepo $naudioDir
    }
}

# Build AcoustID.NET
Write-Host "`nBuilding AcoustID.NET..." -ForegroundColor Cyan
$acoustIdProject = Join-Path $acoustIdDir 'AcoustID/AcoustID.csproj'
Push-Location (Split-Path $acoustIdProject)
dotnet build -c Release
Pop-Location

# Find and copy AcoustID.dll
$acoustIdDll = Get-ChildItem -Path $acoustIdDir -Recurse -Filter 'AcoustID.dll' |
    Where-Object { $_.FullName -match 'Release' -and $_.FullName -match 'netstandard2.0' } |
    Select-Object -First 1

if ($acoustIdDll) {
    Write-Host "Copying $($acoustIdDll.Name) to lib..." -ForegroundColor Green
    Copy-Item -Path $acoustIdDll.FullName -Destination $libDir -Force
} else {
    Write-Error "AcoustID.dll not found after build"
}

# Build NAudio.Core (cross-platform)
Write-Host "`nBuilding NAudio.Core..." -ForegroundColor Cyan
$naudioCoreProject = Join-Path $naudioDir 'NAudio.Core/NAudio.Core.csproj'
Push-Location (Split-Path $naudioCoreProject)
dotnet build -c Release
Pop-Location

# Find and copy NAudio.Core.dll
$naudioCoreDll = Get-ChildItem -Path $naudioDir -Recurse -Filter 'NAudio.Core.dll' |
    Where-Object { $_.FullName -match 'Release' } |
    Select-Object -First 1

if ($naudioCoreDll) {
    Write-Host "Copying $($naudioCoreDll.Name) to lib..." -ForegroundColor Green
    Copy-Item -Path $naudioCoreDll.FullName -Destination $libDir -Force
} else {
    Write-Error "NAudio.Core.dll not found after build"
}

# Build NAudio.Mpeg (MP3 support)
Write-Host "`nBuilding NAudio.Mpeg for MP3 support..." -ForegroundColor Cyan
$naudioMpegProject = Join-Path $naudioDir 'NAudio.Mpeg/NAudio.Mpeg.csproj'
if (Test-Path $naudioMpegProject) {
    Push-Location (Split-Path $naudioMpegProject)
    try {
        dotnet build -c Release

        $naudioMpegDll = Get-ChildItem -Path $naudioDir -Recurse -Filter 'NAudio.Mpeg.dll' |
            Where-Object { $_.FullName -match 'Release' } |
            Select-Object -First 1

        if ($naudioMpegDll) {
            Write-Host "Copying $($naudioMpegDll.Name) to lib..." -ForegroundColor Green
            Copy-Item -Path $naudioMpegDll.FullName -Destination $libDir -Force
        }
    } catch {
        Write-Host "Warning: NAudio.Mpeg build failed: $_" -ForegroundColor Yellow
    }
    Pop-Location
} else {
    Write-Host "Warning: NAudio.Mpeg project not found. MP3 support may not be available." -ForegroundColor Yellow
}

# Build NAudio.Flac if available
Write-Host "`nBuilding NAudio.Flac for FLAC support..." -ForegroundColor Cyan
$naudioFlacProject = Join-Path $naudioDir 'NAudio.Flac/NAudio.Flac.csproj'
if (Test-Path $naudioFlacProject) {
    Push-Location (Split-Path $naudioFlacProject)
    try {
        dotnet build -c Release

        $naudioFlacDll = Get-ChildItem -Path $naudioDir -Recurse -Filter 'NAudio.Flac.dll' |
            Where-Object { $_.FullName -match 'Release' } |
            Select-Object -First 1

        if ($naudioFlacDll) {
            Write-Host "Copying $($naudioFlacDll.Name) to lib..." -ForegroundColor Green
            Copy-Item -Path $naudioFlacDll.FullName -Destination $libDir -Force
        }
    } catch {
        Write-Host "Warning: NAudio.Flac build failed: $_" -ForegroundColor Yellow
    }
    Pop-Location
} else {
    Write-Host "Warning: NAudio.Flac project not found. FLAC support may not be available." -ForegroundColor Yellow
}

# On macOS, get Chromaprint from Homebrew
if ($PSVersionTable.OS -match 'Darwin') {
    Write-Host "`nInstalling Chromaprint via Homebrew (macOS detected)..." -ForegroundColor Cyan

    # Check if Homebrew is installed
    $brew = Get-Command brew -ErrorAction SilentlyContinue
    if ($brew) {
        # Install chromaprint formula
        Write-Host "Installing chromaprint via brew..." -ForegroundColor Yellow
        & brew install chromaprint --quiet

        # Find the installed dylib
        $chromaprintDylib = @(
            '/usr/local/opt/chromaprint/lib/libchromaprint.dylib',
            '/opt/homebrew/opt/chromaprint/lib/libchromaprint.dylib'
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1

        if ($chromaprintDylib) {
            Write-Host "Found Chromaprint native library at: $chromaprintDylib" -ForegroundColor Green
            Write-Host "Copying to lib..." -ForegroundColor Yellow
            Copy-Item -Path $chromaprintDylib -Destination (Join-Path $libDir 'libchromaprint.dylib') -Force
            Write-Host "✓ libchromaprint.dylib copied" -ForegroundColor Green
        } else {
            Write-Error "Chromaprint native library not found after brew install"
        }
    } else {
        Write-Error "Homebrew not found. Please install Homebrew: https://brew.sh"
        Write-Host "Or manually download Chromaprint from: https://acoustid.org/chromaprint" -ForegroundColor Yellow
    }
} else {
    # On other platforms, try NuGet
    Write-Host "`nDownloading Chromaprint from NuGet..." -ForegroundColor Cyan
    $chromaprintSources = @(
        'https://api.nuget.org/v3-flatcontainer/chromaprint.net/1.5.1/chromaprint.net.1.5.1.nupkg',
        'https://www.nuget.org/api/v2/package/Chromaprint.NET/1.5.1',
        'https://www.nuget.org/api/v2/package/Chromaprint.NET'
    )

    $chromaprintDll = $null
    foreach ($source in $chromaprintSources) {
        try {
            Write-Host "Trying: $source" -ForegroundColor Yellow
            $nugetPackage = Join-Path $tmpDir 'chromaprint.nupkg'
            Invoke-WebRequest -Uri $source -OutFile $nugetPackage -ErrorAction Stop -TimeoutSec 10
            Write-Host "Downloaded Chromaprint package" -ForegroundColor Green

            $chromaprintExtractDir = Join-Path $tmpDir 'chromaprint_extracted'
            if (Test-Path $chromaprintExtractDir) {
                Remove-Item -Path $chromaprintExtractDir -Recurse -Force
            }
            Expand-Archive -Path $nugetPackage -DestinationPath $chromaprintExtractDir -Force

            $chromaprintDll = Get-ChildItem -Path $chromaprintExtractDir -Recurse -Filter 'Chromaprint.dll' |
                Where-Object { $_.FullName -match '(net|runtimes)' } |
                Select-Object -First 1

            if ($chromaprintDll) {
                Write-Host "Found Chromaprint.dll in package" -ForegroundColor Green
                break
            }
        } catch {
            Write-Host "Failed to download from $source`: $_" -ForegroundColor Yellow
        }
    }

    if ($chromaprintDll) {
        Write-Host "Copying $($chromaprintDll.Name) to lib..." -ForegroundColor Green
        Copy-Item -Path $chromaprintDll.FullName -Destination $libDir -Force
    } else {
        Write-Error "Chromaprint.dll not found. You may need to manually download it from: https://github.com/acoustid/chromaprint"
    }
}

Write-Host "`nBuild complete!" -ForegroundColor Green
Write-Host "DLLs copied to: $libDir" -ForegroundColor Green
Get-ChildItem -Path $libDir -Filter '*.dll' | Format-Table Name, Length, LastWriteTime

# Clean up tmp folder
Write-Host "`nCleaning up tmp folder..." -ForegroundColor Yellow
if (Test-Path $tmpDir) {
    Remove-Item -Path $tmpDir -Recurse -Force
    Write-Host "tmp folder removed" -ForegroundColor Green
}
