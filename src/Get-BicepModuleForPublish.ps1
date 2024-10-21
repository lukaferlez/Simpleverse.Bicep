<#
.SYNOPSIS

Lists all modules to be published based on pathspec.

.DESCRIPTION

The command will output modules on the pathspec that have been selected for publishing.

If a commit range is supplied the output will include only the modules that have been changed in the commit range and/or are impacted by the changes based on their imports.
If not the output will be all the files on the pathspec.

.INPUTS

None. You cannot pipe objects to Add-Extension.

.OUTPUTS

None.

.EXAMPLE

PS> Get-BicepModuleForPublish '*.bicep' 'd41eeb1c7c0a6a5e3f11efc175aa36b8eaae4af5..0ee2650f101237af9ad923ad2264d37b983d8bab'

.LINK

https://github.com/lukaferlez/Simpleverse.Bicep/blob/main/README.md

#>
function Get-BicepModuleForPublish {
	Param(
		[Parameter(Mandatory=$true,	Position=0, HelpMessage="PathSpec to grep Bicep modules to publish.")]
		[ValidateNotNullOrWhiteSpace()]
		[string] $PathSpec,
		[Parameter(Mandatory=$false, HelpMessage="Commit range to check for changes. If not supplied will return all files in pathSpec.")]
		[Alias("cr")]
		[string] $CommitRange,
		[Parameter(Mandatory=$false, HelpMessage="Exclude direct changes to files in pathSpec from being published.")]
		[Alias("ed")]
		[switch] $ExcludeDirectChanges
	)

	$modulesToPublish = @()
	if ($CommitRange -eq "") {
		$files = Get-ChildItem -Recurse -Path $PathSpec
		$modulesToPublish = @()
		foreach ($file in $files) {
			$modulesToPublish += [BicepModule]::new($file)
		}
	} else {
		$modulesToPublish = Get-BicepModuleChanged $PathSpec $CommitRange -ExcludeDirectChanges:$ExcludeDirectChanges
	}

	Write-InformationEx "Get-BicepModuleForPublish: Found $($modulesToPublish.Count) files to publish." -ForegroundColor Green
	$modulesToPublish | Format-Table | Out-String | Write-InformationEx

	return $modulesToPublish
}

Export-ModuleMember Get-BicepModuleForPublish