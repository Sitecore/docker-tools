# escape=`

ARG BASE_IMAGE
ARG BUILD_IMAGE

FROM ${BUILD_IMAGE} as build

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Create working directories
RUN New-Item -Path 'C:\\temp' -ItemType 'Directory' -Force | Out-Null; `
    New-Item -Path 'C:\\tools' -ItemType 'Directory' -Force | Out-Null; `
    New-Item -Path 'C:\\tools\\bin' -ItemType 'Directory' -Force | Out-Null;

# Install NuGet
ADD https://dist.nuget.org/win-x86-commandline/v5.2.0/nuget.exe /temp/

# Install Microsoft XDT assembly
RUN & 'C:\\temp\\nuget.exe' install 'Microsoft.Web.Xdt' -Version '3.0.0' -OutputDirectory 'C:\\temp'; `
    Copy-Item -Path 'C:\\temp\\Microsoft.Web.Xdt*\\lib\\netstandard2.0\\*.dll' -Destination 'C:\\tools\\bin'; `
    Remove-Item -Path (Get-Item -Path 'C:\\temp\\Microsoft.Web.Xdt*\\').FullName -Recurse -Force;

# Add entrypoints and scripts and patches
COPY /entrypoints/ /tools/entrypoints/
COPY /scripts/ /tools/scripts/
COPY /dev-patches/ /tools/dev-patches/

# Verify all files are copied correctly and set permissions
RUN Write-Host 'Verifying build stage contents:'; `
    Get-ChildItem -Path 'C:\\tools' -Recurse | ForEach-Object { Write-Host $_.FullName }; `
    Write-Host 'Setting permissions...'; `
    icacls 'C:\\tools' /grant 'Everyone:(OI)(CI)F' /T | Out-Null;

FROM ${BASE_IMAGE}

# Set PowerShell as the shell for the final stage
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Create tools directory in final image
RUN New-Item -Path 'C:\\tools' -ItemType 'Directory' -Force | Out-Null

# Copy tools from build stage (using specific approach for Windows)
COPY --from=build /tools/ /tools/

# Verify copy was successful using PowerShell
RUN if (Test-Path 'C:\\tools') { `
        Write-Host 'Tools directory verified successfully'; `
        Get-ChildItem -Path 'C:\\tools' -Recurse | Select-Object -First 10 | ForEach-Object { Write-Host $_.FullName }; `
    } else { `
        Write-Host 'ERROR: Tools directory not found'; `
        exit 1; `
    }