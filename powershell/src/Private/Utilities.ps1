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

<#
.SYNOPSIS
    Generate a random string to use as a key or password.
.PARAMETER Length
    The desired length of the string, no more than 128.
.PARAMETER AlphanumericCharactersOnly
    Limit to use of alphanumeric characters only.
.OUTPUTS
    System.String. The random string.
#>
function GenerateRandomKey
{
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ $_ -le 128 })]
        [int]
        $Length,

        [switch]
        $AlphanumericCharactersOnly
    )

    Add-Type -AssemblyName 'System.Web'

    $key = [Web.Security.Membership]::GeneratePassword($Length, 0)
    if ($AlphanumericCharactersOnly) {
        $key = $key -replace "[^a-zA-Z0-9]", "0"
    }
    return $key
}