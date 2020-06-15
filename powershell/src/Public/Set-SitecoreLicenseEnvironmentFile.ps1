Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Sets the "SITECORE_LICENSE" variable in a Docker environment (.env) file using provided Sitecore license file.
.DESCRIPTION
    Sets the "SITECORE_LICENSE" variable in a Docker environment (.env) file to the expected compressed, Base64 encoded value.
    The Sitecore license can be passed as a stream or a file path.
    Assumes .env file is in the current directory by default.
.PARAMETER LicenseStream
    Specifies the Sitecore license file stream. Either LicenseStream or LicensePath is required.
.PARAMETER LicensePath
    Specifies the Sitecore license file path. Either LicenseStream or LicensePath is required.
.PARAMETER EnvironmentFilePath
    Specifies the Docker environment (.env) file path. Assumes .env file is in the current directory by default.
.EXAMPLE
    PS C:\> Set-SitecoreLicenseEnvironmentFile -LicensePath C:\License\license.xml
.EXAMPLE
    PS C:\> Set-SitecoreLicenseEnvironmentFile -LicensePath C:\License\license.xml -EnvironmentFilePath .\src\.env
.EXAMPLE
    PS C:\> [System.IO.File]::OpenRead('C:\License\license.xml') | Set-SitecoreLicenseEnvironmentFile
.INPUTS
    System.IO.FileStream. You can pipe in the LicenseStream parameter.
.OUTPUTS
    None.
#>
function Set-SitecoreLicenseEnvironmentFile
{
    [CmdletBinding(DefaultParameterSetName = 'FromPath')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'FromStream')]
        [System.IO.FileStream]
        $LicenseStream,

        [Parameter(Mandatory = $true, ParameterSetName = 'FromPath')]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]
        $LicensePath,

        [ValidateScript({ $_ -match '\.env$' })]
        [string]
        $EnvironmentFilePath = (Join-Path $MyInvocation.PSScriptRoot ".env")
    )

    if (!(Test-Path $EnvironmentFilePath)) {
        throw "The environment file $EnvironmentFilePath does not exist"
    }

    $licenseString = $null
    if ($PSCmdlet.ParameterSetName -eq 'FromPath') {
        $licenseString = ConvertTo-CompressedBase64String -Path $LicensePath
    }
    else {
        $licenseString = $LicenseStream | ConvertTo-CompressedBase64String
    }

    # sanity check
    if ($licenseString.Length -lt 100) {
        throw "Unknown error, the compressed license string '$licenseString' is too short."
    }

    Set-EnvironmentFileVariable -Variable 'SITECORE_LICENSE' -Value $licenseString -Path $EnvironmentFilePath

    # persist in current session
    $env:SITECORE_LICENSE = $licenseString
}