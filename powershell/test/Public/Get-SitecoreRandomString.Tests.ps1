. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'Get-SitecoreRandomString' {

        It 'requires $Length' {
            $result = Test-ParamIsMandatory -Command Get-SitecoreRandomString -Parameter Length
            $result | Should -Be $true
        }

        It 'throws if $Length is less than 1' {
            { Get-SitecoreRandomString -Length 0 } | Should -Throw
        }

        It 'generates string' {
            $key = Get-SitecoreRandomString 10
            $key | Should -Not -BeNullOrEmpty
            $key.length | Should -Be 10
        }

        It 'returns requested length' {
            $random = Get-Random -Minimum 8 -Maximum 128
            $key = Get-SitecoreRandomString -Length $random
            $key.length | should be $random
        }

        It 'does not include whitespace in string' {
            $key = Get-SitecoreRandomString 100
            $key | Should -Not -Match " "
        }

        It 'includes non-alphanumeric characters in string by default' {
            $key = Get-SitecoreRandomString 100
            $key | Should -Match "[^a-zA-Z0-9]"
        }

        It 'excludes non-alphanumeric characters in string when requested' {
            $key = Get-SitecoreRandomString 100 -AlphanumericOnly
            $key | Should -Not -Match "[^a-zA-Z0-9]"
        }
    }
}