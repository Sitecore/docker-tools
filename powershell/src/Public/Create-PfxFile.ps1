Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Exports a certificate to a PFX file.
.DESCRIPTION
    Exports the specified certificate to a PFX file at the given path, using the provided password to protect the PFX file.
.PARAMETER Certificate
    The certificate to be exported.
.PARAMETER OutCertPath
    The file path where the PFX file will be saved.
.PARAMETER Password
    The password to protect the PFX file.
.INPUTS
    None. You cannot pipe objects to Create-PfxFile.
.OUTPUTS
    None. Create-PfxFile does not generate any output.
.EXAMPLE
    PS C:\> $cert = Get-Item Cert:\CurrentUser\My\THUMBPRINT
    PS C:\> $password = ConvertTo-SecureString -String "password" -AsPlainText -Force
    PS C:\> Create-PfxFile -Certificate $cert -OutCertPath "C:\path\to\certificate.pfx" -Password $password
#>
function Create-PfxFile{
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        [Parameter(Mandatory = $true)]
        [string]$OutCertPath,

        [Parameter(Mandatory = $true)]
        [SecureString]$Password
    )

    Write-Information -MessageData "Exporting '$($Certificate.Thumbprint)' certificate into Pfx." -InformationAction Continue

    $pfxContent = $Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx, $Password)

    [System.IO.File]::WriteAllBytes($OutCertPath, $pfxContent)
}