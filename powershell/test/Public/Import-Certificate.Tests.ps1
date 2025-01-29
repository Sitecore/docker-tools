. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'Import-LoadedCertificate' {
        It 'requires $Certificate and $StoreName and $StoreLocation' {
            $result = Test-ParamIsMandatory -Command Import-LoadedCertificate -Parameter Certificate
            $result | Should Be $true
            $result = Test-ParamIsMandatory -Command Import-LoadedCertificate -Parameter StoreName
            $result | Should Be $true
            $result = Test-ParamIsMandatory -Command Import-LoadedCertificate -Parameter StoreLocation
            $result | Should Be $true
        }
    }

    Describe 'Import-CertificateForSigning' {
        It 'requires $SignerCertificate and $SignerCertificatePassword' {
            $result = Test-ParamIsMandatory -Command Import-CertificateForSigning -Parameter SignerCertificate
            $result | Should Be $true
            $result = Test-ParamIsMandatory -Command Import-CertificateForSigning -Parameter SignerCertificatePassword
            $result | Should Be $true
        }
    }
}
