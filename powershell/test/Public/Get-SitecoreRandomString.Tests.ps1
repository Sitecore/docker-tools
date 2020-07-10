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
            $key.length | Should -Be $random
        }

        It 'does not include whitespace in string' {
            $key = Get-SitecoreRandomString 100
            $key | Should -Not -Match " "
        }

        It 'throws if Length is less than 4 (<Length>) and EnforceComplexty requested' -TestCases @(
            @{ Length = 1},
            @{ Length = 3}
        ){
            param($Length)
            { Get-SitecoreRandomString -Length $Length -EnforceComplexity } | Should -Throw
        }

        It 'throws if there are no allowed character types' {
            $random = Get-Random -Minimum 10 -Maximum 20

            { Get-SitecoreRandomString -Length $random -DisallowCaps -DisallowLower -DisallowNumbers -DisallowSpecial } | Should -Throw
        }

        It 'includes all character types in string by default' {
            $result = Get-SitecoreRandomString 100
            $result | Should -MatchExactly "[A-Z]"
            $result | Should -MatchExactly "[a-z]"
            $result | Should -MatchExactly "[0-9]"
            $result | Should -MatchExactly "[^a-zA-Z0-9]"
        }

        It 'excludes requested character type: Caps' {
            $random = Get-Random -Minimum 10 -Maximum 20
            $result = Get-SitecoreRandomString -Length $random -DisallowCaps
            $result | Should -Not -MatchExactly "[A-Z]"
        }

        It 'excludes requested character type: Lowercase' {
            $random = Get-Random -Minimum 10 -Maximum 20
            $result = Get-SitecoreRandomString -Length $random -DisallowLower
            $result | Should -Not -MatchExactly "[a-z]"
        }

        It 'excludes requested character type: Numbers' {
            $random = Get-Random -Minimum 10 -Maximum 20
            $result = Get-SitecoreRandomString -Length $random -DisallowNumbers
            $result | Should -Not -MatchExactly "[0-9]"
        }

        It 'excludes requested character type: Special' {
            $random = Get-Random -Minimum 10 -Maximum 20
            $result = Get-SitecoreRandomString -Length $random -DisallowSpecial
            $result | Should -Not -MatchExactly "[^a-zA-Z0-9]"
        }

        It 'meets complexity requirements' {
            $random = Get-Random -Minimum 15 -Maximum 25
            $result = Get-SitecoreRandomString -Length $random -EnforceComplexity

            $nums = 0
            $caps = 0
            $lower = 0
            $special = 0

            $charArray = $result.ToCharArray()

            foreach ($character in $charArray) {

                if ([byte]$character -ge 33 -and [byte]$character -le 47) {
                    $special = 1
                }
                if ([byte]$character -ge 48 -and [byte]$character -le 57) {
                    $nums = 1
                }
                if ([byte]$character -ge 58 -and [byte]$character -le 64) {
                    $special = 1
                }
                if ([byte]$character -ge 65 -and [byte]$character -le 90) {
                    $caps = 1
                }
                if ([byte]$character -ge 91 -and [byte]$character -le 96) {
                    $special = 1
                }
                if ([byte]$character -ge 97 -and [byte]$character -le 122) {
                    $lower = 1
                }
                if ([byte]$character -ge 123 -and [byte]$character -le 126) {
                    $special = 1
                }
            }
            $total = $nums + $caps + $lower + $special

            $total | Should -eq 4
        }
    }
}