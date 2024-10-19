# Module manifest for module 'Simpleverse-Bicep'

@{

	# Script module or binary module file associated with this manifest.
	RootModule = '{{modulePath}}'
	
	# Version number of this module.
	ModuleVersion     = '{{version}}'
	
	# Supported PSEditions
	# CompatiblePSEditions = @()
	
	# ID used to uniquely identify this module
	GUID              = '48b779c6-c4d0-42a9-a51f-004f76bd1114'
	
	# Author of this module
	Author            = 'luka@ferlez.hr'
	
	# Company or vendor of this module
	CompanyName       = 'Simpleverse'
	
	# Copyright statement for this module
	Copyright         = '(c) luka@ferlez. All rights reserved.'
	
	# Description of the functionality provided by this module
	Description = 'Simplifies operations with custom Bicep modules and version maintenance.
		* Get-BicepImports - Returns list of imports/modules used in Bicep files.
		* Get-BicepImpactedModules - Returns list of impacted modules impacted by changes between two commits. It will include modules changes following the import hierarchy provuiding a full list of impacted modules.
		* Get-BicepModulesToPublish - Returns list of Bicep modules to publish based on the changes between two commits or all modules based on parameters. It will include modules changes following the import hierarchy provuiding a full list of impacted modules.
		* Publish-BicepModules - Publishes Bicep modules to Azure ACR.
		* Update-BicepModulesVersion - Updates the version of the imports & modules from custom repositories to the latest version available in the registry. Currently supports only Azure ACR.
	'
	
	# Minimum version of the PowerShell engine required by this module
	PowerShellVersion = '7.0'
	
	# Name of the PowerShell host required by this module
	# PowerShellHostName = ''
	
	# Minimum version of the PowerShell host required by this module
	# PowerShellHostVersion = ''
	
	# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
	# DotNetFrameworkVersion = ''
	
	# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
	# CLRVersion = ''
	
	# Processor architecture (None, X86, Amd64) required by this module
	# ProcessorArchitecture = ''
	
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
	FunctionsToExport = @("Update-BicepModulesVersion", "Publish-BicepModules", "Get-BicepModulesToPublish", "Get-BicepImports", "Get-BicepImpactedModules")
	
	# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
	CmdletsToExport   = @()
	
	# Variables to export from this module
	VariablesToExport = '*'
	
	# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
	AliasesToExport   = @()
	
	# DSC resources to export from this module
	# DscResourcesToExport = @()
	
	# List of all modules packaged with this module
	# ModuleList = @()
	
	# List of all files packaged with this module
	# FileList = @()
	
	# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData       = @{
	
		PSData = @{
	
			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = "Bicep", "Azure", "ACR", "Publish", "Version"
	
			# A URL to the license for this module.
			LicenseUri = 'https://github.com/lukaferlez/Simpleverse.Bicep?tab=MIT-1-ov-file#readme'
	
			# A URL to the main website for this project.
			ProjectUri = 'https://github.com/lukaferlez/Simpleverse.Bicep'
	
			# A URL to an icon representing this module.
			# IconUri = ''
	
			# ReleaseNotes of this module
			# ReleaseNotes = ''
	
			# Prerelease string of this module
			# Prerelease = '{{preReleaseTag}}'
	
			# Flag to indicate whether the module requires explicit user acceptance for install/update/save
			# RequireLicenseAcceptance = $false
	
			# External dependent modules of this module
			# ExternalModuleDependencies = @()
	
		} # End of PSData hashtable
	
	} # End of PrivateData hashtable
	
	# HelpInfo URI of this module
	# HelpInfoURI = ''
	
	# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
	# DefaultCommandPrefix = ''
	
}