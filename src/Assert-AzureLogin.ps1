function Assert-AzureLogin {
	if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
		throw "Azure CLI (az) is not installed or not in PATH."
	}

	az account show 2>&1 | Out-Null
	if ($LASTEXITCODE -ne 0) {
		throw "Not logged in to Azure CLI. Please run 'az login' before using this command."
	}
}
