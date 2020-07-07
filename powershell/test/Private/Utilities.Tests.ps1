. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    Describe 'WriteLines' {

        BeforeEach {
            Push-Location $TestDrive
        }

        AfterEach {
            Pop-Location
        }

        It 'throws on invalid path' {
            { WriteLines -File "z:\fail.txt" } | Should -Throw
        }

        It 'throws on unrooted path' {
            { WriteLines -File ".\file.txt" } | Should -Throw
        }

        It 'throws if lock retry limit has been reached' {
            $random = Get-Random
            $file = Join-Path -Path $TestDrive -ChildPath $random
            New-Item -Path $file
            $fileLock = [System.IO.File]::Open($file, 'Open', 'ReadWrite', 'None')

            { WriteLines -File $file -Content "Test" -Retries 5} | Should -Throw

            $fileLock.Close()
        }

        It 'writes content to file'{
            $file = Join-Path -Path $TestDrive -ChildPath "normalfile.txt"
            $content = "ABC123"

            WriteLines -File $file -Content $content

            $result = Get-Content -Path $file
            $result | Should -Be $content
        }
    }
}