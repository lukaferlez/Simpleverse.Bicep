function Build-Manifest {
	param (
		[Parameter(Mandatory = $true, Position = 0, HelpMessage = "The name of the module.")]
		[string] $name,
		[Parameter(Mandatory = $true, Position = 1, HelpMessage = "Powershell manifest path.")]
		[string] $psdPath,
		[Parameter(Mandatory = $true, Position = 2, HelpMessage = "Powershell module path.")]
		[string] $psmPath,
		[Parameter(Mandatory = $true, Position = 3, HelpMessage = "Version number.")]
		[string] $version,
		[Parameter(Mandatory = $false, HelpMessage = "Prerelease tag.")]
		[Alias("pr")]
		[string] $preReleaseTag,
		[Parameter(Mandatory = $false, HelpMessage = "Build folder.")]
		[Alias("b")]
		[string] $buildPath = './'
	)

	Write-InformationEx "Processing manifest $($psdPath)" -ForegroundColor Green

	$workingDir = Join-Path $buildPath "build/($name)" | Resolve-Path
	Write-DebugEx "Working directory $workingDir"

	$psmPath = Resolve-Path $psmPath	
	Write-DebugEx "Module path $psmPath"

	$psdOutFile = Join-Path $workingDir "$name.psd1"
	Write-DebugEx "Manifest output path $psdOutFile"

	$modulePath = Resolve-Path $psmPath -Relative -RelativeBasePath $workingDir
	Write-DebugEx "Module path $modulePath"

	$fileContent = Get-Content $psdPath
	Write-InformationEx "Set RootModule $modulePath"
	$fileContent = $fileContent -replace '{{modulePath}}', $modulePath
	Write-InformationEx "Set ModuleVersion $version"
	$fileContent = $fileContent -replace '{{version}}', $version
	Write-InformationEx "Set Prerelease $preReleaseTag"	
	$fileContent = $fileContent -replace '{{preReleaseTag}}', $preReleaseTag 
	Set-Content $psdOutFile -Value $fileContent -Force

	return $psdOutFile
}