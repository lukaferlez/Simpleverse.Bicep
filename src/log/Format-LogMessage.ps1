enum LogLevel
{
	Verbose
	Debug
	Information
	Warning
	Error
}

function Format-LogMessage {
	[CmdletBinding()]
	[OutputType([string])]
	param(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[Object] $Message,
		[Parameter(Mandatory = $true, Position = 1)]
		[Alias("l")]
		[LogLevel] $Level
	)
	BEGIN
	{}
	PROCESS
	{
		if ($level -eq [LogLevel]::Debug) {
			return "[$(Get-Date -format "yyyy-MM-dd HH:mm:ss.fff")] $($Message)"
		}

		switch ($Level) {
			Verbose { $prefix = 'VERBOSE' }
			Debug { $prefix = '' }
			Information { $prefix = 'INFO' }
			Warning { $prefix = 'WARNING' }
			Error { $prefix = 'ERROR' }
		}

		return "$($prefix): [$(Get-Date -format "yyyy-MM-dd HH:mm:ss.fff")] $($Message)"
	}
	END
	{}
}