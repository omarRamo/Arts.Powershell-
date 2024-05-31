<#
.SYNOPSIS
    Deploy windows service application
.DESCRIPTION
    This script allows you to copy the files resulting from the generation of a windows service. 
	It also kills the associated process, and restarts the service.
#>
function Send-WindowsServiceApp {
	param(
		# Environment name
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string] $Environment,
		# Account name
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string] $Account,
		# Password
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string] $Password,
		# App project Name
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string] $ProjectName,
		# Windows service Name
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string] $ServiceName
	)
	Write-Host "DEPLOYMENT STARTED"
	
	$DestinationFolderPath = "D:\APPLICATIONS\$ProjectName\"
	$ExecutableFile = "$ProjectName.exe"
	$Session = Get-RemoteSession -Environment $Environment -Account $Account -Password $Password -Type "Console"

	# Stop and kill service
	Invoke-Command -Session $Session -ScriptBlock {
		if (Get-Service $Using:ServiceName -ErrorAction SilentlyContinue) {
			Write-Host "Stopping service '$Using:ServiceName'" -NoNewline
			Get-Service -ServiceName $Using:ServiceName | Stop-Service
			Write-Host "Stopped!"
		}
		if (Get-Process $Using:ExecutableFile -ErrorAction SilentlyContinue) {
			Write-Host "Killing process '$Using:ExecutableFile'... " -NoNewline
			Get-Process $Using:ExecutableFile -ErrorAction SilentlyContinue | Stop-Process -PassThru -Force
			Write-Host "Killed!"
		}
	}
	
	Start-Sleep -Milliseconds 10000 # wait 10 seconds
	Copy-FilesToRemoteSession -Session $Session -SourcePath .\$ProjectName\bin\$Environment -RemotePath $DestinationFolderPath
	
	# Install and start service
	Invoke-Command -Session $Session -ScriptBlock {
		Write-Host "Installing and starting service... " -NoNewline
		& (Join-Path $Using:DestinationFolderPath $Using:ExecutableFile) install
		Start-Service -Name $Using:ServiceName
		Write-Host "Installed and started !"
	}
}