Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Loads a certificate from a specified path.
.DESCRIPTION
    Loads a certificate from the specified file path. If a password is provided, it will be used to decrypt the certificate.
.PARAMETER CertPath
    The file path to the certificate to be loaded.
.PARAMETER CertPassword
    The password for the certificate, if it is encrypted. This parameter is optional.
.INPUTS
    None. You cannot pipe objects to Load-Certificate.
.OUTPUTS
    System.Security.Cryptography.X509Certificates.X509Certificate2. The loaded certificate.
.EXAMPLE
    PS C:\> Load-Certificate -CertPath "C:\path\to\certificate.pfx"
    PS C:\> Load-Certificate -CertPath "C:\path\to\certificate.pfx" -CertPassword (ConvertTo-SecureString -String "password" -AsPlainText -Force)
#>
function Load-Certificate {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $CertPath,

        [Parameter()]
        [SecureString]
        $CertPassword = $null
    )

    Write-Information -MessageData "Loading '$CertPath' certificate." -InformationAction Continue

    # Reading into memory first as a workaround for
    # https://github.com/dotnet/runtime/issues/27826		
    $certContent = [System.IO.File]::ReadAllBytes($CertPath)

    if ($CertPassword -ne $null) {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @($certContent, $CertPassword)
    }else {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @(,$certContent)
    }

    return $cert
}