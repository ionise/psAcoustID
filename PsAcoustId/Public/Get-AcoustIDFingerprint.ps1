function Get-AcoustIDFingerprint {
    <#
    .SYNOPSIS
    Generates AcoustID/Chromaprint fingerprints for audio files.

    .DESCRIPTION
    Decodes audio using NAudio, resamples to 44.1kHz 16-bit PCM, and feeds
    PCM buffers into Chromaprint to generate fingerprints. Supports pipeline
    input and parallel processing.

    .PARAMETER Path
    One or more audio file paths. Accepts pipeline input.

    .PARAMETER Parallel
    Process files concurrently using PowerShell parallel runspaces.

    .PARAMETER ThrottleLimit
    Maximum number of parallel tasks.

    .EXAMPLE
    Get-ChildItem *.flac | Get-AcoustIDFingerprint -Parallel -ThrottleLimit 4
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [string[]]$Path,

        [switch]$Parallel,

        [int]$ThrottleLimit = [Environment]::ProcessorCount
    )

    begin {
        $allPaths = New-Object System.Collections.Generic.List[string]
    }

    process {
        foreach ($p in $Path) {
            if ($p) {
                $allPaths.Add($p)
            }
        }
    }

    end {
        if ($allPaths.Count -eq 0) {
            return
        }

        if ($Parallel) {
            $modulePath = $MyInvocation.MyCommand.Module.Path
            if (-not $modulePath) {
                $modulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'PsAcoustId.psm1'
            }
            $allPaths | ForEach-Object -Parallel {
                $inputPath = $_
                Import-Module $using:modulePath -Force -ErrorAction Stop | Out-Null
                $module = Get-Module PsAcoustId
                if (-not $module) {
                    throw 'PsAcoustId module not loaded in parallel runspace.'
                }
                & $module {
                    param($path)
                    Import-AcoustIdDependencies
                    Invoke-AcoustIdFingerprintInternal -InputPath $path
                } $inputPath
            } -ThrottleLimit $ThrottleLimit
        } else {
            Import-AcoustIdDependencies
            foreach ($p in $allPaths) {
                Invoke-AcoustIdFingerprintInternal -InputPath $p
            }
        }
    }
}
