[CmdletBinding(SupportsShouldProcess, ConfirmImpact= 'High')]
param(
	[Parameter(Mandatory=$true, Position=0, HelpMessage="Module version.")]
	[Alias("v")]
	[string] $version,
	[Parameter(Mandatory=$true, Position=1, HelpMessage="The API key to use when publishing.")]
	[Alias("ak")]
	[string] $apiKey
)

. "./src/log/Format-LogMessage.ps1"
. "./src/log/Format-Message.ps1"
. "./src/log/Write-DebugEx.ps1"
. "./src/log/Write-InformationEx.ps1"
. "./src/build/Publish-Manifest.ps1"

./Build-SimpleverseBicep -v $version

# $filePath = ./Build-SimpleverseBicep -v $version
# 
# Write-InformationEx $filePath
# 
# $filePath | Publish-Manifest -ak $apiKey -Confirm:$ConfirmPreference -WhatIf:$WhatIfPreference