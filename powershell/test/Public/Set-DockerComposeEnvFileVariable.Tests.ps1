. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'Set-DockerComposeEnvFileVariable' {

        It 'requires $Variable' {
            $result = Test-ParamIsMandatory -Command Set-DockerComposeEnvFileVariable -Parameter Variable
            $result | Should -Be $true
        }

        It 'requires $Value' {
            $result = Test-ParamIsMandatory -Command Set-DockerComposeEnvFileVariable -Parameter Value
            $result | Should -Be $true
        }

        It 'throws if $Path is invalid' {
            { Set-DockerComposeEnvFileVariable -Variable "foo" -Value "bar" -Path $TestDrive } | Should -Throw
        }

        It 'throws if $Path is not a .env file' {
            $textFile = Join-Path $TestDrive 'test.txt'
            Set-Content $textFile -Value "Lorem ipsum dolor sit amet."

            { Set-DockerComposeEnvFileVariable -Variable "foo" -Value "bar" -Path $textFile } | Should -Throw
        }

        It 'throws if $Variable is $null or empty' {
            $envFile = 'TestDrive:\.env'
            Set-Content $envFile -Value ''
            { Set-DockerComposeEnvFileVariable -Variable $null -Value "bar" -Path $envFile } | Should -Throw
            { Set-DockerComposeEnvFileVariable -Variable "" -Value "bar" -Path $envFile } | Should -Throw
        }

        It 'adds variable to empty file' {
            $envFile = 'TestDrive:\.env'
            Set-Content $envFile -Value ''
            Set-DockerComposeEnvFileVariable -Path $envFile -Variable 'VAR' -Value 'VAL'
            $envFile | Should -FileContentMatchExactly '^VAR=VAL$'
        }

        It 'adds variable on new line to end of file' {
            $envFile = 'TestDrive:\.env'
            Set-Content $envFile -Value 'VAR1=VAL1'
            Set-DockerComposeEnvFileVariable -Path $envFile -Variable 'VAR2' -Value 'VAL2'
            $envFile | Should -FileContentMatchMultiline '^VAR1=VAL1\r\nVAR2=VAL2\r\n$'
        }

        It 'sets existing variable with value to new value' {
            $envFile = 'TestDrive:\.env'
            Set-Content $envFile -Value @(
                'VAR1=VAL1',
                'VAR2=VAL2',
                'VAR3=VAL3'
            )
            Set-DockerComposeEnvFileVariable -Path $envFile -Variable 'VAR2' -Value 'two'
            $envFile | Should -FileContentMatchExactly '^VAR2=two$'
        }

        It 'sets existing variable with value to empty' {
            $envFile = 'TestDrive:\.env'
            Set-Content $envFile -Value @(
                'VAR1=VAL1',
                'VAR2=VAL2',
                'VAR3=VAL3'
            )
            Set-DockerComposeEnvFileVariable -Path $envFile -Variable 'VAR3' -Value ''
            $envFile | Should -FileContentMatchExactly '^VAR3=$'
        }

        It 'sets existing variable empty to value' {
            $envFile = 'TestDrive:\.env'
            Set-Content $envFile -Value @(
                'VAR1=',
                'VAR2=VAL2',
                'VAR3=VAL3'
            )
            Set-DockerComposeEnvFileVariable -Path $envFile -Variable 'VAR1' -Value 'one'
            $envFile | Should -FileContentMatchExactly '^VAR1=one$'
        }

        It 'sets existing variable case insensitively' {
            $envFile = 'TestDrive:\.env'
            Set-Content $envFile -Value @(
                'VAR1=VAL1',
                'VAR2=VAL2',
                'VAR3=VAL3'
            )
            Set-DockerComposeEnvFileVariable -Path $envFile -Variable 'var1' -Value 'one'
            $envFile | Should -FileContentMatchExactly '^var1=one$'
            $envFile | Should -Not -FileContentMatchExactly '^VAR1=VAL1$'
            $envFile | Should -Not -FileContentMatchExactly '^VAR1=one$'
        }

        It 'preserves comments' {
            $envFile = 'TestDrive:\.env'
            Set-Content $envFile -Value @(
                '#VAR1=VAL1',
                'VAR2=VAL2',
                'VAR3=VAL3'
            )
            Set-DockerComposeEnvFileVariable -Path $envFile -Variable 'VAR2' -Value 'two'
            $envFile | Should -FileContentMatchExactly '^#VAR1=VAL1$'
            $envFile | Should -FileContentMatchExactly '^VAR2=two$'
        }

        It 'adds variable when existing is commented' {
            $envFile = 'TestDrive:\.env'
            Set-Content $envFile -Value @(
                '#VAR1=VAL1',
                'VAR2=VAL2',
                'VAR3=VAL3'
            )
            Set-DockerComposeEnvFileVariable -Path $envFile -Variable 'VAR1' -Value 'one'
            $envFile | Should -FileContentMatchExactly '^#VAR1=VAL1$'
            $envFile | Should -FileContentMatchExactly '^VAR1=one$'
        }

        It 'preserves blank lines' {
            $envFile = 'TestDrive:\.env'
            Set-Content $envFile -Value @(
                'VAR1=VAL1',
                '',
                'VAR2=VAL2'
            )
            Set-DockerComposeEnvFileVariable -Path $envFile -Variable 'VAR2' -Value 'two'
            $envFile | Should -FileContentMatchExactly '^$'
            $envFile | Should -FileContentMatchExactly '^VAR2=two$'
        }

        It 'uses .\.env as default $Path' {
            $envFile = Join-Path $TestDrive '.env'
            Set-Content $envFile -Value "foo=bar"

            Push-Location $TestDrive
            Set-DockerComposeEnvFileVariable -Variable "foo" -Value "baz"
            Pop-Location

            $envFile | Should -FileContentMatchExactly '^foo=baz$'
        }
    }
}