class BicepImport {
	[ValidateNotNullOrEmpty()][string]$Alias
	[ValidateNotNullOrEmpty()][string]$Name
	[string]$Version
	[string]$RegistryUrl
	[string]$LatestVersion
	[array]$FilePaths
}

function Get-BicepImports([string] $pathSpec) {
	Write-Host "Get-BicepImports: $pathSpec"
	$moduleReferences = Get-ChildItem -recurse -Path $pathSpec | Select-String -pattern "\bmodule\b", "\bimport\b" | Select-Object

	$modules = @()
	for(($index = 0); $index -lt $moduleReferences.Count; $index++) {
		$moduleReference = $moduleReferences[$index]

		Write-DebugIndexed $index "Reference $($moduleReference)"
		Write-DebugIndexed $index "Line: '$($moduleReference.Line)'"

		$beginIndex = $moduleReference.Line.IndexOf("'")+1
		$endIndex = $moduleReference.Line.IndexOf("'", $beginIndex)		
		Write-DebugIndexed $index "Begin: $($beginIndex) - End: $($endIndex)"

		$module = $moduleReference.Line.SubString($beginIndex, $endIndex - $beginIndex)
		Write-DebugIndexed $index "Module: '$($module)'"

		$alias = ''
		$name = ''
		$version = ''

		if ($module.Contains(':')) {
			$moduleParts = $module.Split(':')

			$alias = $moduleParts[0]
			$name = $moduleParts[1]
			$version = $moduleParts[2]
		} elseif ($module.Contains('@')) {
		} elseif ($module.Contains('.bicep')) {
			$fileDir = Split-Path -Path $moduleReference.Path -Parent
			Write-DebugIndexed $index "FileDir: $($fileDir)"
			$moduleName = Resolve-Path "$($fileDir)/$($module)" -Relative
			Write-DebugIndexed $index "ModuleName: $($moduleName)"

			$alias = '.'
			$name = $moduleName
			$version = ''
		}

		$existingModule = $modules | Where-Object { $_.Alias -eq $alias -And $_.Name -eq $name}
		if ($null -eq $existingModule) {
			$modules += [BicepImport]@{
				Alias = $alias
				Name = $name
				Version = $version
				FilePaths = @($moduleReference.Path)
			}
		} else  {
			if ($existingModule.FilePaths -notcontains $moduleReference.Path) {
				$existingModule.FilePaths += $moduleReference.Path
			}
		}
		Write-Debug "-------------- END REFERENCE $($index) --------------"
	}

	Write-Host "Get-BicepImports: Found $($modules.Count) imports." -ForegroundColor Green
	$modules | Select-Object Alias, Name, Version, FilePaths | Format-Table | Out-String | Write-Host
	return $modules
}

Export-ModuleMember Get-BicepImports

class BicepModule {
	[string] $FilePath
	[string] $Name

	BicepModule() {}

	BicepModule([string] $fullPath) {
		$this.FilePath = Resolve-Path -Relative $fullPath
		$this.Name = $this.FilePath -replace "^./" -replace '^.\\' -replace '\..*'
	}

	BicepModule([string] $filePath, [string] $name) {
		FilePath = $filePath
		Name = $name
	}
}

<#
.SYNOPSIS

Lists all modules impacted by changes in a defined commit range.

.DESCRIPTION

The command will output modules that have either been changed in the commit range or modules that have been impacted by the change. The module list will include

* modules added, edited or renamed
* modules that import or use modules added, edited or renamed

The command preforms the search recursively through all detected module files to build a complete list of impacted modules.

.INPUTS

None. You cannot pipe objects to Add-Extension.

.OUTPUTS

None.

.EXAMPLE

PS> Publish-BicepModules '*.bicep' 'd41eeb1c7c0a6a5e3f11efc175aa36b8eaae4af5..0ee2650f101237af9ad923ad2264d37b983d8bab'

.LINK

https://github.com/lukaferlez/Simpleverse.Bicep/blob/main/README.md

