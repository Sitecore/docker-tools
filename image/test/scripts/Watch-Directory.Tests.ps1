$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$script = "$here\..\..\src\scripts\$sut"
. $PSScriptRoot\..\TestUtils.ps1

Describe 'Watch-Directory.ps1' {

    BeforeAll {
        $dummyFile = Join-Path $TestDrive 'dummy.txt'
        Set-Content $dummyFile -Value 'dummy'
    }

    It 'requires $Path' {
        $result = Test-ParamIsMandatory -Command $script -Parameter Path
        $result | Should Be $true
    }

    It 'requires $Destination' {
        $result = Test-ParamIsMandatory -Command $script -Parameter Destination
        $result | Should Be $true
    }
    
    It 'throws if invalid $Path' {
        {& $script -Path 'C:\DoesNotExist' -Destination $TestDrive} | Should Throw
        {& $script -Path $dummyFile -Destination $TestDrive} | Should Throw
        {& $script -Path $null -Destination $TestDrive} | Should Throw
    }

    It 'throws if invalid $Destination' {
        {& $script -Path $TestDrive -Destination 'C:\DoesNotExist'} | Should Throw
        {& $script -Path $TestDrive -Destination $dummyFile} | Should Throw
        {& $script -Path $TestDrive -Destination $null} | Should Throw
    }

}