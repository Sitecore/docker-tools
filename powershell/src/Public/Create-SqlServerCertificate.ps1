Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Creates a self-signed certificate for SQL Server.
.DESCRIPTION
    Creates a self-signed certificate with the specified CommonName, DnsName, and SignerCertificate.
    The certificate is configured for SSL Server Authentication and uses RSA with SHA256.
.PARAMETER CommonName
    The common name (CN) to use for the certificate subject.
.PARAMETER DnsName
    The DNS name to include in the certificate.
.PARAMETER SignerCertificate
    The certificate used to sign the new certificate.
.PARAMETER NotBefore
    The start date and time for the certificate validity period. Default is the current date and time.
.PARAMETER NotAfter
    The end date and time for the certificate validity period. Default is 3285 days from the current date and time.
.INPUTS
    None. You cannot pipe objects to Create-SqlServerCertificate.
.OUTPUTS
    System.Security.Cryptography.X509Certificates.X509Certificate2. The created certificate.
.EXAMPLE
    PS C:\> $signerCert = Get-Item Cert:\LocalMachine\My\{THUMBPRINT}
    PS C:\> Create-SqlServerCertificate -CommonName 'sql.server' -DnsName 'localhost' -SignerCertificate $signerCert
#>
function Create-SqlServerCertificate{
    param(
        [Parameter(Mandatory=$true)]
        [Alias("CN")]
        [string]
        $CommonName,

        [Parameter(Mandatory=$true)]
        [string]
        $DnsName,

        [Parameter(Mandatory=$true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $SignerCertificate,

        [Parameter()]
        [System.DateTimeOffset]
        $NotBefore = [System.DateTimeOffset]::Now,

        [Parameter()]
        [System.DateTimeOffset]
        $NotAfter = [System.DateTimeOffset]::Now.AddDays(3285)
    )

    Write-Information -MessageData "Creating a certificate for SqlServer with '$($SignerCertificate.Thumbprint)' signer." -InformationAction Continue

    $certificateParams = @{
        Type = "SSLServerAuthentication"
        Subject = "CN=$CommonName"
        DnsName = @($DnsName, 'localhost')
        KeyAlgorithm = "RSA"
        KeyLength = 2048
        HashAlgorithm = "SHA256"
        TextExtension = "2.5.29.37={text}1.3.6.1.5.5.7.3.1"
        NotBefore = $NotBefore.DateTime
        NotAfter = $NotAfter.DateTime
        KeySpec = "KeyExchange"
        Provider = "Microsoft RSA SChannel Cryptographic Provider"
        Signer = $SignerCertificate
        FriendlyName = "Sitecore Container Development Sql Server Certificate"
    };

    $certificate = New-SelfSignedCertificate @certificateParams

    return $certificate
}
