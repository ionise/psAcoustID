function Convert-FingerprintToBase36 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Fingerprint
    )

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Fingerprint)
    if ($bytes.Length -eq 0) {
        return ''
    }

    $unsignedBytes = New-Object byte[] ($bytes.Length + 1)
    [System.Array]::Copy($bytes, $unsignedBytes, $bytes.Length)
    $value = [System.Numerics.BigInteger]::new($unsignedBytes)

    if ($value -eq 0) {
        return '0'
    }

    $alphabet = '0123456789abcdefghijklmnopqrstuvwxyz'
    $sb = New-Object System.Text.StringBuilder

    while ($value -gt 0) {
        $remainder = [System.Numerics.BigInteger]::Remainder($value, 36)
        $value = [System.Numerics.BigInteger]::Divide($value, 36)
        $null = $sb.Insert(0, $alphabet[[int]$remainder])
    }

    return $sb.ToString()
}
