. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'Set-SitecoreLicenseEnvironmentFile' {

        BeforeAll {
            Remove-Item env:SITECORE_LICENSE -ErrorAction SilentlyContinue

            $envFilePath = Join-Path $TestDrive '.env'
            Set-Content $envFilePath -Value "FOO=bar"

            $licensePath = Join-Path $TestDrive 'license.xml'
            Set-Content $licensePath -Value '<?xml version="1.0" encoding="utf-8"?><license>Lorem ipsum dolor sit amet.</license>'

            Mock Set-EnvironmentFileVariable {}
        }

        AfterEach {
            Remove-Item env:SITECORE_LICENSE -ErrorAction SilentlyContinue
        }

        It 'requires $LicensePath or $LicenseStream' {
            $result = Test-ParamIsMandatory -Command Set-SitecoreLicenseEnvironmentFile -Parameter LicensePath -SetName 'FromPath'
            $result | Should -Be $true
            $result = Test-ParamIsMandatory -Command Set-SitecoreLicenseEnvironmentFile -Parameter LicenseStream -SetName 'FromStream'
            $result | Should -Be $true
        }

        It 'throws if $LicensePath is $null' {
            { Set-SitecoreLicenseEnvironmentFile -LicensePath $null } | Should -Throw
        }

        It 'throws if $LicensePath is empty' {
            { Set-SitecoreLicenseEnvironmentFile -LicensePath "" } | Should -Throw
        }

        It 'throws if $LicensePath is invalid' {
            { Set-SitecoreLicenseEnvironmentFile -LicensePath "NO:\\NO" } | Should -Throw
        }

        It 'throws if $LicensePath is a folder' {
            { Set-SitecoreLicenseEnvironmentFile -LicensePath $TestDrive } | Should -Throw
        }

        It 'throws if $EnvironmentFilePath is invalid' {
            { Set-SitecoreLicenseEnvironmentFile -EnvironmentFilePath $TestDrive } | Should -Throw
        }

        It 'throws if $EnvironmentFilePath is not a .env file' {
            $textFile = Join-Path $TestDrive 'test.txt'
            Set-Content $textFile -Value "Lorem ipsum dolor sit amet."

            { Set-SitecoreLicenseEnvironmentFile -EnvironmentFilePath $textFile } | Should -Throw
        }

        Context 'when license is invalid' {
            Mock ConvertTo-CompressedBase64String { return 'invalid' }

            It 'throws if compressed string is less than 100 characters' {
                { Set-SitecoreLicenseEnvironmentFile -LicensePath $licensePath } | Should -Throw
            }
        }

        Context 'when license is valid' {
            $licenseString = "jWyHbAjjPx5b9TMRYkYsMGsrcLXsYKH4awm6mn5kQYMzVLznGmx6QLwtg9qHqsXbKUUvFcwNvZWMsxhD2FKWyLmrukeYnZTR6ruFjGXt6RdvBauZ4dSW5kMwdNLyMc9Y"
            Mock ConvertTo-CompressedBase64String { return $licenseString }.GetNewClosure()

            It 'sets environment file from $LicensePath' {
                Set-SitecoreLicenseEnvironmentFile -LicensePath $licensePath -EnvironmentFilePath $envFilePath

                Assert-MockCalled ConvertTo-CompressedBase64String -ParameterFilter { $LicensePath -eq $licensePath }
                Assert-MockCalled Set-EnvironmentFileVariable -ParameterFilter { $Variable -eq "SITECORE_LICENSE" -and $Value -eq $licenseString -and $Path -eq $envFilePath }
            }

            It 'sets environment file from $LicenseStream' {
                $stream = [System.IO.File]::OpenRead($licensePath)
                $stream | Set-SitecoreLicenseEnvironmentFile -EnvironmentFilePath $envFilePath
                $stream.Dispose()

                Assert-MockCalled ConvertTo-CompressedBase64String -ParameterFilter { $Stream -eq $stream }
                Assert-MockCalled Set-EnvironmentFileVariable -ParameterFilter { $Variable -eq "SITECORE_LICENSE" -and $Value -eq $licenseString -and $Path -eq $envFilePath }
            }

            It 'persists environment variable for current session' {
                Set-SitecoreLicenseEnvironmentFile -LicensePath $licensePath -EnvironmentFilePath $envFilePath
                $env:SITECORE_LICENSE | Should -Be $licenseString
            }

            It 'uses $PSScriptRoot\.env as default $EnvironmentFilePath' {
                $tempFile = Join-Path $PSScriptRoot '.env'
                Set-Content $tempFile -Value "FOO=bar"
                Set-SitecoreLicenseEnvironmentFile -LicensePath $licensePath
                Remove-Item $tempFile

                Assert-MockCalled Set-EnvironmentFileVariable -ParameterFilter { $Path -eq $tempFile }
            }
        }
    }
}