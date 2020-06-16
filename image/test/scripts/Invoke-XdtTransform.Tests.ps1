$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$script = "$here\..\..\src\scripts\$sut"
. $PSScriptRoot\..\TestUtils.ps1

Describe 'Invoke-XdtTransform.ps1' {

    BeforeAll {
        if (!(Get-Package Microsoft.Web.Xdt -Destination "$PSScriptRoot\..\packages" -ErrorAction SilentlyContinue)) {
            Install-Package Microsoft.Web.Xdt -RequiredVersion 3.0.0 -ProviderName NuGet -Destination "$PSScriptRoot\..\packages" -Force -ForceBootstrap
        }
        $xdtDllPath = "$PSScriptRoot\..\packages\Microsoft.Web.Xdt.3.0.0\lib\netstandard2.0\Microsoft.Web.XmlTransform.dll"

        $validConfig = Join-Path $TestDrive 'Web.config'
        Set-Content $validConfig -Value '<?xml version="1.0"?><configuration></configuration>'
        $validTransform = Join-Path $TestDrive 'Web.config.xdt'
        Set-Content $validTransform -Value '<?xml version="1.0"?><configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform"></configuration>'
    }

    It 'requires $Path' {
        $result = Test-ParamIsMandatory -Command $script -Parameter Path
        $result | Should -Be $true
    }

    It 'requires $XdtPath' {
        $result = Test-ParamIsMandatory -Command $script -Parameter XdtPath
        $result | Should -Be $true
    }

    It 'throws if $Path is a folder and $XdtPath is a file' {
        {& $script -Path $TestDrive -XdtPath $validTransform -XdtDllPath $xdtDllPath} | Should -Throw
    }

    It 'throws if $Path is a file and $XdtPath is a folder' {
        {& $script -Path $validConfig -XdtPath $TestDrive -XdtDllPath $xdtDllPath} | Should -Throw
    }

    It 'throws if invalid $XdtDllPath' {
        {& $script -Path $validConfig -XdtPath $validTransform -XdtDllPath $null} | Should -Throw
    }

    Context 'when passing files' {

        It 'applies file transform' {
            $config = Join-Path $TestDrive 'Web.config'
            Set-Content $config -Value `
@'
<?xml version="1.0"?>
<configuration>
  <connectionStrings>
    <add name="foo" connectionString="value"/>
  </connectionStrings>
  <system.web>
    <customErrors mode="Off"/>
  </system.web>
</configuration>
'@
            $transform = Join-Path $TestDrive 'Web.config.xdt'
            Set-Content $transform -Value `
@'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
  <connectionStrings>
	<add name="bar" connectionString="value" xdt:Transform="Insert"/>
  </connectionStrings>
  <system.web>
	<customErrors mode="On" xdt:Transform="Replace"/>
  </system.web>
</configuration>
'@

            & $script -Path $config -XdtPath $transform -XdtDllPath $xdtDllPath -Verbose

            $config | Should -FileContentMatchExactly '<add name="foo" connectionString="value"/>'
            $config | Should -FileContentMatchExactly '<add name="bar" connectionString="value"/>'
            $config | Should -FileContentMatchExactly '^    <customErrors mode="On"/>$'
        }

        It 'throws if file transform fails' {
            $config = Join-Path $TestDrive 'Web.config'
            Set-Content $config -Value `
@'
<?xml version="1.0"?>
<configuration>
</configuration>
'@
            $transform = Join-Path $TestDrive 'Web.config.xdt'
            Set-Content $transform -Value `
@'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
  <connectionStrings xdt:Transform="INVALID" />
</configuration>
'@

            {& $script -Path $config -XdtPath $transform -XdtDllPath $xdtDllPath} | Should -Throw
        }
    }

    Context 'when passing folders' {

        It "applies folder transforms from <target> folder" -TestCases @(
            @{ target = 'same'; configFolder = '\same'; transformFolder = '\same' },
            @{ target = 'different'; configFolder = '\different-one'; transformFolder = '\different-two' }
        ) {
            param($target, $configFolder, $transformFolder)

            $configs = New-Item -Path (Join-Path $TestDrive $configFolder) -ItemType 'Directory' -Force
            $transforms = New-Item -Path (Join-Path $TestDrive $transformFolder) -ItemType 'Directory' -Force

            $webConfig = Join-Path $configs 'Web.config'
            Set-Content $webConfig -Value `
@'
<?xml version="1.0"?>
<configuration>
  <system.web>
    <customErrors mode="Off"/>
  </system.web>
</configuration>
'@
            $webConfigTransform = Join-Path $transforms 'Web.config.xdt'
            Set-Content $webConfigTransform -Value `
@'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
  <system.web>
	<customErrors mode="On" xdt:Transform="Replace"/>
  </system.web>
</configuration>
'@
            New-Item -Path (Join-Path $configs '\App_Config') -ItemType 'Directory' -Force
            $layersConfig = Join-Path $configs '\App_Config\Layers.config'
            Set-Content $layersConfig -Value `
@'
<?xml version="1.0"?>
<layers>
  <layer name="Sitecore" />
</layers>
'@
            New-Item -Path (Join-Path $transforms '\App_Config') -ItemType 'Directory' -Force
            $layersConfigTransform = Join-Path $transforms '\App_Config\layers.config.xdt'
            Set-Content $layersConfigTransform -Value `
@'
<?xml version="1.0"?>
<layers xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
  <layer name="Custom" xdt:Locator="Match(name)" xdt:Transform="InsertIfMissing"/>
</layers>
'@

            & $script -Path (Join-Path $TestDrive $configFolder) -XdtPath (Join-Path $TestDrive $transformFolder) -XdtDllPath $xdtDllPath -Verbose

            $webConfig | Should -FileContentMatchExactly '<customErrors mode="On"/>'
            $layersConfig | Should -FileContentMatchExactly '<layer name="Custom"/>'
        }

        It 'skips transforms without matching file' {
            $configFolder = '\skips-configs'
            $transformFolder = '\skips-transforms'
            $configs = New-Item -Path (Join-Path $TestDrive $configFolder) -ItemType 'Directory' -Force
            $transforms = New-Item -Path (Join-Path $TestDrive $transformFolder) -ItemType 'Directory' -Force

            $webConfig = Join-Path $configs 'Web.config'
            Set-Content $webConfig -Value `
@'
<?xml version="1.0"?>
<configuration>
  <system.web>
    <customErrors mode="Off"/>
  </system.web>
</configuration>
'@
            $webConfigTransform = Join-Path $transforms 'Web.config.xdt'
            Set-Content $webConfigTransform -Value `
@'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
  <system.web>
	<customErrors mode="On" xdt:Transform="Replace"/>
  </system.web>
</configuration>
'@
            $hangingTransform = Join-Path $transforms 'hanging.config.xdt'
            Set-Content $hangingTransform -Value '<?xml version="1.0"?><configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform"></configuration>'

            {& $script -Path (Join-Path $TestDrive $configFolder) -XdtPath (Join-Path $TestDrive $transformFolder) -XdtDllPath $xdtDllPath -Verbose} | Should -Not -Throw

            $webConfig | Should -FileContentMatchExactly '<customErrors mode="On"/>'
        }
    }
}