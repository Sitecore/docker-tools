. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'SetEnvironmentVariable' {

        It 'requires $Variable' {
            $result = Test-ParamIsMandatory -Command SetEnvironmentVariable -Parameter Variable
            $result | Should -Be $true
        }

        It 'requires $Value' {
            $result = Test-ParamIsMandatory -Command SetEnvironmentVariable -Parameter Value
            $result | Should -Be $true
        }

        It 'throws if $Variable is $null' {
            { SetEnvironmentVariable -Variable $null } | Should -Throw
        }

        It 'throws if $Variable is empty' {
            { SetEnvironmentVariable -Variable "" } | Should -Throw
        }

        It 'restricts $Target to limited set' {
            $result = Test-ParamValidateSet -Command SetEnvironmentVariable -Parameter Target -Values 'Machine','User','Process'
            $result | Should -Be $true
        }
    }

    Describe 'GenerateRandomKey' {

        It 'requires $Length' {
            $result = Test-ParamIsMandatory -Command GenerateRandomKey -Parameter Length
            $result | Should -Be $true
        }

        It 'throws if $Length is greater than 128' {
            { GenerateRandomKey -Length 129 } | Should -Throw
        }

        It 'generates key' {
            $key = GenerateRandomKey 10
            $key | Should -Not -BeNullOrEmpty
            $key.length | Should -Be 10
        }

        It 'does not include whitespace in key' {
            $key = GenerateRandomKey 100
            $key | Should -Not -Match " "
        }

        It 'includes non-alphanumeric characters in key by default' {
            $key = GenerateRandomKey 100
            $key | Should -Match "[^a-zA-Z0-9]"
        }

        It 'excludes non-alphanumeric characters in key when requested' {
            $key = GenerateRandomKey 100 -AlphanumericCharactersOnly
            $key | Should -Not -Match "[^a-zA-Z0-9]"
        }
    }
}