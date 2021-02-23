@{
    RootModule              = 'SitecoreDockerTools.psm1'
    GUID                    = '36f0f2d9-8a8a-461f-b54f-3fb109f30b70'
    Author                  = 'Sitecore Corporation A/S'
    CompanyName             = 'Sitecore Corporation A/S'
    Copyright               = 'Copyright (C) by Sitecore A/S'
    Description             = 'PowerShell extensions for Docker-based Sitecore development'
    ModuleVersion           = '0.0.1'
    PowerShellVersion       = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @('Get-SitecoreRandomString','ConvertTo-CompressedBase64String','Get-SitecoreCertificateAsBase64String','Set-EnvFileVariable','Add-HostsEntry','Remove-HostsEntry','Write-SitecoreDockerWelcome','Get-EnvFileVariable')

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    # VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @('Set-DockerComposeEnvFileVariable')

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            Tags            = @('sitecore','docker','powershell')
            LicenseUri      = 'https://doc.sitecore.net/~/media/C23E989268EC4FA588108F839675A5B6.pdf'
            ProjectUri      = 'https://github.com/Sitecore/docker-tools'
            IconUri         = 'https://mygetwwwsitecoreeu.blob.core.windows.net/feedicons/sc-packages.png'
        }
    }
}

