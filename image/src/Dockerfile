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

FROM ${BASE_IMAGE}

# Copy resulting tools
COPY --from=build /tools/ /tools/