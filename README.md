# Sitecore Docker Tools

Sitecore Docker Tools are utilities which improve developer experience when running Sitecore in a Docker environment. This includes:

  * `sitecore-docker-tools-assets`, a Docker image with development scripts and entrypoints which can be used during Sitecore container builds.  
  [![Image Build Status](https://dev.azure.com/sitecore-devex/docker-tools/_apis/build/status/DockerTools.Image?branchName=main)](https://dev.azure.com/sitecore-devex/docker-tools/_build/latest?definitionId=9&branchName=main)
  * `SitecoreDockerTools`, a PowerShell module with functions used on the Sitecore container host to initialize the Sitecore Docker environment.  
  [![PowrShell Build Status](https://dev.azure.com/sitecore-devex/docker-tools/_apis/build/status/DockerTools.PowerShell?branchName=main)](https://dev.azure.com/sitecore-devex/docker-tools/_build/latest?definitionId=10&branchName=main)

## Usage

Released versions of these utilities can be found on the Sitecore Container Registry and the Sitecore PowerShell Gallery. Usage details can be found in the [Sitecore container development documentation](https://doc.sitecore.com/developers/100/developer-tools/en/containers-in-sitecore-development.html).

### Docker Image
The scripts found in the Docker image are intended to be copied in via your custom `Dockerfile`.

```Dockerfile
FROM ${TOOLS_IMAGE} as tools
FROM ${PARENT_IMAGE}
COPY --from=tools C:\tools C:\tools
```

You can enable the [development entrypoint](https://doc.sitecore.com/developers/100/developer-tools/en/deploying-files-into-running-containers.html#idp15256) in your `docker-compose` override.

```yml
entrypoint: powershell.exe -Command "& C:\tools\entrypoints\iis\Development.ps1"
```

The development entrypoint also enables the application of development-specific configuration patches and configuration transforms at runtime via the `SITECORE_DEVELOPMENT_PATCHES` environment variable. You can see [available patches here](image/src/dev-patches).

```yml
environment:
  SITECORE_DEVELOPMENT_PATCHES: DevEnvOn,CustomErrorsOff,DebugOn,DiagnosticsOff,InitMessagesOff,RobotDetectionOff
```

### PowerShell Module
The PowerShell module can be installed and imported from the Sitecore PowerShell Gallery. 

```powershell
Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/F/sc-powershell/api/v2
Install-Module SitecoreDockerTools
Import-Module SitecoreDockerTools

# See available commands
Get-Command -Module SitecoreDockerTools
```

## Building/Using from Source

### Docker Image
```powershell
cd image\src
docker-compose build
```

### PowerShell Module
```powershell
Import-Module .\powershell\src\SitecoreDockerTools.psd1
```

## Running Tests

Unit tests require use of [Pester v4](https://pester.dev/docs/v4/introduction/installation).

From the root folder of either project:

```powershell
Import-Module Pester -RequiredVersion 4.9.0
Invoke-Pester -Path .\test\*
```
