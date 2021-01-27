$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\..\..\src\scripts\$sut"
. $PSScriptRoot\..\TestUtils.ps1

function Set-EnvironmentValue($Value) {
    $env:SITECORE_DEVELOPMENT_PATCHES = $Value
}

Describe 'Get-PatchFolders' {
    Mock Write-Host {}

    BeforeAll {
        Set-EnvironmentValue -Value $null
    }

    It 'requires $Path' {
        $result = Test-ParamIsMandatory -Command Get-PatchFolders -Parameter Path
        $result | Should -Be $true
    }

    It 'throws if $Path is a file' {
        $filePath = Join-Path $TestDrive 'file.txt'
        Set-Content $filePath 'foo'
        {Get-PatchFolders -Path $filePath} | Should -Throw
    }

    It 'returns nothing if the environment variable is empty' {
        $folders = (Get-PatchFolders -Path $TestDrive)
        $folders | Should -BeNullOrEmpty
    }

    It 'gets the configured patch folders' {
        Set-EnvironmentValue -Value 'foo,bar,baz'
        $test1 = New-Item -Path (Join-Path $TestDrive 'foo') -ItemType 'Directory' -Force
        $test2 = New-Item -Path (Join-Path $TestDrive 'bar') -ItemType 'Directory' -Force
        $test3 = New-Item -Path (Join-Path $TestDrive 'baz') -ItemType 'Directory' -Force
        $folders = (Get-PatchFolders -Path $TestDrive)
        $folders | Should -HaveCount 3

        $tests = @($test1, $test2, $test3) | ForEach-Object { $_.FullName }
        $folderNames = $folders | ForEach-Object { $_.FullName }
        $tests | ForEach-Object { $_ | Should -BeIn $folderNames }
    }

    It 'writes warning if a provided folder does not exist' {
        Set-EnvironmentValue -Value 'foo,idontexist,meeither'
        New-Item -Path (Join-Path $TestDrive 'foo') -ItemType 'Directory' -Force
        Get-PatchFolders -Path $TestDrive | Should -HaveCount 1
        Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $Object -match 'idontexist' }
        Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $Object -match 'meeither' }
    }

    It 'writes a warning if a provided path has invalid characters' {
        Set-EnvironmentValue -Value 'foo,subpath/leaking,something?strange,baz*bar'
        New-Item -Path (Join-Path $TestDrive 'foo') -ItemType 'Directory' -Force
        Get-PatchFolders -Path $TestDrive | Should -HaveCount 1
        Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $Object -match 'subpath/leaking' }
        Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $Object -match 'something\?strange' }
        Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $Object -match 'baz\*bar' }
    }

}