$ModuleScriptName = 'SitecoreDockerTools.psm1'
$ModuleManifestName = 'SitecoreDockerTools.psd1'
$ModuleScriptPath = "$PSScriptRoot\..\..\src\$ModuleScriptName"
$ModuleManifestPath = "$PSScriptRoot\..\..\src\$ModuleManifestName"

if (!(Get-Module PSScriptAnalyzer -ErrorAction SilentlyContinue)) {
    Install-Module -Name PSScriptAnalyzer -Repository PSGallery -Force
}

Describe 'Module Tests' {
    It 'imports successfully' {
        { Import-Module -Name $ModuleScriptPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'passes default PSScriptAnalyzer rules' {
        Invoke-ScriptAnalyzer -Path $ModuleScriptPath | Should -BeNullOrEmpty
    }
}

Describe 'Module Manifest Tests' {
    It 'passes Test-ModuleManifest' {
        Write-Host $ModuleManifestPath
        Test-ModuleManifest -Path $ModuleManifestPath | Should -Not -BeNullOrEmpty
        $? | Should -Be $true
    }
}