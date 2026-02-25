function Convert-FloatSamplesToInt16 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][float[]]$Samples,
        [Parameter(Mandatory)][int]$Count
    )

    $shorts = New-Object short[] $Count
    for ($i = 0; $i -lt $Count; $i++) {
        $value = [Math]::Round($Samples[$i] * 32767.0)
        if ($value -gt 32767) { $value = 32767 }
        if ($value -lt -32768) { $value = -32768 }
        $shorts[$i] = [short]$value
    }

    return $shorts
}
