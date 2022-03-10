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
        $DnsName = "localhost",

        [Parameter()]
        [ValidateSet(512, 1024, 2048, 4096)]
        [int]
        $KeyLength = 2048
    )

    $certRequest = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
        [X500DistinguishedName]::new("CN=$DnsName"), 
        [System.Security.Cryptography.RSA]::Create($KeyLength), 
        [System.Security.Cryptography.HashAlgorithmName]::SHA256, 
        [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)

    $basicConstraints = [System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::new($false, $false, 0, $false)
    $certRequest.CertificateExtensions.Add($basicConstraints)
    $subjectKeyIdentifier = [System.Security.Cryptography.X509Certificates.X509SubjectKeyIdentifierExtension]::new($certRequest.PublicKey, $false)
    $certRequest.CertificateExtensions.Add($subjectKeyIdentifier)

    $certificate = $certRequest.CreateSelfSigned([datetime]::Now, [datetime]::Now.AddYears(5))
    $certificateBytes = $certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx, $Password)
    
    return [System.Convert]::ToBase64String($certificateBytes)
}