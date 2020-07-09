. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    $windir = $env:windir

    Describe 'Add-HostsEntry' {

        $hostsPath = Join-Path -Path $TestDrive -ChildPath "system32\drivers\etc\hosts"
        New-Item ([io.Directory]::GetParent($hostsPath)) -ItemType Directory | Out-Null
        New-Item $hostsPath -ItemType File | Out-Null

        BeforeAll {
            $env:windir = $TestDrive
        }
        AfterAll {
            $env:windir = $windir
        }

        It 'requires $HostName' {
            $result = Test-ParamIsMandatory -Command Add-HostsEntry -Parameter HostName
            $result | Should Be $true
        }

        It 'throws if $HostName is $null or empty' {
            { Add-HostsEntry -HostName $null } | Should -Throw
            { Add-HostsEntry -HostName "" } | Should -Throw
        }

        It 'throws if $IPAddress is $null or empty' {
            { Add-HostsEntry -HostName "test" -IPAddress $null } | Should -Throw
            { Add-HostsEntry -HostName "test" -IPAddress "" } | Should -Throw
        }

        Context 'Default $Path' {
            Mock Test-Path { $false }

            It 'uses hosts file in system32' {
                $expected = Join-Path -Path $env:windir -ChildPath "system32\drivers\etc\hosts"

                Add-HostsEntry -HostName "somehost"

                Assert-MockCalled Test-Path -Times 1 -Exactly -ParameterFilter {
                    $Path -eq $expected
                } -Scope It
            }
        }

        Context 'Missing hosts file' {
            Mock Test-Path { $false }

            It 'writes warning' {
                Mock Write-Warning

                Add-HostsEntry -HostName "somehost"

                Assert-MockCalled Write-Warning -Times 1 -Exactly -ParameterFilter {
                    $Message -eq 'No hosts file found, hosts have not been updated'
                } -Scope It
            }
        }

        Context 'Encoding' {
            Mock WriteLines
            Mock Get-Content

            It 'reads as UTF8' {
                Add-HostsEntry -Path $hostsPath -HostName 'somehost' -IPAddress '10.10.10.10'

                Assert-MockCalled Get-Content -Times 1 -Exactly -ParameterFilter {
                    $Path -eq $hostsPath -and `
                    $Encoding -eq 'UTF8'
                } -Scope It
            }

            It 'writes as UTF8' {
                Add-HostsEntry -Path $hostsPath -HostName 'somehost' -IPAddress '10.10.10.10'

                Assert-MockCalled WriteLines -Times 1 -Exactly -ParameterFilter {
                    $File -eq $hostsPath -and `
                    $Encoding -eq [System.Text.Encoding]::UTF8
                } -Scope It
            }
        }

        Context 'When modifying' {
            Mock WriteLines

            It 'creates a backup before modifying' {
                Add-HostsEntry -Path $hostsPath -HostName 'somehost'
                Test-Path "$hostsPath.backup" | Should Be $true
            }

            It 'adds as 127.0.0.1 by default' {
                Add-HostsEntry -Path $hostsPath -HostName 'somehost'

                Assert-MockCalled WriteLines -Times 1 -Exactly -ParameterFilter {
                    $File -eq $hostsPath -and `
                    $Content -eq "127.0.0.1`tsomehost"
                } -Scope It
            }

            It 'adds with given ipaddress' {
                Add-HostsEntry -Path $hostsPath -HostName 'somehost' -IPAddress '10.10.10.10'

                Assert-MockCalled WriteLines -Times 1 -Exactly -ParameterFilter {
                    $File -eq $hostsPath -and `
                    $Content -eq "10.10.10.10`tsomehost"
                } -Scope It
            }
        }

        Context 'When modifying with existing hosts' {
            Mock WriteLines

            It 'does not throw when no entry in hosts exists' {
                Add-HostsEntry -Path $hostsPath -HostName 'somehost' -IPAddress '10.10.10.10'

                Assert-MockCalled WriteLines -Times 1 -Exactly -ParameterFilter {
                    $File -eq $hostsPath -and `
                    $Content -eq "10.10.10.10`tsomehost"
                } -Scope It
            }

            It 'does not throw when single entry in hosts exists' {
                Set-Content -Path $hostsPath -Value "`n127.0.0.1`tsomehost"
                Add-HostsEntry -Path $hostsPath -HostName 'somehost' -IPAddress '10.10.10.10'

                Assert-MockCalled WriteLines -Times 1 -Exactly -ParameterFilter {
                    $File -eq $hostsPath -and `
                    $Content -eq "10.10.10.10`tsomehost"
                } -Scope It
            }

            It 'adds only comments exist' {
                Set-Content -Path $hostsPath -Value "# Copyright  1993-2009 Microsoft Corp."
                Add-HostsEntry -Path $hostsPath -HostName 'somehost' -IPAddress '10.10.10.10'

                Assert-MockCalled WriteLines -Times 1 -Exactly -ParameterFilter {
                    $File -eq $hostsPath -and `
                    $Content -eq "10.10.10.10`tsomehost"
                } -Scope It
            }

            It 'is not added when default IP Address already exists for host' {
                Set-Content -Path $hostsPath -Value "`n127.0.0.1`tsomehost`n10.10.10.10`tsomehost"

                Add-HostsEntry -Path $hostsPath -HostName 'somehost' -IPAddress '10.10.10.10'

                Assert-MockCalled WriteLines -Times 0 -Exactly -ParameterFilter {
                    $File -eq $hostsPath -and `
                    $Content -eq "127.0.0.1`tsomehost"
                } -Scope It
            }

            It 'is not added when specific IP Address already exists for host' {
                Set-Content -Path $hostsPath -Value "`n127.0.0.1`tsomehost`n10.10.10.10`tsomehost"

                Add-HostsEntry -Path $hostsPath -HostName 'somehost'

                Assert-MockCalled WriteLines -Times 0 -Exactly -ParameterFilter {
                    $File -eq $hostsPath -and `
                    $Content -eq "127.0.0.1`tsomehost"
                } -Scope It
            }

            It 'is added when existing partial host exists' {
                Set-Content -Path $hostsPath -Value "`n127.0.0.1`tsomehost`n10.10.10.10`tsomehost"

                Add-HostsEntry -Path $hostsPath -HostName 'some'

                Assert-MockCalled WriteLines -Times 1 -Exactly -ParameterFilter {
                    $File -eq $hostsPath -and `
                    $Content -eq "127.0.0.1`tsome"
                } -Scope It
            }
        }
    }
}