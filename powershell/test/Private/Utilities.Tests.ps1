. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'SetEnvironmentVariable' {

        It 'requires $Variable' {
            $result = Test-ParamIsMandatory -Command SetEnvironmentVariable -Parameter Variable
            $result | Should Be $true
        }

        It 'requires $Value' {
            $result = Test-ParamIsMandatory -Command SetEnvironmentVariable -Parameter Value
            $result | Should Be $true
        }

        It 'throws if $Variable is $null' {
            { SetEnvironmentVariable -Variable $null } | Should Throw
        }

        It 'throws if $Variable is empty' {
            { SetEnvironmentVariable -Variable "" } | Should Throw
        }

        It 'restricts $Target to limited set' {
            $result = Test-ParamValidateSet -Command SetEnvironmentVariable -Parameter Target -Values 'Machine','User','Process'
            $result | Should Be $true
        }
    }
}