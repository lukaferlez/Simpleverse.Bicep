function Write-DebugEx {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[Object] $Message
	)
	BEGIN
	{}
	PROCESS
	{
		if ($null -eq $Message -or $Message -eq '') {
			return
		}

		Format-LogMessage -Message $Message -Level Debug | Write-Debug
	}
	END
	{}
}