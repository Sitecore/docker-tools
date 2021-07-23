Set-StrictMode -Version Latest

<#
.SYNOPSIS
Multifunctional script to work with self-signed certificate.

.DESCRIPTION
This script is able to create regular self signed certificates and also certificates for Trusted Authority (CA). It also can sign one self signed
certificate with another one. There is also methods to store certificates to physical file with .crt extension and private key to physical file
with .key extension. Requires powershell core.

.EXAMPLE
$rootKey = Create-RSAKey -KeyLength 4096
$rootCertificate = Create-SelfSignedCertificate -Key $rootKey
Create-CertificateFile -Certificate $rootCertificate -OutCertPath "<Path_to_folder>\RootCA.crt"

$dnsNames = @('dns1', 'dns2', 'dns3'...)

$dnsNames | ForEach-Object {
	$selfSignedKey = Create-RSAKey
	$certificate = Create-SelfSignedCertificateWithSignature -Key $selfSignedKey -CommonName $_ -DnsName $_ -RootCertificate $rootCertificate

	Create-KeyFile -Key $selfSignedKey -OutKeyPath "<Path_to_folder>\$_.key"
	Create-CertificateFile -Certificate $certificate -OutCertPath "<Path_to_folder>\$_.crt"
}
#>

# Class to represent a certificate distinguished name
# like "CN=com.contoso, C=US, O=Contoso Ltd".
# See https://docs.microsoft.com/en-us/windows/desktop/seccrypto/distinguished-name-fields.
class CertificateDistinguishedName
{
    # Name of a person or an object host name
    [ValidateNotNullOrEmpty()]
    [string]$CommonName

    # 2-character ISO country code
    [ValidateLength(2, 2)]
    [string]$Country

    # The name of the registering organization
    [string]$Organization

    # Format the distinguished name like 'CN="com.contoso"; C="US"'
    [string] Format()
    {
        return $this.Format(';', <# UseQuotes #> $true)
    }

    # Format the distinguished name with the given separator and quote usage setting
    [string] Format([char]$Separator, [bool]$UseQuotes)
    {
        $sb = [System.Text.StringBuilder]::new()

        if ($UseQuotes)
        {
            $sb.Append("CN=`"$($this.CommonName)`"")
        }
        else
        {
            $sb.Append("CN=$($this.CommonName)")
        }

        $fields = @{
            C = $this.Country
            O = $this.Organization
        }

        foreach ($field in 'C', 'O')
        {
            $val = $fields[$field]

            if (-not $val)
            {
                continue
            }

            $sb.Append($Separator)
            $sb.Append(" ")

            if ($UseQuotes)
            {
                $sb.Append("$field=`"$val`"")
            }
            else
            {
                $sb.Append("$field=$val")
            }
        }

        return $sb.ToString()
    }

    # Create a new X500DistinguishedName object from this certificate
    [X500DistinguishedName] AsX500DistinguishedName()
    {
        return [X500DistinguishedName]::new($this.Format())
    }
}

# Produce a new authority key identifier from the authority's subject key identifier
function New-AuthorityKeyIdentifier
{
    param(
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509SubjectKeyIdentifierExtension]
        $SubjectKeyIdentifier,

        [switch]
        $Critical = $false
    )

    # The canonical OID of an Authority Key Identifier
    $akiOid = "2.5.29.35"

    # AKI is not supported directly by .NET, we have to make our own
    # The ASN.1 rule we follow is:
    # AuthorityKeyId ::= SEQUENCE { keyIdentifier [0] IMPLICIT_OCTET_STRING }
    # Because nothing documents what that means in DER encoding:
    #  - SEQUENCE: 0x30 tag, then length in bytes up to 0x79
    #  - keyIdentifier: <a type hint, not encoded - equates to the [0] tag>
    #  - [0]: a context-specific tag (bit 8 = 1, bit 7 = 0) of value 0 (bits 6-1 = 0)
    #  - IMPLICIT_OCTECT_STRING: no 0x04 octet string tag, first byte is length in bytes up to 0x79, then the string content
    # Example:
    #    | SEQUENCE  | [0]  | IMPLICIT_OCTET_STRING | 0x01 0x02 0x03 0x04
    #    | 0x30 0x06 | 0x80 | 0x04                  | 0x01 0x02 0x03 0x04
    #   sequence ^ length       ^ octet string length
    #
    # For more information see:
    #  - Microsoft's resources on this: https://docs.microsoft.com/en-us/windows/desktop/seccertenroll/about-certificate-request-encoding
    #  - This helpful page: http://luca.ntop.org/Teaching/Appunti/asn1.html

    # Compose the key here
    # We could extract from the SKI's raw data, but the string is a safer bet
    $ski = $SubjectKeyIdentifier.SubjectKeyIdentifier
    $key = [System.Collections.Generic.List[byte]]::new()
    for ($i = 0; $i -lt $SubjectKeyIdentifier.SubjectKeyIdentifier.Length; $i += 2)
    {
        $x = $ski[$i] + $ski[$i+1]
        $b = [System.Convert]::ToByte($x, 16)
        [void]$key.Add($b)
    }

