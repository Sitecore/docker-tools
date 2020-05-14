Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Simple wrapper for .NET Environment.SetEnvironmentVariable to allow mocking / unit testing
#>
function SetEnvironmentVariable
{
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Variable,

        [Parameter(Mandatory = $true)]
        [string]
        $Value,

        [ValidateSet("Process", "Machine", "User")]
        [string]
        $Target = "Process"
    )

    [Environment]::SetEnvironmentVariable($Variable, $Value, $Target)
}