. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'Get-EnvFileContent' {

        BeforeEach {
            Push-Location $TestDrive
        }

        AfterEach {
            Pop-Location
        }

        It 'throws on invalid path' {
            { Get-EnvFileContent -File "z:\fail.txt" } | Should -Throw
        }

        It 'throws on unrooted path' {
            { Get-EnvFileContent -File ".\file.txt" } | Should -Throw
        }

        It 'reads content from file the absolute path' {
            $envFile = Join-Path $TestDrive '.env'
            $content = @(
                'VAR1=VAL1',
                'VAR2=VAL2',
                'VAR3=VAL3'
            )
            Set-Content $envFile -Value $content

            $compare = @{
                VAR1 = 'VAL1'
                VAR2 = 'VAL2'
                VAR3 = 'VAL3'
            }

            $result = Get-EnvFileContent -File $envFile
            $result.Count | Should -Be $compare.Keys.Count
            $result.Get_Item('VAR1') | Should -Be $compare.Get_Item('VAR1')
        }

        It 'reads content from file using the relative path' {
            $envFile = '.env'
            $content = @(
                'VAR1=VAL1',
                'VAR2=VAL2',
                'VAR3=VAL3'
            )
            Set-Content $envFile -Value $content

            $compare = @{
                VAR1 = 'VAL1'
                VAR2 = 'VAL2'
                VAR3 = 'VAL3'
            }

            $result = Get-EnvFileContent -File $envFile
            $result.Count | Should -Be $compare.Keys.Count
            $result.Get_Item('VAR1') | Should -Be $compare.Get_Item('VAR1')
        }
    }
}