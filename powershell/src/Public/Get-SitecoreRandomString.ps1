Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Generate a random string e.g. to use as a key or password.
.PARAMETER Length
    The desired length of the string.
.PARAMETER AlphanumericOnly
    Limit to use of alphanumeric characters only.
.OUTPUTS
    System.String. The random string.
#>
function Get-SitecoreRandomString
{
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Validatescript({ $_ -ge 1})]
        [int]
        $Length,

        [switch]
        $AlphanumericOnly
    )

    $charset = @(
        'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',`
        'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',`
        '1','2','3','4','5','6','7','8','9','0'
    )

    if (!$AlphanumericOnly) {
        $charset += ('~','!','@','#','$','%','^','&','*','_','-','+','=','`','|','\','(',')','{','}','[',']',':',';','<','>','.','?','/')
    }

    Write-Verbose "Generating a string of length $Length"
    Write-Verbose "Choosing from: $charset"

    $string = ""

    for ($i=1; $i -le $Length; $i++) {
        $string += Get-Random $charset
    }

    Write-Verbose "Generated string is $string"

    return $string
}