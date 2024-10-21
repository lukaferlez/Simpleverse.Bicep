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

PS> Publish-BicepModule '*.bicep' someacr '2024.10.17.1' -cr 'd41eeb1c7c0a6a5e3f11efc175aa36b8eaae4af5..0ee2650f101237af9ad923ad2264d37b983d8bab'

.LINK

https://github.com/lukaferlez/Simpleverse.Bicep/blob/main/README.md

#>
function Publish-BicepModule {
	Param(
		[Parameter(Mandatory = $true, Position = 0, HelpMessage = "PathSpec to grep Bicep modules to publish.")]
		[ValidateNotNullOrWhiteSpace()]
		[string] $PathSpec,
		[Parameter(Mandatory = $true, Position = 1, HelpMessage = "Registry name of Azure container registry to which to publish.")]
		[ValidateNotNullOrWhiteSpace()]
		[string] $RegistryName,
		[Parameter(Mandatory = $true, Position = 2, HelpMessage = "Version to be tagged to published modules.")]
		[ValidateNotNullOrWhiteSpace()]
		[string] $Version,
		[Parameter(Mandatory = $false, HelpMessage = "Commit range to check for changes.")]
		[Alias("cr")]
		[string] $CommitRange,
		[Parameter(Mandatory = $false, HelpMessage = "Exclude direct changes to files in pathSpec from being published.")]
		[Alias("ed")]
		[switch] $ExcludeDirectChanges
	)

	$modulesToPublish = Get-BicepModuleForPublish $PathSpec $CommitRange -ExcludeDirectChanges:$ExcludeDirectChanges

	foreach ($module in $modulesToPublish) {
		Write-InformationEx "Publishing module $($module.Name) with version $($Version) to registry $($RegistryName)"
		az bicep publish --file $module.FilePath --target "br:$($RegistryName).azurecr.io/$($module.Name):$($Version)" --only-show-errors
	}
}

Export-ModuleMember Publish-BicepModule