#>
function Get-BicepImpactedModules {
	Param(
		[Parameter(Mandatory=$true,	Position=0, HelpMessage="PathSpec to grep Bicep modules to publish.")]
		[string] $PathSpec,
		[Parameter(Mandatory=$true,	Position=1, HelpMessage="Commit range to check for changes.")]
		[string] $CommitRange,
		[Parameter(Mandatory=$false, HelpMessage="Exclude direct changes to files in pathSpec from being published.")]
		[Alias("ed")]
		[switch] $ExcludeDirectChanges
	)

	Write-Host "Get-ImpactedModules: $PathSpec - $CommitRange"	
	
	$changedFiles = git diff-tree --no-commit-id --name-only --diff-filter=d -r $CommitRange $PathSpec
	Write-Debug "Found $($changedFiles.Count) changed files."
	$changedFiles | Format-Table | Out-String | Write-Debug

	$changedModules = @()
	foreach ($file in $changedFiles) {
		$changedModules += [BicepModule]::new($file)
	}

	Write-Host "Get-ImpactedModules: Found $($changedModules.Count) changed modules." -ForegroundColor Green
	$changedModules | Select-Object Name, FilePath | Format-Table | Out-String | Write-Host

	$bicepImports = Get-BicepImports $PathSpec

	function Get-ImpactedModules2 {
		Param(
			[BicepModule] $changedModule,
			$imports
		)
		Write-Debug "Get-ImpactedModules: $($changedModule.FilePath) - Resolving impacted modules"

		$impactedModules = @($changedModule)

		$import = $imports | Where-Object { $_.Name -eq $changedModule.FilePath } | Select-Object -First 1
		if ($null -ne $import) {
			Write-Debug "Get-ImpactedModules: $($changedModule.FilePath) - Discovered dependecies"

			foreach($filePath in $import.FilePaths) {
				Write-Debug "Get-ImpactedModules: $($changedModule.FilePath) - Resolving impacted modules for $($filePath)"

				$module = [BicepModule]::new($filePath)
				$impactedModules += Get-ImpactedModules2 $module $imports
			}
		}

		return $impactedModules
	}

	$impactedModules = @()
	foreach($changedModule in $changedModules) {
		$impactedModules += Get-ImpactedModules2 $changedModule $bicepImports
	}

	$impactedModules  = $impactedModules | Group-Object -Property 'Name', 'FilePath' | %{ $_.Group | Select-Object 'Name', 'FilePath' -First 1 } | Sort-Object 'Name'
	if ($ExcludeDirectChanges) {
		$reducedModules = @()
		foreach ($module in $impactedModules) {
			$existingModule = $changedModules | Where-Object { $_.Name -eq $module.Name }
			if ($null -eq $existingModule) {
				$reducedModules += $module
			}
		}

		$impactedModules = $reducedModules
	}

	Write-Host "Get-ImpactedModules: Found $($impactedModules.Count) impacted modules." -ForegroundColor Green
	$impactedModules | Select-Object Name, FilePath | Format-Table | Out-String | Write-Host

	return $impactedModules
}

Export-ModuleMember Get-BicepImpactedModules


function Get-BicepModulesToPublish {
	Param(
		[Parameter(Mandatory=$true,	Position=0, HelpMessage="PathSpec to grep Bicep modules to publish.")]
		[string] $PathSpec,
		[Parameter(Mandatory=$true,	Position=1, HelpMessage="Commit range to check for changes.")]
		[string] $CommitRange,
		[Parameter(Mandatory=$false, HelpMessage="Include only changed Bicep modules.")]
		[Alias("c")]
		[switch] $IncludeNotChanged,
		[Parameter(Mandatory=$false, HelpMessage="Exclude direct changes to files in pathSpec from being published.")]
		[Alias("ed")]
		[switch] $ExcludeDirectChanges
	)

	$modulesToPublish = @()
	if ($IncludeNotChanged) {
		$files = Get-ChildItem -Recurse -Path $PathSpec
		$modulesToPublish = @()
		foreach ($file in $files) {
			$modulesToPublish += [BicepModule]::new($file)
		}
	} else {
		$modulesToPublish = Get-BicepImpactedModules $PathSpec $CommitRange -ExcludeDirectChanges:$ExcludeDirectChanges
	}

	Write-Host "Get-ModulesToPublish: Found $($modulesToPublish.Count) files to publish." -ForegroundColor Green
	$modulesToPublish | Format-Table | Out-String | Write-Host
	
	return $modulesToPublish
}

Export-ModuleMember Get-BicepModulesToPublish

<#
.SYNOPSIS

Publishes changed Bicep modules to the Azure Container Registry (ACR).

.DESCRIPTION

Extracts changed files based on a pathspec and commit range.
Checks for usage in imports and module declarations on the same pathspace.
Publishes changed modules and dependants with a new version to the registry.
Current support is limited to Azure Container Registry (ACR).

.INPUTS

None. You cannot pipe objects to Add-Extension.

.OUTPUTS

None.

.EXAMPLE

PS> Publish-BicepModules '*.bicep' 'd41eeb1c7c0a6a5e3f11efc175aa36b8eaae4af5..0ee2650f101237af9ad923ad2264d37b983d8bab' someacr '2024.10.17.1'

.LINK

https://github.com/lukaferlez/Simpleverse.Bicep/blob/main/README.md

