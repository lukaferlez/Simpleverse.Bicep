[CmdletBinding(SupportsShouldProcess, ConfirmImpact= 'High')]
param(
	[Parameter(Mandatory=$true, Position=0, HelpMessage="Module version.")]
	[Alias("v")]
	[string] $version,
	[Parameter(Mandatory=$true, Position=1, HelpMessage="The API key to use when publishing.")]
	[Alias("ak")]
	[string] $apiKey,
	[Parameter(Mandatory=$false, HelpMessage="Force publish without confirmation.")]
	[Alias("f")]
	[switch] $Force
)

. "./src/log/Format-LogMessage.ps1"
. "./src/log/Format-Message.ps1"
. "./src/log/Write-DebugEx.ps1"
. "./src/log/Write-InformationEx.ps1"
. "./src/build/Publish-Manifest.ps1"

./Build-SimpleverseBicep -v $version | Publish-Manifest -ak $apiKey -f:$Force -WhatIf:$WhatIfPreference