function Import-AcoustIdDependencies {
    [CmdletBinding()]
    param()

    $moduleRoot = $MyInvocation.MyCommand.Module.ModuleBase
    $libPath = Join-Path $moduleRoot 'lib'
    $naudioPath = Join-Path $libPath 'NAudio.Core.dll'
    $acoustIdPath = Join-Path $libPath 'AcoustID.dll'

    if (-not (Test-Path -LiteralPath $naudioPath)) {
        throw "NAudio.Core.dll not found at $naudioPath. Run Build-Dependencies.ps1 to compile dependencies."
    }
    if (-not (Test-Path -LiteralPath $acoustIdPath)) {
        throw "AcoustID.dll not found at $acoustIdPath. Run Build-Dependencies.ps1 to compile dependencies."
    }

    if ($PSVersionTable.OS -match 'Darwin') {
        $chromaprintLib = Join-Path $libPath 'libchromaprint.dylib'
        if (-not (Test-Path -LiteralPath $chromaprintLib)) {
            throw "libchromaprint.dylib not found at $chromaprintLib. Run Build-Dependencies.ps1 to install dependencies via Homebrew."
        }
        Write-Verbose "Found native Chromaprint library at $chromaprintLib"

        $currentDyldPath = [Environment]::GetEnvironmentVariable('DYLD_LIBRARY_PATH')
        $pathsToAdd = @($libPath, '/opt/homebrew/opt/chromaprint/lib', '/usr/local/opt/chromaprint/lib')
        if ($currentDyldPath) {
            $pathsToAdd += $currentDyldPath.Split(':')
        }
        $newDyldPath = ($pathsToAdd | Select-Object -Unique) -join ':'
        [Environment]::SetEnvironmentVariable('DYLD_LIBRARY_PATH', $newDyldPath, 'Process')
        Write-Verbose "Set DYLD_LIBRARY_PATH to include: $libPath and Homebrew paths"
    }

    Add-Type -Path $naudioPath -ErrorAction Stop | Out-Null
    Add-Type -Path $acoustIdPath -ErrorAction Stop | Out-Null

    Write-Verbose "AcoustId dependencies loaded successfully"
}
