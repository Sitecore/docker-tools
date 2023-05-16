Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Gets the value of a variable in a Docker environment (.env) file.
.DESCRIPTION
    Gets the value of a variable in a Docker environment (.env) file.
    Assumes .env file is in the current directory by default.
.PARAMETER Variable
    Specifies the variable name.
.PARAMETER Path
    Specifies the Docker environment (.env) file path. Assumes .env file is in the current directory by default.
.EXAMPLE
    PS C:\> Get-EnvFileVariable -Variable VAR1
.EXAMPLE
    PS C:\> Get-EnvFileVariable "VAR1"
.EXAMPLE
    PS C:\> Get-EnvFileVariable -Variable VAR1 -Path .\src\.env
.INPUTS
    System.String.
.OUTPUTS
    System.String. Value of variable. System.Exception if key is not present
#>
function Get-EnvFileVariable {
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Variable,

        [string]
        $Path = ".\.env"
    )

    if (!(Test-Path $Path)) {
        throw "The environment file $Path does not exist"
    }

    $variables = Get-EnvFileContent $Path
    try {
        if ($variables.ContainsKey($variable)) {
            $rawVariable = $variables.Get_Item($variable)            
            if (IsLiteral -Value $rawVariable) {
                #strip out the start/end single quotes if it's a literal value and un-escape.
                return $rawVariable.Substring(1, $rawVariable.Length - 2).Replace("''", "'")
            }            
            return $rawVariable
        }
        else {
            throw "Unable to find value for $Variable in $Path"
        }
    }
    catch {
        throw "Unable to find value for $Variable in $Path"
    }
}

function IsLiteral {
    param( 
        [Parameter(Mandatory = $true)]
        [string] 
        $Value
    )
    if(!$Value.StartsWith("'")){ return $false }
    #Is it a literal value? Test for an odd number of starting 's to avoid escaped values and ending with '
    $nonQuoteIndex = [regex]::Match($Value, "[^']")
    return ($nonQuoteIndex.Success -and $nonQuoteIndex.Index % 2 -eq 1 -and $Value.EndsWith("'"))
}