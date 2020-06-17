Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Generates a new self-signed certificate in its Base64 encoded form.
.DESCRIPTION
    Generates a new self-signed certificate and returns the certificate in its password-protected, Base64 encoded form.
.PARAMETER Password
    Specifies the password to be used for securing the certificate.
.PARAMETER DnsName
    Specifies the DnsName to use for the certificate. Uses "localhost" by default.
.EXAMPLE
    PS C:\> Get-SitecoreCertificateAsBase64String -DnsName "localhost" -Password (ConvertTo-SecureString -String "Password12345" -Force -AsPlainText)
.INPUTS
    System.SecureString. You can pipe in the Password parameter.
.OUTPUTS
    System.String. The Base64 encoded string.
#>
function Get-SitecoreCertificateAsBase64String
{
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [securestring]
        $Password,

        [ValidateNotNullOrEmpty()]
        [string[]]
        $DnsName = "localhost"
    )

    # Create the certificate
    $params = @{
        DnsName = $DnsName
        NotAfter = (Get-Date).AddYears(5)
    }
    $cert = New-SelfSignedCertificate @params

    Write-Verbose "Created temporary self-signed certificate $($cert.Thumbprint) for $DnsName"

    # Export to pfx
    $pfxPath = Join-Path $Env:TEMP "sitecorecertificate.pfx"
    $params = @{
        Cert = $cert
        FilePath = $pfxPath
        Password = $Password
        Force = $true
    }
    Export-PfxCertificate @params | Out-Null

    Write-Verbose "Exported certificate to temporary pfx file $pfxPath"

    # Get Base64 encoded form of the pfx
    $encodedString = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Get-Item $pfxPath)))

    # Cleanup
    $cert | Remove-Item
    $pfxPath | Remove-Item

    Write-Verbose "Temporary certificate and pfx file removed"

    # Return Base64 encoded string
    return $encodedString
}