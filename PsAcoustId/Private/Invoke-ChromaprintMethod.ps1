function Invoke-ChromaprintMethod {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Instance,
        [Parameter(Mandatory)][string[]]$MethodNames,
        [Parameter()][object[]]$Arguments = @()
    )

    $type = $Instance.GetType()
    foreach ($methodName in $MethodNames) {
        $method = $type.GetMethod($methodName)
        if ($method) {
            return $method.Invoke($Instance, $Arguments)
        }
    }

    throw "Chromaprint method not found. Tried: $($MethodNames -join ', ')"
}
