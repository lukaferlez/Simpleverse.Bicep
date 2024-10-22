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

PS> Get-BicepModuleChanged '*.bicep' 'd41eeb1c7c0a6a5e3f11efc175aa36b8eaae4af5..0ee2650f101237af9ad923ad2264d37b983d8bab'

.LINK

https://github.com/lukaferlez/Simpleverse.Bicep/blob/main/README.md

#>
function Get-BicepModuleChanged {
	Param(
		[Parameter(Mandatory=$true,	Position=0, HelpMessage="PathSpec to grep Bicep modules to publish.")]
		[ValidateNotNullOrWhiteSpace()]
		[string] $PathSpec,
		[Parameter(Mandatory=$true,	Position=1, HelpMessage="Commit range to check for changes.")]
		[ValidateNotNullOrWhiteSpace()]
		[string] $CommitRange,
		[Parameter(Mandatory=$false, HelpMessage="Exclude direct changes to files in pathSpec from being published.")]
		[Alias("ed")]
		[switch] $ExcludeDirectChanges
	)

	Write-InformationEx "Get-BicepModuleChanged: $PathSpec - $CommitRange" -ForegroundColor Green

	$changedFiles = git diff-tree --no-commit-id --name-only --diff-filter=d -r $CommitRange $PathSpec
	Write-DebugEx "Found $($changedFiles.Count) changed files."
	$changedFiles | Format-Table | Out-String | Write-DebugEx

	$changedModules = @()
	foreach ($file in $changedFiles) {
		$changedModules += [BicepModule]::new($file)
	}

	Write-InformationEx "Get-BicepModuleChanged: Found $($changedModules.Count) changed modules." -ForegroundColor Green
	$changedModules | Select-Object Name, FilePath | Format-Table | Out-String | Write-InformationEx

	$bicepImports = Get-BicepModuleImport $PathSpec

	function Get-ImpactedModules2 {
		Param(
			[BicepModule] $changedModule,
			$imports
		)
		Write-DebugEx "Get-ImpactedModules: $($changedModule.FilePath) - Resolving impacted modules"

		$impactedModules = @($changedModule)

		$import = $imports | Where-Object { $_.Name -eq $changedModule.FilePath } | Select-Object -First 1
		if ($null -ne $import) {
			Write-DebugEx "Get-BicepModuleChanged: $($changedModule.FilePath) - Discovered dependecies"

			foreach($filePath in $import.FilePaths) {
				Write-DebugEx "Get-BicepModuleChanged: $($changedModule.FilePath) - Resolving impacted modules for $($filePath)"

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

	$impactedModules  = $impactedModules | Group-Object -Property 'Name', 'FilePath' | ForEach-Object { $_.Group | Select-Object 'Name', 'FilePath' -First 1 } | Sort-Object 'Name'
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

	Write-InformationEx "Get-BicepModuleChanged: Found $($impactedModules.Count) impacted modules." -ForegroundColor Green
	$impactedModules | Select-Object Name, FilePath | Format-Table | Out-String | Write-InformationEx

	return $impactedModules
}

Export-ModuleMember Get-BicepModuleChanged