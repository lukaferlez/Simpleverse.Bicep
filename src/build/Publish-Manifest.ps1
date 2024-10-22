function Publish-Manifest {
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact= 'High')]
	param (
		[Parameter(Mandatory=$true, Position=0, HelpMessage="Powershell manifest path.", ValueFromPipeline = $true)]
		[string] $psdPath,
		[Parameter(Mandatory=$true, Position=1, HelpMessage="The API key to use when publishing.")]
		[Alias("ak")]
		[string] $apiKey
	)

	$relativePath = Resolve-Path $psdPath -Relative
	Write-InformationEx "Publishing manifest $($relativePath)" -ForegroundColor Green

	if ($PSCmdlet.ShouldProcess($relativePath)) {
		Publish-Module `
			-Name $psdPath `
			-NuGetApiKey $apiKey `
			-Force
	}
}