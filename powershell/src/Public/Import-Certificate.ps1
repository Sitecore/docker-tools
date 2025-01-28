Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Imports a loaded certificate into a specified store.
.DESCRIPTION
    Imports a loaded certificate into the specified certificate store and location.
.PARAMETER Certificate
    The certificate to be imported.
.PARAMETER StoreName
    The name of the store where the certificate will be imported.
.PARAMETER StoreLocation
    The location of the store where the certificate will be imported.
.INPUTS
    None. You cannot pipe objects to Import-LoadedCertificate.
.OUTPUTS
    None. Import-LoadedCertificate does not generate any output.
.EXAMPLE
   PS C:\> Import-LoadedCertificate -Certificate $cert -StoreName "My" -StoreLocation "CurrentUser"
#>
function Import-LoadedCertificate {
    param(
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        [Parameter(Mandatory = $true)]
        [string]
        $StoreName,

        [Parameter(Mandatory = $true)]
        $StoreLocation
    )

    Write-Information -MessageData "Importing '$($Certificate.Thumbprint)' certificate into '$StoreName' store of '$StoreLocation' location." -InformationAction Continue

    $store = [System.Security.Cryptography.X509Certificates.X509Store]::new($StoreName, $StoreLocation)

    try {
        $store.Open("ReadWrite")
        $store.Add($Certificate)
    }
    finally {
        $store.Close()
    }
}

<#
.SYNOPSIS
    Imports a certificate for signing.
.DESCRIPTION
    Imports a certificate into the specified certificate store for signing purposes.
.PARAMETER SignerCertificate
    The certificate to be imported as signer.
.PARAMETER SignerCertificatePassword
    The password for the certificate to be imported as signer.
.INPUTS
    None. You cannot pipe objects to Import-CertificateForSigning.
.OUTPUTS
    System.Security.Cryptography.X509Certificates.X509Certificate2. The imported signer certificate.
.EXAMPLE
    PS C:\> Import-CertificateForSigning -SignerCertificate $cert -SignerCertificatePassword $password
#>
function Import-CertificateForSigning{
    param(
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $SignerCertificate,

        [Parameter(Mandatory = $true)]
        [SecureString]$SignerCertificatePassword
    )

    Write-Information -MessageData "Importing '$($SignerCertificate.Thumbprint)' certificate for signing." -InformationAction Continue

    $pfxContent = $SignerCertificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx, $SignerCertificatePassword)

    $importCertificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
        $pfxContent,
        $SignerCertificatePassword,
        [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::UserKeySet -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet
    )

    Import-LoadedCertificate -Certificate $importCertificate -StoreName "My" -StoreLocation "CurrentUser"

	return $importCertificate
}