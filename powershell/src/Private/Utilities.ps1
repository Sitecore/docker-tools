Set-StrictMode -Version Latest

function WriteLines
{
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -IsValid })]
        [ValidateScript({ [System.IO.Path]::IsPathRooted($_) })]
        [string]
        $File,

        [string[]]
        $Content,

        [System.Text.Encoding]
        $Encoding = [System.Text.Encoding]::UTF8,

        [int]
        $Retries = 10
    )

    $enc = $Encoding
    $crlf = $enc.GetBytes([Environment]::NewLine)
    $tries = 0
    $fileLock = $false

    if (!(Test-Path -Path $File)) {
        New-Item -Path $File
    }

    do {
        try {
            $fileLock = [System.IO.File]::Open($File, 'Open', 'ReadWrite', 'None')
        }
        catch {
            Write-Warning -Message "Failed to get lock on file. $File"
            $tries++
            Start-Sleep -Milliseconds 100
        }
    } until ($fileLock -or ($tries -eq $Retries))

    if ($tries -eq $Retries) {
        throw "Unable to get lock on file $File after $Retries attempt(s)."
    }

    $fileLock.SetLength(0)

    foreach ($line in $Content) {
        $newLine = $enc.GetBytes($line)
        $fileLock.Write($newLine, 0, $newLine.Length)
        $fileLock.Write($crlf, 0, $crlf.Length)
    }

    $fileLock.Close()
}