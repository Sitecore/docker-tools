. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'Set-SitecoreLicenseEnvironmentVariable' {

        BeforeAll {
            Remove-Item env:SITECORE_LICENSE -ErrorAction SilentlyContinue

            $licensePath = Join-Path $TestDrive 'license.xml'
            Set-Content $licensePath -Value '<?xml version="1.0" encoding="utf-8"?><license>Lorem ipsum dolor sit amet.</license>'

            Mock SetEnvironmentVariable {}
        }

        AfterEach {
            Remove-Item env:SITECORE_LICENSE -ErrorAction SilentlyContinue
        }

        It 'requires $LicensePath or $LicenseStream' {
            $result = Test-ParamIsMandatory -Command Set-SitecoreLicenseEnvironmentVariable -Parameter LicensePath -SetName 'FromPath'
            $result | Should Be $true
            $result = Test-ParamIsMandatory -Command Set-SitecoreLicenseEnvironmentVariable -Parameter LicenseStream -SetName 'FromStream'
            $result | Should Be $true
        }

        It 'restricts $Target to limited set' {
            $result = Test-ParamValidateSet -Command Set-SitecoreLicenseEnvironmentVariable -Parameter Target -Values 'Machine','User'
            $result | Should Be $true
        }

        It 'throws if $LicensePath is $null' {
            { Set-SitecoreLicenseEnvironmentVariable -LicensePath $null } | Should Throw
        }

        It 'throws if $LicensePath is empty' {
            { Set-SitecoreLicenseEnvironmentVariable -LicensePath "" } | Should Throw
        }

        It 'throws if $LicensePath is invalid' {
            { Set-SitecoreLicenseEnvironmentVariable -LicensePath "NO:\\NO" } | Should Throw
        }

        It 'throws if $LicensePath is a folder' {
            { Set-SitecoreLicenseEnvironmentVariable -LicensePath $TestDrive } | Should Throw
        }

        Context 'when license is invalid' {
            Mock ConvertTo-CompressedBase64String { return 'invalid' }

            It 'throws if compressed string is less than 100 characters' {
                { Set-SitecoreLicenseEnvironmentVariable -LicensePath $licensePath } | Should Throw
            }
        }

        Context 'when license is valid' {
            $licenseString = "jWyHbAjjPx5b9TMRYkYsMGsrcLXsYKH4awm6mn5kQYMzVLznGmx6QLwtg9qHqsXbKUUvFcwNvZWMsxhD2FKWyLmrukeYnZTR6ruFjGXt6RdvBauZ4dSW5kMwdNLyMc9Y"
            Mock ConvertTo-CompressedBase64String { return $licenseString }.GetNewClosure()

            It 'sets environment variable from $LicensePath' {
                Set-SitecoreLicenseEnvironmentVariable -LicensePath $licensePath

                Assert-MockCalled ConvertTo-CompressedBase64String -ParameterFilter { $LicensePath -eq $licensePath }
                Assert-MockCalled SetEnvironmentVariable -ParameterFilter { $Variable -eq "SITECORE_LICENSE" -and $Value -eq $licenseString }
            }

            It 'sets environment variable from $LicenseStream' {
                $stream = [System.IO.File]::OpenRead($licensePath)
                $stream | Set-SitecoreLicenseEnvironmentVariable
                $stream.Dispose()

                Assert-MockCalled ConvertTo-CompressedBase64String -ParameterFilter { $Stream -eq $stream }
                Assert-MockCalled SetEnvironmentVariable -ParameterFilter { $Variable -eq "SITECORE_LICENSE" -and $Value -eq $licenseString }
            }

            It 'persists environment variable for current session' {
                Set-SitecoreLicenseEnvironmentVariable -LicensePath $licensePath
                $env:SITECORE_LICENSE | Should Be $licenseString
            }

            It 'uses Machine as default $Target' {
                Set-SitecoreLicenseEnvironmentVariable -LicensePath $licensePath
                Assert-MockCalled SetEnvironmentVariable -ParameterFilter { $Target -eq "Machine" }
            }

            It "uses specified target '<target>'" -TestCases @(
                @{ target = 'Machine' },
                @{ target = 'User' }
            ) {
                param($target)
                Set-SitecoreLicenseEnvironmentVariable -LicensePath $licensePath -Target $target
                Assert-MockCalled SetEnvironmentVariable -ParameterFilter { $Target -eq $target }
            }
        }
    }
}