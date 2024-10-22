function Publish-Manifest {
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact= 'High')]
	param (
		[Parameter(Mandatory=$true, Position=0, HelpMessage="Powershell manifest path.", ValueFromPipeline = $true)]
		[string] $psdPath,
		[Parameter(Mandatory=$true, Position=1, HelpMessage="The API key to use when publishing.")]
		[Alias("ak")]
		[string] $apiKey,
		[Parameter(Mandatory=$false, HelpMessage="Force publish without confirmation.")]
		[Alias("f")]
		[switch] $Force
	)

	$relativePath = Resolve-Path $psdPath -Relative
	Write-InformationEx "Publishing manifest $($relativePath)" -ForegroundColor Green

	if ($Force -and -not $PSBoundParameters.ContainsKey('Confirm')) {
		$ConfirmPreference = 'None'
	}

	Write-Host $ConfirmPreference

	if ($PSCmdlet.ShouldProcess($relativePath)) {
		Publish-Module `
			-Name $psdPath `
			-NuGetApiKey $apiKey `
			-Force:$Force
	}
}