    # Ensure our assumptions about not having to encode too much are correct
    if ($key.Count + 2 -gt 0x79)
    {
        throw [System.InvalidOperationException] "Subject key identifier length is to high to encode: $($key.Count)"
    }

    [byte]$octetLength = $key.Count
    [byte]$sequenceLength = $octetLength+2

    [byte]$sequenceTag = 0x30
    [byte]$keyIdentifierTag = 0x80

    # Assemble the raw data
    [byte[]]$akiRawData = @($sequenceTag, $sequenceLength, $keyIdentifierTag, $octetLength) + $key

    # Construct the Authority Key Identifier extension
    return [System.Security.Cryptography.X509Certificates.X509Extension]::new(
        $akiOid,
        $akiRawData,
        $Critical)
}

# Copy a hashtable with all the falsy entries removed
# @{ x = 'x'; y = '' } -> @{ x = 'x' }
function Get-FalsyRemovedHashtable
{
    param([hashtable]$Hashtable)

    $outTable = @{}

    foreach ($key in $Hashtable.Keys)
    {
        if ($Hashtable[$key])
        {
            $outTable[$key] = $Hashtable[$key]
        }
    }

    return $outTable
}

<#
.SYNOPSIS
Creates a private key for self-signed certificate.

.PARAMETER KeyLength
The length of the key in bits.
#>
function Create-RSAKey {
	param(
        [Parameter()]
        [ValidateSet(2048, 4096)]
        [int]
        $KeyLength = 2048
    )

	return [System.Security.Cryptography.RSA]::Create($KeyLength)
}

<#
.SYNOPSIS
Creates a self-signed certificate for testing use.

.DESCRIPTION
Creates a self-signed certificate for testing usage in a
given format and using a given backend. Can be used as certificate for certification authority (CA).

.PARAMETER Key
Private key required to create certificate.

.PARAMETER CommonName
The common name of the certificate subject, e.g. "com.contoso" or "Jennifer McCallum".

.PARAMETER Country
The country of the certificate subject as a two-character ISO code, e.g. "US" or "GB".

.PARAMETER Organization
The organization to which the certificate subject belongs, e.g. "Contoso Ltd".

.PARAMETER ForCertificateAuthority
Specifies that the certificate is for a certification authority (CA).

.PARAMETER KeyUsage
What general usages the certificate will be used for.

.PARAMETER NotBefore
The time when the certificate becomes valid.

