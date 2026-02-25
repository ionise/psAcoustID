function New-ChromaprintContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$SampleRate,
        [Parameter(Mandatory)][int]$Channels
    )

    $ctxType = Get-ChromaprintContextType
    $ctx = [Activator]::CreateInstance($ctxType)

    Invoke-ChromaprintMethod -Instance $ctx -MethodNames @('Start') -Arguments @($SampleRate, $Channels) | Out-Null

    return $ctx
}
