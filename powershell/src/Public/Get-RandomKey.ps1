Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Generate a random string to use as a key or password.
.PARAMETER Length
    The desired length of the string, no more than 128.
.PARAMETER AlphanumericOnly
    Limit to use of alphanumeric characters only.
.OUTPUTS
    System.String. The random string.
#>
function Get-RandomKey
{
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ $_ -le 128 })]
        [int]
        $Length,

        [switch]
        $AlphanumericOnly
    )

    Add-Type -AssemblyName 'System.Web'

    $key = [Web.Security.Membership]::GeneratePassword($Length, 0)
    if ($AlphanumericOnly) {
        $key = $key -replace "[^a-zA-Z0-9]", (Get-Random -Minimum 0 -Maximum 10)
    }
    return $key
}