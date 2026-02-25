function Invoke-AcoustIdFingerprintInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$InputPath
    )

    $reader = $null
    try {
        Write-Verbose "Processing file: $InputPath"

        $extension = [System.IO.Path]::GetExtension($InputPath).ToLower()

        switch ($extension) {
            {$_ -in '.aiff', '.aif'} {
                $reader = [NAudio.Wave.AiffFileReader]::new($InputPath)
            }
            '.wav' {
                $reader = [NAudio.Wave.WaveFileReader]::new($InputPath)
            }
            '.mp3' {
                try {
                    $mp3ReaderType = [Type]::GetType('NAudio.Mpeg.Mp3FileReader')
                    if ($mp3ReaderType) {
                        $reader = [Activator]::CreateInstance($mp3ReaderType, @($InputPath))
                    } else {
                        Write-Error "MP3 reader not available. Ensure NAudio.Mpeg.dll is in lib folder."
                        return
                    }
                } catch {
                    Write-Error "Failed to open MP3 file. Ensure NAudio.Mpeg.dll is available. Error: $_"
                    return
                }
            }
            '.flac' {
                try {
                    $flacReaderType = [Type]::GetType('NAudio.Flac.FlacFileReader')
                    if ($flacReaderType) {
                        $reader = [Activator]::CreateInstance($flacReaderType, @($InputPath))
                    } else {
                        Write-Error "FLAC reader not available. Ensure NAudio.Flac.dll is in lib folder."
                        return
                    }
                } catch {
                    Write-Error "Failed to open FLAC file. Ensure NAudio.Flac.dll is available. Error: $_"
                    return
                }
            }
            '.m4a' {
                Write-Error "M4A/AAC format is not directly supported by NAudio. Consider converting to AIFF, WAV, FLAC, or MP3."
                return
            }
            default {
                throw "Unsupported audio format: $extension. Supported formats: .aiff, .aif, .wav, .mp3, .flac"
            }
        }

        $duration = $reader.TotalTime.TotalSeconds
        $waveFormat = $reader.WaveFormat
        $sampleRate = $waveFormat.SampleRate
        $channels = $waveFormat.Channels
        $bitsPerSample = $waveFormat.BitsPerSample

        Write-Verbose "Audio format: $($sampleRate)Hz, $channels channels, $bitsPerSample-bit"

        $ctx = New-ChromaprintContext -SampleRate $sampleRate -Channels $channels

        $sourceBytesPerSample = $bitsPerSample / 8
        $sourceFrameSize = $sourceBytesPerSample * $channels
        $bufferSize = 4096 * $sourceFrameSize
        $buffer = New-Object byte[] $bufferSize

        while ($true) {
            $bytesRead = $reader.Read($buffer, 0, $buffer.Length)
            if ($bytesRead -le 0) {
                break
            }

            $frameCount = [int]($bytesRead / $sourceFrameSize)
            $completeFrameBytes = $frameCount * $sourceFrameSize

            if ($completeFrameBytes -le 0) {
                continue
            }

            $int16Buffer = $null

            if ($bitsPerSample -eq 16) {
                $sampleCount = $completeFrameBytes / 2
                $int16Buffer = New-Object short[] $sampleCount
                [System.Buffer]::BlockCopy($buffer, 0, $int16Buffer, 0, $completeFrameBytes)
            }
            elseif ($bitsPerSample -eq 24) {
                $sampleCount = $frameCount * $channels
                $int16Buffer = New-Object short[] $sampleCount

                for ($i = 0; $i -lt $sampleCount; $i++) {
                    $byteOffset = $i * 3
                    $byte1 = $buffer[$byteOffset]
                    $byte2 = $buffer[$byteOffset + 1]
                    $byte3 = $buffer[$byteOffset + 2]

                    $sample32 = [int]($byte1 -bor ($byte2 -shl 8) -bor ($byte3 -shl 16))
                    if ($sample32 -band 0x800000) {
                        $sample32 = $sample32 -bor 0xFF000000
                    }

                    $int16Buffer[$i] = [short]($sample32 -shr 8)
                }
            }
            else {
                throw "Unsupported bit depth: $bitsPerSample-bit. Only 16-bit and 24-bit audio are supported."
            }

            try {
                $ctx.Feed($int16Buffer, $int16Buffer.Length)
            } catch {
                Write-Error "Feed failed: $_"
                throw
            }
        }

        Invoke-ChromaprintMethod -Instance $ctx -MethodNames @('Finish') | Out-Null
        $fingerprint = Invoke-ChromaprintMethod -Instance $ctx -MethodNames @('GetFingerprint', 'Fingerprint')

        [AcoustIdFingerprintResult]::new($InputPath, $duration, ([string]$fingerprint))
    }
    finally {
        if ($reader) {
            $reader.Dispose()
        }
    }
}
