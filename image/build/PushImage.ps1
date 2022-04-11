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
        
        Write-Information -MessageData "Logging into '$ContainerRegistry' registry..." -InformationAction Continue
        $Password | docker.exe login --username $Username --password-stdin $ContainerRegistry | Out-Null
        if ($LASTEXITCODE -gt 0){
            throw "Error logging into $ContainerRegistry"
        }
        
        Write-Information -MessageData "Pushing '$imageName' image to the ACR..." -InformationAction Continue

        docker push $imageName | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Error pushing $ContainerRegistry"
        }    
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Error due to failure to cleanup build images"
    }
}
catch{
    # Catch any errors and write just the error message. 
    # We don't want to show the PowerShell stack traces to the user 
    [Console]::Error.WriteLine($error[0].Exception.Message)

    Exit 1
}
finally{
    Write-Information -MessageData "Cleaning up after build..." -InformationAction Continue

    # Clean up build solution image
    docker rmi "$imageName" -f | Out-Null

    # Clean up dangling images
    $danglingImages=$(docker images -f dangling=true -q)

    if ($danglingImages.Count -ne 0) {
        docker rmi $danglingImages | Out-Null
    }

    # Clean up built images
    docker rmi $BaseImage | Out-Null
    docker rmi $BuildImage | Out-Null

    # Remove any stopped containers
    $stoppedContainers = docker ps -a -q
    if ($stoppedContainers.Count -ne 0) {
        docker rm -v $(docker ps -a -q) | Out-Null
    }
}