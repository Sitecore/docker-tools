. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'Load-Certificate' {
        BeforeAll {
            # Generate a self-signed certificate with password
            $certPath = Join-Path -Path $TestDrive -ChildPath "certificate.pfx"
            $certificate = New-SelfSignedCertificate -DnsName "mockCertificate" -CertStoreLocation "Cert:\CurrentUser\My"
            $certPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
            Export-PfxCertificate -Cert "Cert:\CurrentUser\My\$($certificate.Thumbprint)" -FilePath $certPath -Password $certPassword

            # Generate a self-signed certificate without password
            $certWithoutPasswordPath = Join-Path -Path $TestDrive -ChildPath "certificateWithoutPassword.pfx"
            $certificateWithoutPassword = New-SelfSignedCertificate -DnsName "mockCertificate" -CertStoreLocation "Cert:\CurrentUser\My"
            Export-PfxCertificate -Cert "Cert:\CurrentUser\My\$($certificateWithoutPassword.Thumbprint)" -FilePath $certWithoutPasswordPath -Password (New-Object System.Security.SecureString)
        }

        AfterAll {
            if ($certificate -ne $null) {
                Remove-Item -Path $certificate.PSPath -Force
            }
            if ($certificateWithoutPassword -ne $null) {
                Remove-Item -Path $certificateWithoutPassword.PSPath -Force
            }
        }

        It 'requires $CertPath' {
            $result = Test-ParamIsMandatory -Command Load-Certificate -Parameter CertPath
            $result | Should -Be $true
        }

        It 'throws if $CertPath is $null or empty' {
            { Load-Certificate -CertPath $null } | Should -Throw
            { Load-Certificate -CertPath "" } | Should -Throw
        }

        It 'throws if $CertPath is $null or empty' {
            { Load-Certificate -CertPath $null } | Should -Throw
            { Load-Certificate -CertPath "" } | Should -Throw
        }

        Context 'When loading a certificate with a password' {
            It 'Should load the certificate successfully' {
                # Act
                $cert = Load-Certificate -CertPath $certPath -CertPassword $certPassword

                # Assert
                $cert | Should -BeOfType "System.Security.Cryptography.X509Certificates.X509Certificate2"
            }
        }

        Context 'When loading a certificate without a password' {
            It 'Should load the certificate successfully' {
                # Arrange
                $certWithoutPasswordPath = Join-Path -Path $TestDrive -ChildPath "certificateWithoutPassword.pfx"
                Export-PfxCertificate -Cert "Cert:\CurrentUser\My\$($certificate.Thumbprint)" -FilePath $certWithoutPasswordPath -Password (New-Object System.Security.SecureString)

                # Act
                $cert = Load-Certificate -CertPath $certWithoutPasswordPath

                # Assert
                $cert | Should -BeOfType "System.Security.Cryptography.X509Certificates.X509Certificate2"
            }
        }

        Context 'When the certificate path is invalid' {
            It 'Should throw an error' {
                # Arrange
                $invalidCertPath = Join-Path -Path $TestDrive -ChildPath "invalid\path\to\certificate.pfx"

                # Act & Assert
                { Load-Certificate -CertPath $invalidCertPath } | Should -Throw
            }
        }

        Context 'When the certificate password is incorrect' {
            It 'Should throw an error' {
                # Arrange
                $wrongPassword = ConvertTo-SecureString -String "wrongpassword" -AsPlainText -Force

                # Act & Assert
                { Load-Certificate -CertPath $certPath -CertPassword $wrongPassword } | Should -Throw
            }
        }
    }
}