. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'Get-EnvFileVariable' {

        $envFile = Join-Path $TestDrive '.env'
        $content = @(
            'VAR1=VAL1',
            'VAR2=VAL2',
            'VAR3=VAL3'
        )
        Set-Content $envFile -Value $content

        It 'requires $Variable' {
            $result = Test-ParamIsMandatory -Command Get-EnvFileVariable -Parameter Variable
            $result | Should -Be $true
        }

        It 'throws if $Path is invalid' {
            { Get-EnvFileVariable -Variable "foo" -Value "bar" -Path "$TestDrive\.baz" } | Should -Throw
        }

        It 'throws if $Variable is $null or empty' {
            { Get-EnvFileVariable -Variable $null -Value "bar" -Path $envFile } | Should -Throw
            { Get-EnvFileVariable -Variable "" -Value "bar" -Path $envFile } | Should -Throw
        }

        It 'throws if variable not found' {
            { Get-EnvFileVariable -Path $envFile -Variable 'VAR' } | Should -Throw
        }

        It 'reads variable correctly' {
            $value = 'VAL2'
            $result = Get-EnvFileVariable -Path $envFile -Variable 'VAR2'
            $result | Should -Be $value
        }
    }
}