#>
function Publish-BicepModules {
	Param(
		[Parameter(Mandatory = $true, Position = 0, HelpMessage = "PathSpec to grep Bicep modules to publish.")]
		[string] $PathSpec,
		[Parameter(Mandatory = $true, Position = 1, HelpMessage = "Commit range to check for changes.")]
		[string] $CommitRange,
		[Parameter(Mandatory = $true, Position = 2, HelpMessage = "Registry name of Azure container registry to which to publish.")]
		[string] $RegistryName,		
		[Parameter(Mandatory = $false, Position = 3, HelpMessage = "Version to be tagged to published modules.")]
		[string] $Version,
		[Parameter(Mandatory=$false, HelpMessage="Include only changed Bicep modules.")]
		[Alias("c")]
		[switch] $IncludeNotChanged,
		[Parameter(Mandatory = $false, HelpMessage = "Exclude direct changes to files in pathSpec from being published.")]
		[Alias("ed")]
		[switch] $ExcludeDirectChanges
	)

	$modulesToPublish = Get-BicepModulesToPublish $PathSpec $CommitRange -IncludeNotChanged:$IncludeNotChanged -ExcludeDirectChanges:$ExcludeDirectChanges

	foreach ($module in $modulesToPublish) {
		Write-Host "Publishing module $($module.Name) with version $($Version) to registry $($RegistryName)"
		az bicep publish --file $module.FilePath --target "br:$($RegistryName).azurecr.io/$($module.Name):$($Version)" --only-show-errors
	}
}

Export-ModuleMember Publish-BicepModules

class FileToUpdate {
	[string]$Path
	[array]$Modules
}

<#
.SYNOPSIS

Updates the versions of the imports & modules from custom repositories to the latest version available in the registry.

.DESCRIPTION

Extracts from all files mathcing the pathspec, imports & module declarations that are using the custom repository syntax alias:modulename:version.
Checks a newer version in the registry and updates the version in the files to the latest version available in the registry.
Current support is limited to Azure Container Registry (ACR).

.INPUTS

None. You cannot pipe objects to Add-Extension.

.OUTPUTS

None.

.EXAMPLE

PS> Update-BicepModulesVersion '*.bicep'

.LINK

https://github.com/lukaferlez/Simpleverse.Bicep/blob/main/README.md

#>
function Update-BicepModulesVersion {
	Param(
		[Parameter(Mandatory = $true, Position = 0, HelpMessage = "PathSpec to grep Bicep modules to update.")]
		[string] $PathSpec,
		[Parameter(Mandatory = $false, HelpMessage = "Path to bicepconfig.json with defined registries.")]
		[Alias("b")]
		[string] $BicepConfigPath = 'bicepconfig.json'
	)

	$modules = Get-BicepImports $PathSpec | Where-Object { $_.Alias -ne '.' }

	Write-Host "Found $($modules.Count) modules." -ForegroundColor Green
	$modules | Select-Object Alias, Name, Version | Format-Table | Out-String | Write-Host

	Write-Host "Gathering latest versions from registry source."
	$bicepConfig = Get-Content $BicepConfigPath | ConvertFrom-Json -AsHashtable
	foreach ($module in $modules) {
		$aliasSplit = $module.Alias.Split("/")
		$module.registryUrl = $bicepConfig['moduleAliases'][$aliasSplit[0]][$aliasSplit[1]]['registry']
		Write-Host "Checking $($module.Alias) from registry $($module.registryUrl) for $($module.Name)"
		$module.LatestVersion = az acr repository show-tags --name $module.RegistryUrl.Replace('.azurecr.io', '') --repository $module.Name --top 1 --orderby time_desc | ConvertFrom-Json
	}

	$modulesForUpdate = $modules | Where-Object { $_.Version -ne $_.LatestVersion }

	if ($modulesForUpdate.Count -eq 0) {
		Write-Host "All modules are up to date." -ForegroundColor Green
		return
	}

	Write-Host "Modules to update."
	$modules | Where-Object { $_.Version -ne $_.LatestVersion } | Select-Object Alias, Name, Version, LatestVersion | Format-Table

	$update = Read-Host "Update? (Y/N)"
	if ($update -ne 'Y' -or $update -ne 'y') {
		return
	}

	$filesToUpdate = @()
	foreach ($module in $modules | Where-Object { $_.Version -ne $_.LatestVersion }) {
		foreach ($filePath in $module.FilePaths) {
			$existingFilePath = $filesToUpdate | Where-Object { $_.Path -eq $filePath }
			if ($null -eq $existingFilePath) {
				$filesToUpdate += [FileToUpdate]@{
					Path = $filePath
					Modules = @($module)
				}
			} else {
				$existingFilePath.Modules += $module
			}
		}
	}

	$filesToUpdate | Format-Table | Out-String | Write-Host

	foreach ($fileToUpdate in $filesToUpdate) {
		$content = Get-Content $fileToUpdate.Path
		foreach ($module in $fileToUpdate.Modules) {
			$content = $content -replace "$($module.Alias):$($module.Name):$($module.Version)", "$($module.Alias):$($module.Name):$($module.LatestVersion)"
		}
		Set-Content -Path $fileToUpdate.Path -Value $content
	}

	Write-Host "Updated $($filesToUpdate.Count) files." -ForegroundColor Green
}

Export-ModuleMember Update-BicepModulesVersion

function Write-DebugIndexed {
	Param(
		[int] $index,
		[string] $message
	)
	Write-Debug "Reference #$($index) - $($message)"
}

