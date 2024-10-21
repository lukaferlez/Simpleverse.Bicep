
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

PS> Update-BicepModuleVersion '*.bicep'

.LINK

https://github.com/lukaferlez/Simpleverse.Bicep/blob/main/README.md

#>
function Update-BicepModuleVersion {
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact= 'High')]
	Param(
		[Parameter(Mandatory = $true, Position = 0, HelpMessage = "PathSpec to grep Bicep modules to update.")]
		[ValidateNotNullOrWhiteSpace()]
		[string] $PathSpec,
		[Parameter(Mandatory = $false, HelpMessage = "Path to bicepconfig.json with defined registries.")]
		[Alias("b")]
		[string] $BicepConfigPath = 'bicepconfig.json'
	)

	$modules = Get-BicepModuleImport $PathSpec | Where-Object { $_.Alias -ne '.' }

	Write-InformationEx "Found $($modules.Count) modules." -ForegroundColor Green
	$modules | Select-Object Alias, Name, Version | Format-Table | Out-String | Write-InformationEx

	Write-InformationEx "Gathering latest versions from registry source."
	$bicepConfig = Get-Content $BicepConfigPath | ConvertFrom-Json -AsHashtable
	foreach ($module in $modules) {
		$aliasSplit = $module.Alias.Split("/")
		$module.registryUrl = $bicepConfig['moduleAliases'][$aliasSplit[0]][$aliasSplit[1]]['registry']
		Write-InformationEx "Checking $($module.Alias) from registry $($module.registryUrl) for $($module.Name)"
		$module.LatestVersion = az acr repository show-tags --name $module.RegistryUrl.Replace('.azurecr.io', '') --repository $module.Name --top 1 --orderby time_desc | ConvertFrom-Json
	}

	$modulesForUpdate = $modules | Where-Object { $_.Version -ne $_.LatestVersion }

	if ($modulesForUpdate.Count -eq 0) {
		Write-InformationEx "All modules are up to date." -ForegroundColor Green
		return
	}

	Write-InformationEx "Modules to update."
	$modules | Where-Object { $_.Version -ne $_.LatestVersion } | Select-Object Alias, Name, Version, LatestVersion | Format-Table | Out-String | Write-InformationEx

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

	$filesToUpdate | Format-Table | Out-String | Write-InformationEx

	if ($PSCmdlet.ShouldProcess($filesToUpdate.Path, "Update")) {
		foreach ($fileToUpdate in $filesToUpdate) {
			$content = Get-Content $fileToUpdate.Path
			foreach ($module in $fileToUpdate.Modules) {
				$content = $content -replace "$($module.Alias):$($module.Name):$($module.Version)", "$($module.Alias):$($module.Name):$($module.LatestVersion)"
			}
			Set-Content -Path $fileToUpdate.Path -Value $content
		}

		Write-InformationEx "Updated $($filesToUpdate.Count) files." -ForegroundColor Green
	}
}

Export-ModuleMember Update-BicepModuleVersion

