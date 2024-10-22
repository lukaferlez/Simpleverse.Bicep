using namespace System.Io

function Build-Module {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0, HelpMessage = "Files to include in the module.", ValueFromPipeline = $true)]
		[FileInfo[]] $moduleFiles,
		[Parameter(Mandatory = $true, HelpMessage = "Name of the module.")]
		[ValidateNotNullOrWhiteSpace()]
		[Alias("n")]
		[string] $name,
		[Parameter(Mandatory = $false, HelpMessage = "Build folder.")]
		[Alias("b")]
		[string] $buildPath = './'
	)
	BEGIN
	{}
	PROCESS
	{
		Write-InformationEx "Building module $name" -ForegroundColor 'Green'

		$using = @()
		$content = @()

		foreach ($file in $moduleFiles) {
			$relativeFileName = Resolve-Path $file -Relative
			if ($file.Extension -ne '.ps1' -and $file.Extension -ne '.psm1') {
					Write-InformationEx "Skipping $relativeFileName" -ForegroundColor Yellow
					continue
			}
			
			Write-InformationEx "Reading $relativeFileName"
			if ($file.Extension -eq '.ps1') {
				$results = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$null)
				if ($results.UsingStatements.Count -gt 0) {
					$results.UsingStatements | Select-Object Extent | Format-Table | Out-String | Write-DebugEx 
				}
				$using += $results.UsingStatements
				$content += $results.EndBlock.Extent.Text
			}
			elseif ($file.Extension -eq '.psm1') {
				$content = Get-Content $file
			}
		}

		$workingDir = Join-Path $buildPath "build/($name)"
		$outFile = Join-Path $workingDir "$name.psm1"
# 
		Write-DebugEx "Working directory $workingDir"
		Write-DebugEx "Output file $outFile"
# 
		if (!(Test-Path $workingDir)) {
			Write-DebugEx "Creating $workingDir"
			$newDir = New-Item $workingDir -ItemType Directory -WhatIf:$false
		}
		elseif (Test-Path $outFile) {
			Write-DebugEx "Removing $outFile"
			Remove-Item $outFile -WhatIf:$false
		}
# 
		Write-InformationEx "Combining into $outFile"
		$using | Add-Content -Path $outFile -WhatIf:$false
		$content | Add-Content -Path $outFile -WhatIf:$false

		Resolve-Path $outFile | Write-DebugEx

		Write-InformationEx "Built module $name to $outFile"

		return $outFile
	}
	END
	{}
}