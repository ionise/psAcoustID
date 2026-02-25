# PsAcoustId.psm1

class AcoustIdFingerprintResult {
    [string]$Path
    [double]$Duration
    [string]$Fingerprint

    AcoustIdFingerprintResult([string]$path, [double]$duration, [string]$fingerprint) {
        $this.Path = $path
        $this.Duration = $duration
        $this.Fingerprint = $fingerprint
    }
}

$privatePath = Join-Path $PSScriptRoot 'Private'
$publicPath = Join-Path $PSScriptRoot 'Public'

$privateFunctions = if (Test-Path -LiteralPath $privatePath) {
    Get-ChildItem -Path $privatePath -Filter '*.ps1' -File | Sort-Object Name
} else {
    @()
}

$publicFunctions = if (Test-Path -LiteralPath $publicPath) {
    Get-ChildItem -Path $publicPath -Filter '*.ps1' -File | Sort-Object Name
} else {
    @()
}

foreach ($file in $privateFunctions) {
    . $file.FullName
}

foreach ($file in $publicFunctions) {
    . $file.FullName
}

Export-ModuleMember -Function ($publicFunctions.BaseName) -Variable @()
