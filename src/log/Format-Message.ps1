function Format-Message {
	[CmdletBinding()]
	[OutputType([string])]
	param(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[Object] $Message,
		[Parameter(Mandatory = $false)]
		[Nullable[System.Int32]] $Index
	)
	BEGIN
	{}
	PROCESS
	{
		if ($null -eq $Index) {
			return "$($Message)"
		} else {
			return "[#$($index)] $($message)"
		}
	}
	END
	{}
}