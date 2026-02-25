function Get-ChromaprintContextType {
    [CmdletBinding()]
    param()

    $typeNames = @(
        'AcoustID.ChromaContext',
        'AcoustID.Native.NativeChromaContext',
        'AcoustID.Native.ChromaprintContext',
        'Chromaprint.ChromaprintContext',
        'Chromaprint.Context'
    )

    foreach ($typeName in $typeNames) {
        $type = [Type]::GetType($typeName, $false)
        if ($type) {
            return $type
        }
    }

    foreach ($assembly in [AppDomain]::CurrentDomain.GetAssemblies()) {
        foreach ($typeName in $typeNames) {
            $type = $assembly.GetType($typeName, $false)
            if ($type) {
                return $type
            }
        }
    }

    throw 'Chromaprint context type not found. Verify the Chromaprint .NET bindings.'
}
