using namespace System.Management.Automation

function Write-InformationEx
{
<#
	.SYNOPSIS
		Writes out a message in defined colors.

	.DESCRIPTION
		Enables writing of message in defined colors as with Write-Host, but replaces Write-Host as it is not the prefered way of writing output.

	.PARAMETER Message
		Message to writeout.

	.PARAMETER Background
		Background color of the text.

	.PARAMETER Foreground
		Foreground color of the text.

	.PARAMETER NoNewline
		Terminate with an new line or not.

	.PARAMETER noOutput
		Do not override InformationAction.

	.EXAMPLE
		PS C:\> Write-InformationEx 'Message' -Foreground 'Cyan' -Background 'White' -NoNewline

#>
	[CmdletBinding()]
	[OutputType([string])]
	param
	(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[Object]$Message,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrWhiteSpace()]
		[Alias("b")]
		[ConsoleColor]$BackgroundColor = $Host.UI.RawUI.BackgroundColor,
		[Parameter(Mandatory = $false)]
		[Alias("f")]
		[ValidateNotNullOrWhiteSpace()]
		[ConsoleColor]$ForegroundColor = $Host.UI.RawUI.ForegroundColor,
		[Parameter(Mandatory = $false)]
		[Alias("nn")]
		[Switch]$NoNewline,
		[Parameter(Mandatory = $false)]
		[Alias("no")]
		[Switch]$noOutput
	)
	BEGIN
	{}
	PROCESS
	{
		if ($null -eq $Message -or $Message -eq '') {
			return
		}

		[HostInformationMessage]$outMessage = @{
			Message				    = (Format-LogMessage -Message $Message -Level Information)
			ForegroundColor		    = $ForegroundColor
			BackgroundColor		    = $BackgroundColor
			NoNewline			    = $NoNewline
		}

		if ($noOutput) {
			Write-Information $outMessage
		} else {
			Write-Information $outMessage -InformationAction Continue
		}
	}
	END
	{}
}

