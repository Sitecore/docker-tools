$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$script = "$here\..\..\src\scripts\$sut"
. $PSScriptRoot\..\TestUtils.ps1

Describe 'Install-ConfigurationFolder.ps1' {

    It 'requires $Path' {
        $result = Test-ParamIsMandatory -Command $script -Parameter Path
        $result | Should -Be $true
    }

    It 'requires $PatchPath' {
        $result = Test-ParamIsMandatory -Command $script -Parameter PatchPath
        $result | Should -Be $true
    }

    It 'throws if $Path is not a folder' {
        $filePath = Join-Path $TestDrive 'file.txt'
        Set-Content $filePath 'foo'
        $folderPath = Join-Path $TestDrive 'folder'
        New-Item -Path $folderPath -ItemType 'Directory' -Force
        {& $script -Path $filePath -PatchPath $folderPath} | Should -Throw
    }

    It 'throws if $PatchPath is not a folder' {
        $filePath = Join-Path $TestDrive 'file.txt'
        Set-Content $filePath 'foo'
        $folderPath = Join-Path $TestDrive 'folder'
        New-Item -Path $folderPath -ItemType 'Directory' -Force
        {& $script -Path $folderPath -PatchPath $filePath} | Should -Throw
    }

    It 'copies configuration files' {
        $destination = New-Item -Path (Join-Path $TestDrive 'webroot') -ItemType 'Directory' -Force
        $patches = New-Item -Path (Join-Path $TestDrive 'patches') -ItemType 'Directory' -Force
        $patch = New-Item -Path (Join-Path $patches 'Patch.config') -Force
        Set-Content $patch -Value '<foo />'

        & $script -Path $destination -PatchPath $patches
        (Join-Path $destination '\Patch.config') | Should -FileContentMatchExactly '<foo />'
    }

    It 'copies configuration files to a matching path' {
        $destination = New-Item -Path (Join-Path $TestDrive 'webroot') -ItemType 'Directory' -Force
        $patches = New-Item -Path (Join-Path $TestDrive 'patches') -ItemType 'Directory' -Force
        New-Item -Path (Join-Path $patches '\App_Config') -ItemType 'Directory' -Force
        New-Item -Path (Join-Path $patches '\App_Config\Environment') -ItemType 'Directory' -Force
        $patch = New-Item -Path (Join-Path $patches '\App_Config\Environment\Patch.config') -Force
        Set-Content $patch -Value '<foo />'

        & $script -Path $destination -PatchPath $patches
        (Join-Path $destination '\App_Config\Environment\Patch.config') | Should -FileContentMatchExactly '<foo />'
    }

    It 'does not copy non-config files' {
        $destination = New-Item -Path (Join-Path $TestDrive 'webroot') -ItemType 'Directory' -Force
        $patches = New-Item -Path (Join-Path $TestDrive 'patches') -ItemType 'Directory' -Force
        New-Item -Path (Join-Path $patches '\App_Config') -ItemType 'Directory' -Force
        $transform = New-Item -Path (Join-Path $patches '\App_Config\Patch.xdt') -Force
        Set-Content $transform -Value '<foo />'

        & $script -Path $destination -PatchPath $patches
        (Join-Path $destination '\App_Config\Patch.xdt') | Should -Not -Exist
    }

    It 'overwrites existing files' {
        $destination = New-Item -Path (Join-Path $TestDrive 'webroot') -ItemType 'Directory' -Force
        $existingPatch = New-Item -Path (Join-Path $destination 'Patch.config') -Force
        Set-Content $existingPatch -Value '<bar />'

        $patches = New-Item -Path (Join-Path $TestDrive 'patches') -ItemType 'Directory' -Force
        $patch = New-Item -Path (Join-Path $patches 'Patch.config') -Force
        Set-Content $patch -Value '<foo />'

        & $script -Path $destination -PatchPath $patches
        (Join-Path $destination '\Patch.config') | Should -FileContentMatchExactly '<foo />'
    }

}