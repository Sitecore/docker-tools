. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'Create-PfxFile' {
        $certPath = Join-Path -Path $TestDrive -ChildPath "certificate.pfx"
        $certPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force

        BeforeAll {
            $certificate = New-SelfSignedCertificate -DnsName "mockCertificate" -CertStoreLocation "Cert:\CurrentUser\My"
        }

        AfterAll {
            if ($certificate -ne $null) {
                Remove-Item -Path $certificate.PSPath -Force
            }
        }

        It 'requires $Certificate and $OutCertPath and $Password'  {
            $result = Test-ParamIsMandatory -Command Create-PfxFile -Parameter Certificate
            $result | Should Be $true
            $result = Test-ParamIsMandatory -Command Create-PfxFile -Parameter OutCertPath
            $result | Should Be $true
            $result = Test-ParamIsMandatory -Command Create-PfxFile -Parameter Password
            $result | Should Be $true
        }

        It 'throws if $Certificate is $null' {
            { Create-PfxFile -Certificate $null } | Should -Throw
        }

        It 'throws if $OutCertPath is $null' {
            { Create-PfxFile -OutCertPath $null } | Should -Throw
        }

        It 'throws if $Password is $null' {
            { Create-PfxFile -Password $null } | Should -Throw
        }

        Context 'When exporting a certificate to a PFX file' {
            It 'Should export the certificate successfully' {
                # Act
                Create-PfxFile -Certificate $certificate -OutCertPath $certPath -Password $certPassword

                # Assert
                Test-Path $certPath | Should -Be $true
                $exportedContent = [System.IO.File]::ReadAllBytes($certPath)
                $exportedContent.Length | Should -BeGreaterThan 0
            }
        }

        Context 'When the certificate is invalid' {
            It 'Should throw an error' {
                # Arrange
                $invalidCertificate = $null

                # Act & Assert
                { Create-PfxFile -Certificate $invalidCertificate -OutCertPath $certPath -Password $certPassword } | Should -Throw
            }
        }

        Context 'When the output path is invalid' {
            It 'Should throw an error' {
                # Arrange
                $invalidCertPath = Join-Path -Path $TestDrive -ChildPath "invalid\path\to\certificate.pfx"

                # Act & Assert
                { Create-PfxFile -Certificate $certificate -OutCertPath $invalidCertPath -Password $certPassword } | Should -Throw
            }
        } 
    }
}