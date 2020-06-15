. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'Get-RandomKey' {

        It 'requires $Length' {
            $result = Test-ParamIsMandatory -Command Get-RandomKey -Parameter Length
            $result | Should -Be $true
        }

        It 'throws if $Length is greater than 128' {
            { Get-RandomKey -Length 129 } | Should -Throw
        }

        It 'generates key' {
            $key = Get-RandomKey 10
            $key | Should -Not -BeNullOrEmpty
            $key.length | Should -Be 10
        }

        It 'returns requested length' {
            $random = Get-Random -Minimum 8 -Maximum 128
            $key = Get-RandomKey -Length $random
            $key.length | should be $random
        }

        It 'does not include whitespace in key' {
            $key = Get-RandomKey 100
            $key | Should -Not -Match " "
        }

        It 'includes non-alphanumeric characters in key by default' {
            $key = Get-RandomKey 100
            $key | Should -Match "[^a-zA-Z0-9]"
        }

        It 'excludes non-alphanumeric characters in key when requested' {
            $key = Get-RandomKey 100 -AlphanumericOnly
            $key | Should -Not -Match "[^a-zA-Z0-9]"
        }
    }
}