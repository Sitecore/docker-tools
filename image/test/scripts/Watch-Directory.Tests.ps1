$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$script = "$here\..\..\src\scripts\$sut"
. $PSScriptRoot\..\TestUtils.ps1

Describe 'Watch-Directory.ps1' {

    # Supress info messages from Watch-Directory.ps1. Can set to "Continue" if necessary for debugging.
    $InformationPreference = "SilentlyContinue"

    BeforeAll {
        $dummyFile = Join-Path $TestDrive 'dummy.txt'
        Set-Content $dummyFile -Value 'dummy'
    }

    It 'requires $Path' {
        $result = Test-ParamIsMandatory -Command $script -Parameter Path
        $result | Should -Be $true
    }

    It 'requires $Destination' {
        $result = Test-ParamIsMandatory -Command $script -Parameter Destination
        $result | Should -Be $true
    }

    It 'throws if invalid $Path' {
        {& $script -Path 'C:\DoesNotExist' -Destination $TestDrive} | Should -Throw
        {& $script -Path $dummyFile -Destination $TestDrive} | Should -Throw
        {& $script -Path $null -Destination $TestDrive} | Should -Throw
    }

    It 'throws if invalid $Destination' {
        {& $script -Path $TestDrive -Destination 'C:\DoesNotExist'} | Should -Throw
        {& $script -Path $TestDrive -Destination $dummyFile} | Should -Throw
        {& $script -Path $TestDrive -Destination $null} | Should -Throw
    }

    It 'copies existing files' {
        $src = New-Item -Path (Join-Path $TestDrive (Get-Random)) -ItemType 'Directory'
        $dst = New-Item -Path (Join-Path $TestDrive (Get-Random)) -ItemType 'Directory'
        New-Item -Path "$($src)\file.txt" -ItemType 'File'

        & $script -Path $src -Destination $dst -Timeout 100

        "$($dst)\file.txt" | Should -Exist
    }

    It 'copies new files' {
        $src = New-Item -Path (Join-Path $TestDrive (Get-Random)) -ItemType 'Directory'
        $dst = New-Item -Path (Join-Path $TestDrive (Get-Random)) -ItemType 'Directory'

        $job = Start-Job -ScriptBlock { Start-Sleep -Milliseconds 500; New-Item -Path "$($args[0])\file.txt" } -ArgumentList $src
        & $script -Path $src -Destination $dst -Timeout 2000 -Sleep 100
        $job | Wait-Job | Remove-Job

        "$($dst)\file.txt" | Should -Exist
    }

    It 'deletes files' {
        $src = New-Item -Path (Join-Path $TestDrive (Get-Random)) -ItemType 'Directory'
        $dst = New-Item -Path (Join-Path $TestDrive (Get-Random)) -ItemType 'Directory'
        New-Item -Path "$($src)\file.txt" -ItemType 'File'
        New-Item -Path "$($dst)\file.txt" -ItemType 'File'

        $job = Start-Job -ScriptBlock { Start-Sleep -Milliseconds 500; Remove-Item -Path "$($args[0])\file.txt" -Recurse } -ArgumentList $src
        & $script -Path $src -Destination $dst -Timeout 2000 -Sleep 100
        $job | Wait-Job | Remove-Job

        "$($dst)\file.txt" | Should -Not -Exist
    }

    It 'ignores excluded files on copy' {
        $src = New-Item -Path (Join-Path $TestDrive (Get-Random)) -ItemType 'Directory'
        $dst = New-Item -Path (Join-Path $TestDrive (Get-Random)) -ItemType 'Directory'
        New-Item -Path "$($src)\file.disabled" -ItemType 'File'
        New-Item -Path "$($src)\web.config" -ItemType 'File'

        & $script -Path $src -Destination $dst -Timeout 100 -DefaultExcludedFiles @("*.disabled") -ExcludeFiles @("web.config")

        "$($dst)\file.disabled" | Should -Not -Exist
        "$($dst)\web.config" | Should -Not -Exist
    }

    It 'ignores excluded directories on copy' {
        $src = New-Item -Path (Join-Path $TestDrive (Get-Random)) -ItemType 'Directory'
        $dst = New-Item -Path (Join-Path $TestDrive (Get-Random)) -ItemType 'Directory'
        New-Item -Path "$($src)\obj" -ItemType 'Directory'
        New-Item -Path "$($src)\obj\file.txt" -ItemType 'File'
        New-Item -Path "$($src)\exclude" -ItemType 'Directory'
        New-Item -Path "$($src)\exclude\file.txt" -ItemType 'File'

        & $script -Path $src -Destination $dst -Timeout 100 -DefaultExcludedDirectories @("obj") -ExcludeDirectories @("exclude")

        "$($dst)\obj\file.txt" | Should -Not -Exist
        "$($dst)\exclude\file.txt" | Should -Not -Exist
    }

    It 'ignores excluded files on delete' {
        $src = New-Item -Path (Join-Path $TestDrive (Get-Random)) -ItemType 'Directory'
        $dst = New-Item -Path (Join-Path $TestDrive (Get-Random)) -ItemType 'Directory'
        New-Item -Path "$($src)\web.config" -ItemType 'File'
        New-Item -Path "$($dst)\web.config" -ItemType 'File'

        $job = Start-Job -ScriptBlock { Start-Sleep -Milliseconds 500; Remove-Item -Path "$($args[0])\web.config" } -ArgumentList $src
        & $script -Path $src -Destination $dst -Timeout 1000 -Sleep 100 -ExcludeFiles @("web.config")
        $job | Wait-Job | Remove-Job

        "$($src)\web.config" | Should -Not -Exist
        "$($dst)\web.config" | Should -Exist
    }
}