$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$script = "$here\..\..\src\scripts\$sut"
. $PSScriptRoot\..\TestUtils.ps1

Describe 'Invoke-XdtTransform.ps1' {

    BeforeAll {
        if (!(Get-Package Microsoft.Web.Xdt -Destination .\..\packages -ErrorAction SilentlyContinue)) {
            Install-Package Microsoft.Web.Xdt -RequiredVersion 3.0.0 -ProviderName NuGet -Destination .\..\packages -Force -ForceBootstrap
        }
        $xdtDllPath = ".\..\packages\Microsoft.Web.Xdt.3.0.0\lib\netstandard2.0\Microsoft.Web.XmlTransform.dll"
    }

    It 'requires $Path' {
        $result = Test-ParamIsMandatory -Command $script -Parameter Path
        $result | Should Be $true
    }

    It 'requires $XdtPath' {
        $result = Test-ParamIsMandatory -Command $script -Parameter XdtPath
        $result | Should Be $true
    }

    It 'applies transform' {
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

        & $script -Path $config -XdtPath $transform -XdtDllPath $xdtDllPath

        $config | Should -FileContentMatchExactly '<add name="foo" connectionString="value"/>'
        $config | Should -FileContentMatchExactly '<add name="bar" connectionString="value"/>'
        $config | Should -FileContentMatchExactly '^    <customErrors mode="On"/>$'
    }

    It 'throws if transform fails' {
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

        {& $script -Path $config -XdtPath $transform -XdtDllPath $xdtDllPath} | Should Throw
    }
}