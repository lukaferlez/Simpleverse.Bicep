param (
		[Parameter(Mandatory=$true, Position=0, HelpMessage="Module version.")]
		[Alias("v")]
		[string] $version
	)

. "src/log/Format-LogMessage.ps1"
. "src/log/Format-Message.ps1"
. "src/log/Write-DebugEx.ps1"
. "src/log/Write-InformationEx.ps1"
. "src/build/Build-Module.ps1"
. "src/build/Build-Manifest.ps1"

$moduleFiles = Get-ChildItem './src/log/*.ps1', './src/*.ps1' | Resolve-Path -Relative

Write-InformationEx "Analyzing script file" -ForegroundColor Green
foreach ($moduleFile in $moduleFiles) {
	Write-InformationEx "Analyzing $moduleFile"
	Invoke-ScriptAnalyzer $moduleFile
}

$moduleFile = ,$moduleFiles | Build-Module -n 'Simpleverse.Bicep'

return Build-Manifest 'Simpleverse.Bicep' './src/manifest.psd1' $moduleFile $version