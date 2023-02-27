Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Generates a random string of the specified length e.g. to use as a key or password.
.DESCRIPTION
    Generates a random string of the specified length using one or more of the 4 allowed types (all by default).
    The allowed types include: capital letters, lowercase letters, numbers, and the ASCII special printable characters.
    The -EnforceComplexity option will ensure that at least one of each of the allowed types are present in the string.
.PARAMETER Length
    The desired length of the string.
.PARAMETER EnforceComplexity
    Ensures the returned string contains at least one of each of the allowed character types.
.PARAMETER DisallowSpecial
    Prevent the special characters ~!@#$%^&*_-+=`|(){}[]:;<>.?/
.PARAMETER DisallowDollar
    Prevent just $ symbol
.PARAMETER DisallowCaps
    Prevent capital letters from appearing in the generated sting.
.PARAMETER DisallowLower
    Prevent lower case letters from appearing in the generated string.
.PARAMETER DisallowNumbers
    Prevent numbers from appearing in the generated string.
.INPUTS
    None. You cannot pipe objects to Get-SitecoreRandomString.
.OUTPUTS
    System.String. The random string.
.EXAMPLE
    PS C:\> Get-SitecoreRandomString -Length 10
.EXAMPLE
    PS C:\> Get-SitecoreRandomString -Length 10 -EnforceComplexity -DisallowDollar
#>
function Get-SitecoreRandomString
{
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Validatescript({ $_ -ge 1})]
        [int]
        $Length,

        [Parameter(Position = 1)]
        [switch]
        $EnforceComplexity,

        [Parameter(ParameterSetName = 'custom', Position = 2)]
        [switch]
        $DisallowSpecial,

        [Parameter(ParameterSetName = 'custom', Position = 3)]
        [switch]
        $DisallowCaps,

        [Parameter(ParameterSetName = 'custom', Position = 4)]
        [switch]
        $DisallowLower,

        [Parameter(ParameterSetName = 'custom', Position = 5)]
        [switch]
        $DisallowNumbers,

        [Parameter(ParameterSetName = 'custom', Position = 6)]
        [switch]
        $DisallowDollar
    )

    $complexity = 0
    $charset = @()

    if ($PSCmdlet.ParameterSetName -ne 'custom') {
        $DisallowCaps = $false
        $DisallowLower = $false
        $DisallowNumbers = $false
        $DisallowSpecial = $false
        $DisallowDollar = $false
    }

    if (!$DisallowCaps) {
        $charset = ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')
        $complexity = $complexity + 1
    }

    if (!$DisallowLower) {
        $charset += ('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z')
        $complexity = $complexity + 1
    }

    if (!$DisallowNumbers) {
        $charset += ('1','2','3','4','5','6','7','8','9','0')
        $complexity = $complexity + 1
    }

    if (!$DisallowSpecial) {
        if (!$DisallowDollar) {
        	$charset += ('~','!','@','#','$','%','^','&','*','_','-','+','=','`','|','\','(',')','{','}','[',']',':',';','<','>','.','?','/')
        else
        {
		$charset += ('~','!','@','#','%','^','&','*','_','-','+','=','`','|','\','(',')','{','}','[',']',':',';','<','>','.','?','/')
        }
        $complexity = $complexity + 1
    }

    if ($EnforceComplexity -and $Length -lt $complexity) {
        throw "Requested charater types require a minimum length of $complexity characters."
    }

    if ($complexity -eq 0) {
        throw "No allowed character types."
    }

    Write-Verbose "Choosing from: $charset"
    Write-Verbose "Complexity Level: $complexity"

    do {
        Write-Verbose "Generating a string of length $Length"

        $generatedString = ""

        for ($i=1; $i -le $Length; $i++){
            $generatedString += Get-Random $charset
        }

        Write-Verbose "Generated string is $generatedString"

        $nums = 0
        $caps = 0
        $lower = 0
        $special = 0

        if ($EnforceComplexity) {

            Write-Verbose "Checking for complexity..."

            $charArray = $generatedString.ToCharArray()

            foreach ($character in $charArray){
                if ([byte]$character -ge 33 -and [byte]$character -le 47) {
                    $special = 1
                }
                if ([byte]$character -ge 48 -and [byte]$character -le 57) {
                    $nums = 1
                }
                if ([byte]$character -ge 58 -and [byte]$character -le 64) {
                    $special = 1
                }
                if ([byte]$character -ge 65 -and [byte]$character -le 90) {
                    $caps = 1
                }
                if ([byte]$character -ge 91 -and [byte]$character -le 66) {
                    $special = 1
                }
                if ([byte]$character -ge 97 -and [byte]$character -le 122) {
                    $lower = 1
                }
                if ([byte]$character -ge 123 -and [byte]$character -le 126) {
                    $special = 1
                }
            }

            Write-Verbose "Complexity found: $($nums + $caps + $lower + $special)"

        } else {
           $complexity = $nums + $caps + $lower + $special
        }

    } while ($nums + $caps + $lower + $special -ne $complexity)

    return $generatedString
}