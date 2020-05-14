Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Converts file contents to GZip compressed, Base64 encoded value.
.DESCRIPTION
    Converts file contents to GZip compressed, Base64 encoded value.
.PARAMETER Stream
    Specifies the file stream. Either Stream or Path is required.
.PARAMETER Path
    Specifies the file path. Either Stream or Path is required.
.EXAMPLE
    PS C:\> ConvertTo-CompressedBase64String -Path C:\file.txt
.EXAMPLE
    PS C:\> [System.IO.File]::OpenRead('C:\file.txt') | ConvertTo-CompressedBase64String
.INPUTS
    System.IO.FileStream
.OUTPUTS
    System.String. The GZip compressed, Base64 encoded string.
#>
function ConvertTo-CompressedBase64String
{
    [CmdletBinding(DefaultParameterSetName = 'FromPath')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'FromStream')]
        [System.IO.FileStream]
        $Stream,

        [Parameter(Mandatory = $true, ParameterSetName = 'FromPath')]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]
        $Path
    )

    $encodedString = $null
    if ($PSCmdlet.ParameterSetName -eq 'FromPath') {
        $Stream = [System.IO.File]::OpenRead($Path)
    }

    try {
        $memory = [System.IO.MemoryStream]::new()
        $gzip = [System.IO.Compression.GZipStream]::new($memory, [System.IO.Compression.CompressionLevel]::Optimal, $false)
        $Stream.CopyTo($gzip)
        $gzip.Close()

        # base64 encode the gzipped content
        $encodedString = [System.Convert]::ToBase64String($memory.ToArray())
    }
    finally {
        # cleanup
        if ($null -ne $gzip) {
            $gzip.Dispose()
            $gzip = $null
        }

        if ($null -ne $memory) {
            $memory.Dispose()
            $memory = $null
        }

        $Stream.Dispose()
        $Stream = $null
    }

    return $encodedString
}