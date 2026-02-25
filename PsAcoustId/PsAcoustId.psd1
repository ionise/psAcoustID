@{
    RootModule = 'PsAcoustId.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'c1f5d18f-6b5a-4c0a-9d2e-8bb3d0c93d23'
    Author = 'psmusictagger'
    CompanyName = 'psmusictagger'
    Copyright = '(c) 2026'
    Description = 'Generate AcoustID/Chromaprint fingerprints using NAudio and Chromaprint .NET bindings.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Get-AcoustIDFingerprint')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('acoustid', 'chromaprint', 'audio', 'fingerprint')
        }
    }
}
