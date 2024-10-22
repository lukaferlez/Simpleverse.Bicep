class BicepImport {
	[ValidateNotNullOrEmpty()][string]$Alias
	[ValidateNotNullOrEmpty()][string]$Name
	[string]$Version
	[string]$RegistryUrl
	[string]$LatestVersion
	[array]$FilePaths
}

function Get-BicepModuleImport([string] $pathSpec) {
	Write-InformationEx "Get-BicepModuleImport: $pathSpec" -ForegroundColor Green
	$moduleReferences = Get-ChildItem -recurse -Path $pathSpec | Select-String -pattern "\bmodule\b", "\bimport\b" | Select-Object

	$modules = @()
	for(($index = 0); $index -lt $moduleReferences.Count; $index++) {
		$moduleReference = $moduleReferences[$index]

		Format-Message "Reference $($moduleReference)" -Index $index | Write-DebugEx
		Format-Message "Line: '$($moduleReference.Line)'" -Index $index | Write-DebugEx

		$beginIndex = $moduleReference.Line.IndexOf("'")+1
		$endIndex = $moduleReference.Line.IndexOf("'", $beginIndex)
		Format-Message "Begin: $($beginIndex) - End: $($endIndex)" -Index $index | Write-DebugEx

		$module = $moduleReference.Line.SubString($beginIndex, $endIndex - $beginIndex)
		Format-Message "Module: '$($module)'" -Index $index | Write-DebugEx

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
			Format-Message "FileDir: $($fileDir)" -Index $index | Write-DebugEx
			$moduleName = Resolve-Path "$($fileDir)/$($module)" -Relative
			Format-Message "ModuleName: $($moduleName)" -Index $index | Write-DebugEx

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
		Write-DebugEx "-------------- END REFERENCE $($index) --------------"
	}

	Write-InformationEx "Get-BicepModuleImport: Found $($modules.Count) imports." -ForegroundColor Green
	$modules | Select-Object Alias, Name, Version, FilePaths | Format-Table | Out-String | Write-InformationEx
	return $modules
}

Export-ModuleMember Get-BicepModuleImport