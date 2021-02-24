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
            return $variables.Get_Item($variable)
        }
        else {
            throw "Unable to find value for $Variable in $Path"
        }
    }
    catch {
        throw "Unable to find value for $Variable in $Path"
    }
}