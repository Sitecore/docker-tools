param(
    [Parameter(HelpMessage="The block of tests to run in the scope of the module")]
    [ScriptBlock]$TestScope
)

if (Get-Module SitecoreDockerTools -ErrorAction SilentlyContinue) {
    Remove-Module SitecoreDockerTools -Force
}
Import-Module $PSScriptRoot\..\src\SitecoreDockerTools.psd1 -Force -Scope Global -ErrorAction Stop

InModuleScope SitecoreDockerTools $TestScope