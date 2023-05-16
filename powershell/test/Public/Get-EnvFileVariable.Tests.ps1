. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'Get-EnvFileVariable' {       

        BeforeEach {
            Push-Location $TestDrive
        }

        AfterEach {
            Pop-Location
        }
            
        $envFile = '.env'
        $content = @(
            'VAR1=VAL1',
            'VAR2=VAL2',
            'VAR3=VAL3',
            'VAR4=''VAL4$Literal''',
            "VAR5=''VAL5''Escaped''",
            "VAR6='VAL6''EscapedLiteral'",
            "VAR7='VAL7"
            "VAR8='''VAL8'"
        )
        Set-Content "$TestDrive\$envFile" -Value $content

        It 'requires $Variable' {
            $result = Test-ParamIsMandatory -Command Get-EnvFileVariable -Parameter Variable
            $result | Should -Be $true
        }

        It 'throws if $Path is invalid' {
            { Get-EnvFileVariable -Variable "foo" -Value "bar" -Path "$.baz" } | Should -Throw
        }

        It 'throws if $Variable is $null or empty' {
            { Get-EnvFileVariable -Variable $null -Value "bar" -Path $envFile } | Should -Throw
            { Get-EnvFileVariable -Variable "" -Value "bar" -Path $envFile } | Should -Throw
        }

        It 'throws if variable not found' {
            { Get-EnvFileVariable -Path $envFile -Variable 'VAR' } | Should -Throw
        }

        It 'reads variable correctly using default file path' {
            $value = 'VAL2'
            $result = Get-EnvFileVariable -Variable 'VAR2'
            $result | Should -Be $value
        }

        It 'reads variable correctly using relative file path' {
            $value = 'VAL2'
            $result = Get-EnvFileVariable -Path $envFile -Variable 'VAR2'
            $result | Should -Be $value
        }

        It 'reads variable correctly using absolute file path' {
            $value = 'VAL2'
            $result = Get-EnvFileVariable -Path "$TestDrive\$envFile" -Variable 'VAR2'
            $result | Should -Be $value
        }

        It 'reads variable correctly using a literal value' {
            $value = 'VAL4$Literal'
            $result = Get-EnvFileVariable -Variable 'VAR4'
            $result | Should -Be $value
        }

        It 'reads variable correctly using quotes in non-literal strings' {
            $value = "''VAL5''Escaped''"
            $result = Get-EnvFileVariable -Variable 'VAR5'
            $result | Should -Be $value
        }

        It 'reads variable correctly using escaped quotes in literals' {
            $value = "VAL6'EscapedLiteral"
            $result = Get-EnvFileVariable -Variable 'VAR6'
            $result | Should -Be $value
        }
        
        It 'reads variable correctly using non-literal strings starting with quote' {
            $value = "'VAL7"
            $result = Get-EnvFileVariable -Variable 'VAR7'
            $result | Should -Be $value
        }
        It 'reads variable correctly using literal strings starting with quote' {
            $value = "'VAL8"
            $result = Get-EnvFileVariable -Variable 'VAR8'
            $result | Should -Be $value
        }
    }
}