.PARAMETER NotAfter
The time when the certificate ceases to be valid.
#>
function Create-SelfSignedCertificate {
    param(
        [Parameter(Mandatory=$true)]
        [System.Security.Cryptography.RSA]
        $Key,

        [Parameter()]
        [Alias("CN")]
        [string]
        $CommonName = "Sitecore Docker Compose Development Self-Signed Authority",

        [Parameter()]
        [Alias("C")]
        [string]
        $Country = "US",

        [Parameter()]
        [Alias("O")]
        [string]
        $Organization = "Sitecore-Development",

        [Parameter()]
        [bool]
        $ForCertificateAuthority = $true,

        [Parameter()]
        [System.Security.Cryptography.X509Certificates.X509KeyUsageFlags[]]
        $KeyUsage = @('DigitalSignature', 'CrlSign', 'KeyCertSign'),

        [Parameter()]
        [System.DateTimeOffset]
        $NotBefore = [System.DateTimeOffset]::Now,

        [Parameter()]
        [System.DateTimeOffset]
        $NotAfter = [System.DateTimeOffset]::Now.AddDays(3652)
    )

    # Construct the subject name
    $subjectName = [CertificateDistinguishedName] (Get-FalsyRemovedHashtable -Hashtable @{
        CommonName = $CommonName
        Country = $Country
        Organization = $Organization
    })

    # Create the subject of the certificate
    $subject = $subjectName.AsX500DistinguishedName()

    # Create Certificate Request
    $certRequest = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
        $subject,
        $Key,
        [System.Security.Cryptography.HashAlgorithmName]::SHA256,
        [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)

    $extensions = [System.Collections.Generic.List[System.Security.Cryptography.X509Certificates.X509Extension]]::new()

    # Create Subject Key Identifier
    $subjectKeyIdentifier = [System.Security.Cryptography.X509Certificates.X509SubjectKeyIdentifierExtension]::new(
        $certRequest.PublicKey,
        <# critical #> $false)

    $extensions.Add($subjectKeyIdentifier)

    # Create Authority Key Identifier
    $authorityKeyIdentifier = New-AuthorityKeyIdentifier -SubjectKeyIdentifier $subjectKeyIdentifier
    $extensions.Add($authorityKeyIdentifier)

    # Create Basic Constraints
    $basicConstraints = [System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::new(
        <# certificateAuthority #> $ForCertificateAuthority,
        <# hasPathLengthConstraint #> $true,
        <# pathLengthConstraint #> 3,
        <# critical #> $true)
    $extensions.Add($basicConstraints)

    # Roll the key usage flags into a single value (since they are flags)
    $keyUsageFlags = [System.Security.Cryptography.X509Certificates.X509KeyUsageFlags]::None
    foreach ($keyUsageFlag in $KeyUsage)
    {
        $keyUsageFlags = $keyUsageFlags -bor $keyUsageFlag
    }

    # Create Key Usage
    $keyUsages = [System.Security.Cryptography.X509Certificates.X509KeyUsageExtension]::new(
        $keyUsageFlags,
        <# critical #> $true)
    $extensions.Add($keyUsages)

    foreach ($extension in $extensions)
    {
        $certRequest.CertificateExtensions.Add($extension)
    }

    # Create self signed certificate
    $cert = $certRequest.CreateSelfSigned($NotBefore, $NotAfter)

    return $cert
}

<#
.SYNOPSIS
Creates a self-signed certificate for testing use.

.DESCRIPTION
Creates a self-signed certificate for testing usage in a
given format and using a given backend and signed with another certificate.

.PARAMETER Key
Private key required to create certificate.

.PARAMETER CommonName
The common name of the certificate subject, e.g. "com.contoso" or "Jennifer McCallum".

.PARAMETER Country
The country of the certificate subject as a two-character ISO code, e.g. "US" or "GB".

.PARAMETER Organization
The organization to which the certificate subject belongs, e.g. "Contoso Ltd".

.PARAMETER DnsName
Specifies dns name the certificate will be used for.

.PARAMETER RootCertificate
The certificate which is used for signing self signed certificate.

.PARAMETER NotBefore
The time when the certificate becomes valid.

.PARAMETER NotAfter
The time when the certificate ceases to be valid.
#>
function Create-SelfSignedCertificateWithSignature {
    param(
        [Parameter(Mandatory=$true)]
        [System.Security.Cryptography.RSA]
        $Key,

        [Parameter()]
        [Alias("CN")]
        [string]
        $CommonName = "localhost",

        [Parameter()]
        [Alias("C")]
        [string]
        $Country = "US",

        [Parameter()]
        [Alias("O")]
        [string]
        $Organization = "Sitecore-Development",

        [Parameter()]
        [string]
        $DnsName = "localhost",

        [Parameter(Mandatory=$true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $RootCertificate,

        [Parameter()]
        [System.DateTimeOffset]
        $NotBefore = [System.DateTimeOffset]::Now,

        [Parameter()]
        [System.DateTimeOffset]
        $NotAfter = [System.DateTimeOffset]::Now.AddDays(3650)
    )

    # Construct the subject name
    $subjectName = [CertificateDistinguishedName] (Get-FalsyRemovedHashtable -Hashtable @{
        CommonName = $CommonName
        Country = $Country
        Organization = $Organization
    })

    # Create the subject of the certificate
    $subject = $subjectName.AsX500DistinguishedName()

    # Create Certificate Request
    $certRequest = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
        $subject,
        $Key,
        [System.Security.Cryptography.HashAlgorithmName]::SHA256,
        [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)

    # Create Subject Alternative name property
    $alternativeBuilder = [System.Security.Cryptography.X509Certificates.SubjectAlternativeNameBuilder]::new()
    $alternativeBuilder.AddDnsName($DnsName)
    $altBuilder = $alternativeBuilder.Build()
    $certRequest.CertificateExtensions.Add($altBuilder)

    $uniqueId = [System.BitConverter]::GetBytes([System.DateTime]::Now.ToBinary())

    # Create sertificate, signed by RootCA
    $cert = $certRequest.Create($RootCertificate, $NotBefore, $NotAfter, $uniqueId)

    return $cert
}

<#
.SYNOPSIS
Creates a physical file in .crt format for self-signed certificate for testing use.

.PARAMETER Certificate
The certificate for which physical file needs to be created.

.PARAMETER OutFilePath
The filepath to output the generated certificate to. File should have .crt extension.
#>
function Create-CertificateFile {
    param(
        [Parameter(Mandatory=$true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        [Parameter()]
        [string]
        $OutCertPath = $pwd
    )
    $content = @(
        '-----BEGIN CERTIFICATE-----'
        [System.Convert]::ToBase64String($Certificate.RawData, 'InsertLineBreaks')
        '-----END CERTIFICATE-----'
    )
    $content | Out-File -FilePath $OutCertPath -Encoding ascii

    Write-Host "Certificate is written to $OutCertPath"
}

<#
.SYNOPSIS
Creates a physical file in .key format for the private key.

.PARAMETER Key
Private key required to create certificate.

.PARAMETER OutKeyPath
The filepath to output the generated key to.
#>
function Create-KeyFile {
    param(
        [Parameter(Mandatory=$true)]
        [System.Security.Cryptography.RSA]
        $Key,

        [Parameter()]
        [string]
        $OutKeyPath = $pwd
    )
    $parameters = $Key.ExportParameters($true)
	$data = [RSAKeyUtils]::PrivateKeyToPKCS8($parameters)

    $content = @(
	    '-----BEGIN PRIVATE KEY-----'
	    [System.Convert]::ToBase64String($data, 'InsertLineBreaks')
	    '-----END PRIVATE KEY-----'
	)
    $content | Out-File -FilePath $OutKeyPath -Encoding ascii

    Write-Host "Key is written to $OutKeyPath"
}