Set-StrictMode -Version Latest

function Get-EnvFileContent {
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ -IsValid })]
        [ValidateScript( { [System.IO.Path]::IsPathRooted($_) })]
        [string]
        $File
    )

    if (!(Test-Path -Path $File)) {
        throw "$File not found."
    }
    try {
        return (Get-Content $File -Raw).Replace("\", "\\") | ConvertFrom-StringData
    }
    catch {
        throw "Error processing $File"
    }
}