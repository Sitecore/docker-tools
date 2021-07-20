. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'Create-RSA key' {
        It 'Valid length provided' {
            { Create-RSAKey -KeyLength 4096 } | Should -Not -Throw
        }

        It 'Invalid key length' {
           { Create-RSAKey -KeyLength 10 } | Should -Throw
        }

        It 'No key length provided' {
            { Create-RSAKey } | Should -Not -Throw
        }
    }

    Describe 'New-AuthorityKeyIdentifier' {
        It 'Requires $SubjectKeyIdentifier' {
            $result = Test-ParamIsMandatory -Command "New-AuthorityKeyIdentifier" -Parameter "SubjectKeyIdentifier"
            $result | Should -Be $true
        }

        It 'Optional authority parameters not provided' {
            $key = Create-RSAKey -KeyLength 4096
            $subject = "CN=localhost"
            $certRequest = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
                $subject,
                $key,
                [System.Security.Cryptography.HashAlgorithmName]::SHA256,
                [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
            $subjectKeyIdentifier = [System.Security.Cryptography.X509Certificates.X509SubjectKeyIdentifierExtension]::new(
                $certRequest.PublicKey,
                <# critical #> $false)

            { New-AuthorityKeyIdentifier -SubjectKeyIdentifier $subjectKeyIdentifier} | Should -Not -Throw
        }
    }

    Describe 'Create-SelfSignedCertificate' {
        It 'Requires $Key' {
            $result = Test-ParamIsMandatory -Command "Create-SelfSignedCertificate" -Parameter "Key"
            $result | Should -Be $true
        }

        It 'Optional parameters not provided' {
            $key = Create-RSAKey -KeyLength 4096

            { Create-SelfSignedCertificate -Key $key } | Should -Not -Throw
        }

        Context 'Create self signed with proper params' {
            BeforeAll {
                $key = Create-RSAKey -KeyLength 4096
                $startDate = [System.DateTimeOffset]::Now
                $endDate = [System.DateTimeOffset]::Now.AddDays(10)

                $result = Create-SelfSignedCertificate -Key $key -CommonName "Sitecore-test" -Country "UA" -Organization "Sitecore" -NotBefore $startDate -NotAfter $endDate
            }

            It 'Generate self signed certificate with private key' {
                $result.HasPrivateKey | Should -Be $true
            }
    
            It 'Generate self signed certificate with proper subject' {
                $result.Subject | Should -Match "CN=Sitecore-test, C=UA, O=Sitecore"
            }
    
            It 'Generate self signed certificate with correct start date' {
                $result.NotBefore.Date | Should -Match $startDate.Date
            }
    
            It 'Generate self signed certificate with correct end date' {    
                $result.NotAfter.Date | Should -Match $endDate.Date
            }
        }

        Context "Internal methods called" {
            Mock New-AuthorityKeyIdentifier

            $key = Create-RSAKey -KeyLength 4096
            Create-SelfSignedCertificate -Key $key
            
            It 'Authority key identifier called' {
                Assert-MockCalled New-AuthorityKeyIdentifier -Times 1 -Exactly
            }
        }
    }

    Describe 'Create-SelfSignedCertificateWithSignature' {
        It 'Requires $Key for signed certificate' {
            $result = Test-ParamIsMandatory -Command "Create-SelfSignedCertificateWithSignature" -Parameter "Key"
            $result | Should -Be $true
        }

        It 'Requires $RootCertificate for signed certificate' {
            $result = Test-ParamIsMandatory -Command "Create-SelfSignedCertificateWithSignature" -Parameter "RootCertificate"
            $result | Should -Be $true
        }

        It 'Optional parameters not provided for signed certificate' {
            $rootKey = Create-RSAKey -KeyLength 4096
            $rootCert = Create-SelfSignedCertificate -Key $rootKey
            $signedKey = Create-RSAKey -KeyLength 2048

            { Create-SelfSignedCertificateWithSignature -Key $signedKey -RootCertificate $rootCert } | Should -Not -Throw
        }

        Context "Create certificate with singature" {
            BeforeAll {
                $rootKey = Create-RSAKey -KeyLength 4096
                $rootCert = Create-SelfSignedCertificate -Key $rootKey
                $signedKey = Create-RSAKey -KeyLength 2048
                $startDate = [System.DateTimeOffset]::Now
                $endDate = [System.DateTimeOffset]::Now.AddDays(10)

                $result = Create-SelfSignedCertificateWithSignature -Key $signedKey -RootCertificate $rootCert -CommonName "Sitecore-signed" -Country "UA" -Organization "Sitecore" -NotBefore $startDate -NotAfter $endDate
            }
            
            It 'Generate self signed certificate with signature and private key' {
                $result.HasPrivateKey | Should -Be $false
            }

            It 'Generate self signed certificate with signature and proper subject' {
                $result.Subject | Should -Match "CN=Sitecore-signed, C=UA, O=Sitecore"
            }

            It 'Generate self signed certificate with signature and correct start date' {
                $result.NotBefore.Date | Should -Match $startDate.Date
            }

            It 'Generate self signed certificate with signature and correct end date' {
                $result.NotAfter.Date | Should -Match $endDate.Date
            }
        }
    }

    Describe 'Create-CertificateFile' {
        It 'Requires $Certificate' {
            $result = Test-ParamIsMandatory -Command "Create-CertificateFile" -Parameter "Certificate"
            $result | Should -Be $true
        }

        It 'Certificate file should not be empty' {  
            $outCertPath = "$TestDrive\localhost.crt"
            $key = Create-RSAKey -KeyLength 4096
            $certificate = Create-SelfSignedCertificate -Key $key
            Create-CertificateFile -Certificate $certificate -OutCertPath $outCertPath
                    
            (Get-Item $outCertPath).Length | Should -Not -BeNullOrEmpty
        }

        Context "Certificate file created properly" {
            $outCertPath = "$TestDrive\localhost.crt"
            $key = Create-RSAKey -KeyLength 4096
            $certificate = Create-SelfSignedCertificate -Key $key
            Create-CertificateFile -Certificate $certificate -OutCertPath $outCertPath

            It 'Certificate file should not be empty' {         
                (Get-Item $outCertPath).Length | Should -Not -BeNullOrEmpty
            }

            It 'Certificate file should contain entry message' {          
                Get-Content $outCertPath | Should -Contain "-----BEGIN CERTIFICATE-----"
            }
    
            It 'Certificate file should contain end message' {        
                Get-Content $outCertPath | Should -Contain "-----END CERTIFICATE-----"
            }
        }

        Context "Write host called for certificate file" {
            Mock Write-Host

            $key = Create-RSAKey -KeyLength 4096
            $certificate = Create-SelfSignedCertificate -Key $key
            Create-CertificateFile -Certificate $certificate -OutCertPath $TestDrive\localhost.crt
            
            It 'Authority key identifier called' {
                Assert-MockCalled Write-Host -Times 1 -Exactly
            }
        }
    }

    Describe 'Create-KeyFile' {
        It 'Requires $Key' {
            $result = Test-ParamIsMandatory -Command "Create-KeyFile" -Parameter "Key"
            $result | Should -Be $true
        }
        Context "Key file created properly" {
            $outKeyPath = "$TestDrive\localhost.key"
            $key = Create-RSAKey -KeyLength 4096
            Create-KeyFile -Key $key -OutKeyPath $outKeyPath

            It 'Key file should not be empty' {       
                (Get-Item $outKeyPath).Length | Should -Not -BeNullOrEmpty
            }
    
            It 'Key file should contain entry message' {
                (Get-Content $outKeyPath) | Should -Contain "-----BEGIN PRIVATE KEY-----"
            }
    
            It 'Key file should contain end message' {
                (Get-Content $outKeyPath) | Should -Contain "-----END PRIVATE KEY-----"
            }
        }

        Context "Write host called for key file" {
            Mock Write-Host

            $key = Create-RSAKey -KeyLength 4096
            Create-KeyFile -Key $key -OutKeyPath $TestDrive\localhost.key
            
            It 'Authority key identifier called' {
                Assert-MockCalled Write-Host -Times 1 -Exactly
            }
        }
    }
}