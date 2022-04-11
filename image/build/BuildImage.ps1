[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ContainerRegistry = "ideftdevacr.azurecr.io",
    [Parameter(Mandatory = $true)]
    [string]$Username,
    [Parameter(Mandatory = $true)]
    [string]$Password,
    [Parameter(Mandatory = $true)]
    [string]$Project,
    [Parameter(Mandatory = $true)]
    [string]$Tag,
    [Parameter(Mandatory = $true)]
    [string]$BaseImage,
    [Parameter(Mandatory = $true)]
    [string]$BuildImage
)

try{
    
    $imageName = "$ContainerRegistry/$Project/sitecore-docker-tools-assets:$Tag"
    
    if ($(docker images "$imageName" -q).Count -ne 0) {
        docker rmi "$imageName" -f | Out-Null 2> $null
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Error due to failure to cleanup build images"
    }
    
    $ContainerRegistry = ($ContainerRegistry).ToLower();
    $Project = ($Project).ToLower();
    
    Write-Information -MessageData "Logging into '$ContainerRegistry' registry..." -InformationAction Continue
    $Password | docker.exe login --username $Username --password-stdin $ContainerRegistry | Out-Null
    if ($LASTEXITCODE -gt 0){
        throw "Error logging into $ContainerRegistry"
    }
    
    Write-Information -MessageData "Building '$imageName' image..." -InformationAction Continue

    Push-Location "$PSScriptRoot\..\src\"
    
    try{
        $env:REGISTRY="$ContainerRegistry/$Project/"
        $env:VERSION=$Tag
        $env:BASE_IMAGE=$BaseImage
        $env:BUILD_IMAGE=$BuildImage
       
        docker-compose build --force-rm
        
        if ($LASTEXITCODE -ne 0) {
            throw "Error creating '$imageName' image"
        }

        Pop-Location
    }
    catch{
        Pop-Location
        throw
    }   
}
catch{
    # Catch any errors and write just the error message. 
    # We don't want to show the PowerShell stack traces to the user 
    [Console]::Error.WriteLine($error[0].Exception.Message)

    Exit 1
}