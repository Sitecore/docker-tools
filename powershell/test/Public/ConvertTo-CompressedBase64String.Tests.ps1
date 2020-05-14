. $PSScriptRoot\..\TestRunner.ps1 {
    . $PSScriptRoot\..\TestUtils.ps1

    function GetExpectedResult([string] $path) {
        $stream = [System.IO.File]::OpenRead($path)
        $memory = [System.IO.MemoryStream]::new()
        $gzip = [System.IO.Compression.GZipStream]::new($memory, [System.IO.Compression.CompressionLevel]::Optimal, $false)
        $stream.CopyTo($gzip)
        $gzip.Close()
        $expectedResult = [System.Convert]::ToBase64String($memory.ToArray())

        $gzip.Dispose()
        $gzip = $null
        $memory.Dispose()
        $memory = $null
        $stream.Dispose()
        $stream = $null

        return $expectedResult
    }

    Describe 'ConvertTo-CompressedBase64String' {

        BeforeAll {
            $testPath = Join-Path $TestDrive 'test.txt'
            Set-Content $testPath -value "Lorem ipsum dolor sit amet."
            $expectedResult = GetExpectedResult $testPath
        }

        It 'requires $Path or $Stream' {
            $result = Test-ParamIsMandatory -Command ConvertTo-CompressedBase64String -Parameter Path -SetName 'FromPath'
            $result | Should Be $true
            $result = Test-ParamIsMandatory -Command ConvertTo-CompressedBase64String -Parameter Stream -SetName 'FromStream'
            $result | Should Be $true
        }

        It 'throws if $Path is $null' {
            { ConvertTo-CompressedBase64String -Path $null } | Should Throw
        }

        It 'throws if $Path is empty' {
            { ConvertTo-CompressedBase64String -Path "" } | Should Throw
        }

        It 'throws if $Path is invalid' {
            { ConvertTo-CompressedBase64String -Path "NO:\\NO" } | Should Throw
        }

        It 'throws if $Path is a folder' {
            { ConvertTo-CompressedBase64String -Path $TestDrive } | Should Throw
        }

        It 'returns compressed base64 string from $Path' {
            $result = ConvertTo-CompressedBase64String -Path $testPath
            $result | Should Be $expectedResult
        }

        It 'returns compressed base64 string from $Stream' {
            $result = [System.IO.File]::OpenRead($testPath) | ConvertTo-CompressedBase64String
            $result | Should Be $expectedResult
        }
    }
}