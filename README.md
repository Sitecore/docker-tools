# Sitecore Docker Tools

Sitecore Docker Tools are utilities which improve developer experience when running Sitecore in a Docker environment. This includes:

* `sitecore-docker-tools-assets`, a Docker image with development scripts and entrypoints which can be used during Sitecore container builds.
* `SitecoreDockerTools`, a PowerShell module with functions used on the Sitecore container host to initialize the Sitecore Docker environment.

## Usage

Released versions of these utilities can be found on the Sitecore Container Registry and the Sitecore PowerShell Gallery. Usage details can be found in the [Sitecore container development documentation](https://doc.sitecore.com/developers/100/developer-tools/en/containers-in-sitecore-development.html).

### Docker Image
The scripts found in the Docker image are intended to be copied in via your custom `Dockerfile`, then used within it or your `docker-compose` override.

```Dockerfile
FROM ${TOOLS_IMAGE} as tools
FROM ${PARENT_IMAGE}
COPY --from=tools C:\tools C:\tools
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