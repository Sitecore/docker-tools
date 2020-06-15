Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Sets the "SITECORE_LICENSE" environment variable using provided Sitecore license file.
.DESCRIPTION
    Sets the "SITECORE_LICENSE" environment variable to the expected compressed, Base64 encoded value.
    The Sitecore license can be passed as a stream or a file path.
.PARAMETER LicenseStream
    Specifies the Sitecore license file stream. Either LicenseStream or LicensePath is required.
.PARAMETER LicensePath
    Specifies the Sitecore license file path. Either LicenseStream or LicensePath is required.
.PARAMETER Target
    Specifies the environment variable target. Can be either "Machine" or "User". Default is "Machine".
.EXAMPLE
    PS C:\> Set-SitecoreLicenseEnvironmentVariable -LicensePath C:\License\license.xml
.EXAMPLE
    PS C:\> Set-SitecoreLicenseEnvironmentVariable -LicensePath C:\License\license.xml -Target "User"
.EXAMPLE
    PS C:\> [System.IO.File]::OpenRead('C:\License\license.xml') | Set-SitecoreLicenseEnvironmentVariable
.INPUTS
    System.IO.FileStream. You can pipe in the LicenseStream parameter.
.OUTPUTS
    None.
#>
function Set-SitecoreLicenseEnvironmentVariable
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

        [ValidateSet('User','Machine')]
        [string]
        $Target = 'Machine'
    )

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

    SetEnvironmentVariable -Variable "SITECORE_LICENSE" -Value $licenseString -Target $Target

    # persist in current session
    $env:SITECORE_LICENSE = $licenseString
}