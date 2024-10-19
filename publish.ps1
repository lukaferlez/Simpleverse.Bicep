# Original: https://evotec.xyz/powershell-single-psm1-file-versus-multi-file-modules/
param (
	[Parameter(Mandatory=$true, Position=0, HelpMessage="The name of the module.")]
	[string] $name,
	[Parameter(Mandatory=$true, Position=1, HelpMessage="Powershell manifest path.")]
	[string] $psdPath,
	[Parameter(Mandatory=$true, Position=2, HelpMessage="Files to include in the module.")]
	[string] $pathSpec,
	[Parameter(Mandatory=$true, Position=3, HelpMessage="Version number.")]
    [string] $version,    
	[Parameter(Mandatory=$true, Position=4, HelpMessage="The API key to use when publishing.")]
    [string] $apiKey,
	[Parameter(Mandatory=$false, HelpMessage="Prerelease tag.")]
	[Alias("pr")]
	[string] $preReleaseTag
)

$path = split-path -parent $MyInvocation.MyCommand.Definition
Write-Host "Proceeding to publish all code found in $pathSpec"

if ($name -eq '') {
	$name = "build"
}

$workingDir = Join-Path $path "build"
$outFile = Join-Path $workingDir "$name.psm1"

if (!(Test-Path $workingDir)) {
    New-Item $workingDir -ItemType Directory
} elseif (Test-Path $outFile)  {
    Remove-Item $outFile
}

$files = Get-ChildItem -Recurse -Path $pathSpec
foreach ($file in $files) {
	$relativeFileName = Resolve-Path $file -Relative

	if ($file.Extension -ne '.ps1' -and $file.Extension -ne '.psm1') {
		Write-Host "Skipping $relativeFileName"
		continue
	}

	Write-Host "Combining $relativeFileName"

	$content = ''
	if ($file.Extension -eq '.ps1') {
		$results = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$null)
		$content = $results.EndBlock.Extent.Text
	} elseif ($file.Extension -eq '.psm1') {		
		$content = Get-Content $file		
	}
	$content | Add-Content -Path $outFile
}


Write-Output "All functions collapsed in single file $outFile"
# "Export-ModuleMember -Function * -Cmdlet *" | Add-Content -Path $outFile

# Now replace version in psd1
Write-Output "Processing psd1"
$psdOutFile = Join-Path $workingDir "$name.psd1"
$fileContent = Get-Content $psdPath
$fileContent = $fileContent -replace '{{modulePath}}', (Resolve-Path -Path $outFile -Relative -RelativeBasePath $workingDir)
$fileContent = $fileContent -replace '{{version}}', $version
$fileContent = $fileContent -replace '{{preReleaseTag}}', $preReleaseTag 
Set-Content $psdOutFile -Value $fileContent -Force

Write-Output "Publishing module"
Publish-Module `
    -Name $psdOutFile `
    -NuGetApiKey $apiKey `
    -Verbose `
	-Force