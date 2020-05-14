param(
    [Parameter(HelpMessage="The block of tests to run in the scope of the module")]
    [ScriptBlock]$TestScope
)

Remove-Module SitecoreDockerTools -Force
Import-Module $PSScriptRoot\..\src\SitecoreDockerTools.psd1 -Force -ErrorAction Stop

InModuleScope SitecoreDockerTools $TestScope