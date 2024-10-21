# Simpleverse.Bicep

Powershell module to enable simplified operations with custom Bicep modules and version maintenance.

* Listing changed bicep modules between two commits
* Publishing modules to an Azure Container Registry
* Updating the used version in Bicep files from an Azure Container registry

## Instalation
Module is published to the Powershell Gallery https://www.powershellgallery.com/packages/Simpleverse.Bicep.

```
PS> Install-Module -Name Simpleverse.Bicep
```

## Listing changed modules
Lists all modules impacted by changes in a defined commit range.

```
PS> Get-BicepModuleChanged '*.bicep' 'd41eeb1c7c0a6a5e3f11efc175aa36b8eaae4af5..0ee2650f101237af9ad923ad2264d37b983d8bab'
```

The command will output modules that have either been changed in the commit range or modules that have been impacted by the change. The module list will include

* modules added, edited or renamed
* modules that import or use modules added, edited or renamed

The command preforms the search recursively through all detected module files to build a complete list of impacted modules.

Why? Publishing to a registry forces the modules to be compiled to json meaning that all dependencies are pulled into the module at compile time. Editing & publishing just dependencies will not change the modules importing them.

## Publish bicep modules
Publishes selected modules to an **Azure Container Registry**.

### Publish all files
```
PS> Publish-BicepModule '*.bicep' someacr '2024.10.17.1'
```

### Publish changed files in commit range
```
PS> Publish-BicepModule '*.bicep' someacr '2024.10.17.1' -cr 'd41eeb1c7c0a6a5e3f11efc175aa36b8eaae4af5..0ee2650f101237af9ad923ad2264d37b983d8bab'
```

The command will use **Get-BicepModuleChanged** to determine a list of modules to publish and will publish them to the defined registry with the supplied version number.

## Update bicep modules version
Updates the versions of the imports & modules from custom repositories to the latest version available in the registry.

```
PS> Update-BicepModuleVersion '*.bicep'
```

Extracts from all files matching the pathspec, imports & module declarations that are using the custom repository syntax alias:modulename:version.
Checks a newer version in the registry and updates the version in the files to the latest version available in the registry.

[!NOTE]
Current support is limited to Azure Container Registry (ACR).