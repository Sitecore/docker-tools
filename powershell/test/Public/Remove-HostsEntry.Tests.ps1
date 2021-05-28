. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    $windir = $env:windir

    Describe 'Remove-HostsEntry' {

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
            $result = Test-ParamIsMandatory -Command Remove-HostsEntry -Parameter HostName
            $result | Should Be $true
        }

        It 'throws if $HostName is $null or empty' {
            { Remove-HostsEntry -HostName $null } | Should -Throw
            { Remove-HostsEntry -HostName "" } | Should -Throw
        }

        Context 'Default $Path' {
            Mock Test-Path { $false }

            It 'uses hosts file in system32' {
                $expected = Join-Path -Path $env:windir -ChildPath "system32\drivers\etc\hosts"

                Remove-HostsEntry -HostName "somehost"

                Assert-MockCalled Test-Path -Times 1 -Exactly -ParameterFilter {
                    $Path -eq $expected
                } -Scope It
            }
        }

        Context 'Missing hosts file' {
            Mock Test-Path { $false }

            It 'writes warning' {
                Mock Write-Warning

                Remove-HostsEntry -HostName "somehost"

                Assert-MockCalled Write-Warning -Times 1 -Exactly -ParameterFilter {
                    $Message -eq 'No hosts file found, hosts have not been updated'
                } -Scope It
            }
        }

        Context 'Encoding' {
            Mock WriteLines
            Mock Get-Content {
                return @("10.10.10.10`tsomehost")
            }

            It 'reads as UTF8' {
                Remove-HostsEntry -Path $hostsPath -HostName 'somehost'

                Assert-MockCalled Get-Content -Times 1 -Exactly -ParameterFilter {
                    $Path -eq $hostsPath -and `
                    ($Encoding.ToString() -eq "System.Text.UTF8Encoding" -or $Encoding.ToString() -eq "UTF8")
                } -Scope It
            }

            It 'writes as UTF8' {
                Remove-HostsEntry -Path $hostsPath -HostName 'somehost'

                Assert-MockCalled WriteLines -Times 1 -Exactly -ParameterFilter {
                    $File -eq $hostsPath -and `
                    ($Encoding.ToString() -eq "System.Text.UTF8Encoding+UTF8EncodingSealed" -or $Encoding.ToString() -eq "System.Text.UTF8Encoding")
                } -Scope It
            }
        }

        Context 'When the hosts file is empty' {
            Mock Get-Content {
                return $null
            } -ParameterFilter { $Path -eq $hostsPath -and ($Encoding.ToString() -eq "System.Text.UTF8Encoding" -or $Encoding.ToString() -eq "UTF8")}

            Mock WriteLines

            Remove-HostsEntry -Path $hostsPath -HostName "hostName1"

            It 'does not update the hosts file' {
                Assert-MockCalled WriteLines -Times 0 -Exactly -ParameterFilter {
                    $File -eq $hostsPath
                }
            }
        }

        Context 'When the hosts file contains only comments' {
            Mock Get-Content {
                return @("# Hosts file comment")
            } -ParameterFilter { $Path -eq $hostsPath -and ($Encoding.ToString() -eq "System.Text.UTF8Encoding" -or $Encoding.ToString() -eq "UTF8")}

            Mock WriteLines

            Remove-HostsEntry -Path $hostsPath -HostName "hostName1"

            It 'does not update the hosts file' {
                Assert-MockCalled WriteLines -Times 0 -Exactly -ParameterFilter {
                    $File -eq $hostsPath
                }
            }
        }

        Context 'When there are no matching host headers in the host file' {
            Mock Get-Content {
                return @("10.10.10.10`thostName1", "20.20.20.20`thostName2", "30.30.30.30`thostName3")
            } -ParameterFilter { $Path -eq $hostsPath -and ($Encoding.ToString() -eq "System.Text.UTF8Encoding" -or $Encoding.ToString() -eq "UTF8")}

            Mock WriteLines

            Remove-HostsEntry -Path $hostsPath -HostName "hostName4"

            It 'does not update the hosts file' {
                Assert-MockCalled WriteLines -Times 0 -Exactly -ParameterFilter {
                    $File -eq $hostsPath
                }
            }
        }

        Context 'When there is single host header in the hosts file' {
            Mock Get-Content {
                return @("10.10.10.10`thostName1")
            } -ParameterFilter { $Path -eq $hostsPath -and ($Encoding.ToString() -eq "System.Text.UTF8Encoding" -or $Encoding.ToString() -eq "UTF8")}

            Mock WriteLines

            Remove-HostsEntry -Path $hostsPath -HostName "hostName1"

            It 'removes given host header' {

                Assert-MockCalled WriteLines -Times 1 -Exactly -ParameterFilter {
                    $File -eq $hostsPath -and `
                    $Content -eq $null -and `
                    ($Encoding.ToString() -eq "System.Text.UTF8Encoding+UTF8EncodingSealed" -or $Encoding.ToString() -eq "System.Text.UTF8Encoding")
                }
            }
        }

        Context 'When there are single host header and comment in the hosts file' {
            Mock Get-Content {
                return @("# Hosts file comment", "10.10.10.10`thostName1")
            } -ParameterFilter { $Path -eq $hostsPath -and ($Encoding.ToString() -eq "System.Text.UTF8Encoding" -or $Encoding.ToString() -eq "UTF8")}

            Mock WriteLines

            Remove-HostsEntry -Path $hostsPath -HostName "hostName1"

            It 'removes given host header' {
                Assert-MockCalled WriteLines -Times 1 -Exactly -ParameterFilter {
                    $File -eq $hostsPath -and `
                    @(Compare-Object -ReferenceObject @("# Hosts file comment") -DifferenceObject $Content).Count -eq 0 -and `
                    ($Encoding.ToString() -eq "System.Text.UTF8Encoding+UTF8EncodingSealed" -or $Encoding.ToString() -eq "System.Text.UTF8Encoding")
                }
            }
        }

        Context 'When there are multiple host headers in the hosts file' {
            Mock Get-Content {
                return @("10.10.10.10`thostName1", "20.20.20.20`thostName2", "30.30.30.30`thostName3")
            } -ParameterFilter { $Path -eq $hostsPath -and ($Encoding.ToString() -eq "System.Text.UTF8Encoding" -or $Encoding.ToString() -eq "UTF8")}

            Mock WriteLines

            Remove-HostsEntry -Path $hostsPath -HostName "hostName2"

            It 'removes given host header' {
                Assert-MockCalled WriteLines -Times 1 -Exactly -ParameterFilter {
                    $File -eq $hostsPath -and `
                    @(Compare-Object -ReferenceObject @("10.10.10.10`thostName1", "30.30.30.30`thostName3") -DifferenceObject $Content).Count -eq 0 -and `
                    ($Encoding.ToString() -eq "System.Text.UTF8Encoding+UTF8EncodingSealed" -or $Encoding.ToString() -eq "System.Text.UTF8Encoding")
                }
            }
        }
    }
}