param(
    [Parameter(Mandatory = $true)]
    [string]$AzureContainerRegistry,

    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [string]$Password,
    
    [Parameter(Mandatory = $true)]
    [string]$BaseImage,
    
    [Parameter(Mandatory = $true)]
    [string]$SitecoreVersion,
    
    [Parameter(Mandatory = $true)]
    [string]$Revision,
    
    [Parameter(Mandatory = $true)]
    [string]$BuildNumber,
    
    [Parameter(Mandatory = $true)]
    [string]$OsName,
    
    [Parameter(Mandatory = $true)]
    [string]$Stability
)

Write-Information -MessageData "Logging into '$AzureContainerRegistry' registry..." -InformationAction Continue
$Password | docker.exe login --username $Username --password-stdin $AzureContainerRegistry

Write-Host "Pulling '$BaseImage' base image..."
docker pull $BaseImage

$osVersion = (docker image inspect $BaseImage | ConvertFrom-Json).OsVersion
Write-Host "Image OS version is '$osVersion'"

$longTag = "$SitecoreVersion.$Revision.$BuildNumber-$osVersion-$OsName$Stability"
$shortTag = "$SitecoreVersion-$OsName$Stability"
Write-Host "Setting long tag to '$longTag'"
Write-Host "Setting short tag to '$shortTag'"
Write-Host "##vso[task.setvariable variable=longTag;isOutput=true]$longTag"
Write-Host "##vso[task.setvariable variable=shortTag;isOutput=true]$shortTag"