. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'Create-SqlServerCertificate' {
        BeforeAll {
            $certStoreLocation = "Cert:\CurrentUser\My"
            $signerCert = New-SelfSignedCertificate -DnsName "signer.test" -CertStoreLocation $certStoreLocation
        }

        AfterAll {
            if ($signerCert -ne $null) {
                Remove-Item -Path $signerCert.PSPath -Force
            }
        }

        It 'requires $CommonName and $DnsName and $SignerCertificate' {
            $result = Test-ParamIsMandatory -Command Create-SqlServerCertificate -Parameter CommonName
            $result | Should Be $true
            $result = Test-ParamIsMandatory -Command Create-SqlServerCertificate -Parameter DnsName
            $result | Should Be $true
            $result = Test-ParamIsMandatory -Command Create-SqlServerCertificate -Parameter SignerCertificate
            $result | Should Be $true
        }

        It 'Optional parameter not provided' {
            { Create-SqlServerCertificate -CommonName "test" -DnsName "test" -SignerCertificate $signerCert } | Should -Not -Throw
        }

        It 'throws if $CommonName is $null or empty' {
            { Create-SqlServerCertificate -CommonName $null -DnsName "test" -SignerCertificate $signerCert } | Should -Throw
            { Create-SqlServerCertificate -CommonName "" -DnsName "test" -SignerCertificate $signerCert } | Should -Throw
        }

        It 'throws if $DnsName is $null or empty' {
            { Create-SqlServerCertificate -CommonName "test" -DnsName $null -SignerCertificate $signerCert } | Should -Throw
            { Create-SqlServerCertificate -CommonName "test" -DnsName "" -SignerCertificate $signerCert } | Should -Throw
        }

        It 'throws if $SignerCertificate is $null' {
            { Create-SqlServerCertificate -CommonName "test" -DnsName "test" -SignerCertificate $null } | Should -Throw
        }

        Context 'When creating a self-signed certificate' {
            It 'creates a certificate with the specified parameters' {
                # Arrange
                $commonName = 'test.sql.server'
                $dnsName = 'test.sql.server'

                # Act
                $certificate = Create-SqlServerCertificate -CommonName $commonName -DnsName $dnsName -SignerCertificate $signerCert

                write-host $certificate

                # Assert
                $certificate | Should -Not -BeNullOrEmpty
                $certificate.Subject | Should -Be "CN=$commonName"
                $certificate.DnsNameList | Should -Contain $dnsName
                $certificate.DnsNameList | Should -Contain 'localhost'
                $certificate.Issuer | Should -Be $signerCert.Subject
            }
        }
    }
}
