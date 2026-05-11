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
                
        Context 'When creating a self-signed certificate with DEFAULT validity period' {
            It 'creates a certificate with the correct start and end dates' {
                # Arrange
                $commonName = 'test.sql.server'
                $dnsName = 'test.sql.server'

                # Act
                $certificate = Create-SqlServerCertificate -CommonName $commonName -DnsName $dnsName -SignerCertificate $signerCert

                # Assert
                $certificate | Should -Not -BeNullOrEmpty
                
                # Check default validity period
                $now = [System.DateTimeOffset]::Now
                
                $certificate.NotBefore | Should -BeGreaterThan ($now.DateTime.AddSeconds(-5))
                $certificate.NotBefore | Should -BeLessThan ($now.DateTime.AddSeconds(5))
                
                $certificate.NotAfter | Should -BeGreaterThan ($now.AddDays(3285).DateTime.AddSeconds(-5))
                $certificate.NotAfter | Should -BeLessThan ($now.AddDays(3285).DateTime.AddSeconds(5))
            }
        }

        Context 'When creating a self-signed certificate with CUSTOM validity period' {
            It 'creates a certificate with the correct start and end dates' {
                # Arrange
                $commonName = 'test.sql.server'
                $dnsName = 'test.sql.server'
                $notBefore = [System.DateTimeOffset]::UtcNow.AddDays(-1)
                $notAfter = [System.DateTimeOffset]::UtcNow.AddDays(365)

                # Act
                $certificate = Create-SqlServerCertificate -CommonName $commonName -DnsName $dnsName -SignerCertificate $signerCert -NotBefore $notBefore -NotAfter $notAfter

                # Assert
                $certificate | Should -Not -BeNullOrEmpty
                $certificate.NotBefore | Should -BeGreaterThan ($notBefore.DateTime.AddSeconds(-1))
                $certificate.NotAfter | Should -BeLessThan ($notAfter.DateTime.AddSeconds(1))
            }
        }
    }
}
