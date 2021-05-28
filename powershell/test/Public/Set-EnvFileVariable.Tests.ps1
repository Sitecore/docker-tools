. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'Set-EnvFileVariable' {

        $envFile = Join-Path $TestDrive '.env'
        Set-Content $envFile -Value ''

        It 'requires $Variable' {
            $result = Test-ParamIsMandatory -Command Set-EnvFileVariable -Parameter Variable
            $result | Should -Be $true
        }

        It 'requires $Value' {
            $result = Test-ParamIsMandatory -Command Set-EnvFileVariable -Parameter Value
            $result | Should -Be $true
        }

        It 'throws if $Path is invalid' {
            { Set-EnvFileVariable -Variable "foo" -Value "bar" -Path "$TestDrive\.baz" } | Should -Throw
        }

        It 'throws if $Variable is $null or empty' {
            { Set-EnvFileVariable -Variable $null -Value "bar" -Path $envFile } | Should -Throw
            { Set-EnvFileVariable -Variable "" -Value "bar" -Path $envFile } | Should -Throw
        }

        It 'adds variable to empty file' {
            Set-Content $envFile -Value ''
            Set-EnvFileVariable -Path $envFile -Variable 'VAR' -Value 'VAL'
            $envFile | Should -FileContentMatchExactly '^VAR=VAL$'
        }

        It 'adds variable on new line to end of file' {
            Set-Content $envFile -Value 'VAR1=VAL1'
            Set-EnvFileVariable -Path $envFile -Variable 'VAR2' -Value 'VAL2'
            $envFile | Should -FileContentMatchMultiline '^VAR1=VAL1\r?\nVAR2=VAL2\r?\n$'
        }

        It 'sets existing variable with value to new value' {
            Set-Content $envFile -Value @(
                'VAR1=VAL1',
                'VAR2=VAL2',
                'VAR3=VAL3'
            )
            Set-EnvFileVariable -Path $envFile -Variable 'VAR2' -Value 'two'
            $envFile | Should -FileContentMatchExactly '^VAR2=two$'
        }

        It 'sets existing variable with value to empty' {
            Set-Content $envFile -Value @(
                'VAR1=VAL1',
                'VAR2=VAL2',
                'VAR3=VAL3'
            )
            Set-EnvFileVariable -Path $envFile -Variable 'VAR3' -Value ''
            $envFile | Should -FileContentMatchExactly '^VAR3=$'
        }

        It 'sets existing variable empty to value' {
            Set-Content $envFile -Value @(
                'VAR1=',
                'VAR2=VAL2',
                'VAR3=VAL3'
            )
            Set-EnvFileVariable -Path $envFile -Variable 'VAR1' -Value 'one'
            $envFile | Should -FileContentMatchExactly '^VAR1=one$'
        }

        It 'sets existing variable case insensitively' {
            Set-Content $envFile -Value @(
                'VAR1=VAL1',
                'VAR2=VAL2',
                'VAR3=VAL3'
            )
            Set-EnvFileVariable -Path $envFile -Variable 'var1' -Value 'one'
            $envFile | Should -FileContentMatchExactly '^var1=one$'
            $envFile | Should -Not -FileContentMatchExactly '^VAR1=VAL1$'
            $envFile | Should -Not -FileContentMatchExactly '^VAR1=one$'
        }

        It 'sets existing variable to value with RegEx substitution characters' {
            Set-Content $envFile -Value 'VAR=VAL'
            Set-EnvFileVariable -Path $envFile -Variable 'VAR' -Value 'a$&b$$c'
            $envFile | Should -FileContentMatch ([regex]::Escape('VAR=a$&b$$c'))
        }

        It 'preserves comments' {
            Set-Content $envFile -Value @(
                '#VAR1=VAL1',
                'VAR2=VAL2',
                'VAR3=VAL3'
            )
            Set-EnvFileVariable -Path $envFile -Variable 'VAR2' -Value 'two'
            $envFile | Should -FileContentMatchExactly '^#VAR1=VAL1$'
            $envFile | Should -FileContentMatchExactly '^VAR2=two$'
        }

        It 'adds variable when existing is commented' {
            Set-Content $envFile -Value @(
                '#VAR1=VAL1',
                'VAR2=VAL2',
                'VAR3=VAL3'
            )
            Set-EnvFileVariable -Path $envFile -Variable 'VAR1' -Value 'one'
            $envFile | Should -FileContentMatchExactly '^#VAR1=VAL1$'
            $envFile | Should -FileContentMatchExactly '^VAR1=one$'
        }

        It 'preserves blank lines' {
            Set-Content $envFile -Value @(
                'VAR1=VAL1',
                '',
                'VAR2=VAL2'
            )
            Set-EnvFileVariable -Path $envFile -Variable 'VAR2' -Value 'two'
            $envFile | Should -FileContentMatchExactly '^$'
            $envFile | Should -FileContentMatchExactly '^VAR2=two$'
        }

        It 'uses .\.env as default $Path' {
            Set-Content $envFile -Value "foo=bar"

            Push-Location $TestDrive
            Set-EnvFileVariable -Variable "foo" -Value "baz"
            Pop-Location

            $envFile | Should -FileContentMatchExactly '^foo=baz$'
        }

        It 'is aliased under old name Set-DockerComposeEnvFileVariable' {
            Set-Content $envFile -Value ''
            Set-DockerComposeEnvFileVariable -Path $envFile -Variable 'VAR' -Value 'VAL'
            $envFile | Should -FileContentMatchExactly '^VAR=VAL$'
        }

        Context 'Encoding' {
            Mock WriteLines
            Mock Get-Content

            It 'reads as UTF8' {
                Set-EnvFileVariable -Path $envFile -Variable 'VAR1' -Value 'one'

                Assert-MockCalled Get-Content -Times 1 -Exactly -ParameterFilter {
                    $Path -eq $envFile -and `
                    ($Encoding.ToString() -eq "System.Text.UTF8Encoding" -or $Encoding.ToString() -eq "UTF8")
                } -Scope It
            }

            It 'writes as UTF8' {
                Set-EnvFileVariable -Path $envFile -Variable 'VAR1' -Value 'one'

                Assert-MockCalled WriteLines -Times 1 -Exactly -ParameterFilter {
                    $File -eq $envFile -and `
                    ($Encoding.ToString() -eq "System.Text.UTF8Encoding+UTF8EncodingSealed" -or $Encoding.ToString() -eq "System.Text.UTF8Encoding")
                } -Scope It
            }
        }
    }
}