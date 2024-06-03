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
		[string] $ServiceName,
		# Type of service deployed. If it's native, we need to create a service using sc.exe
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet("Topshelf", "Native")]
		[string] $ServiceType
	)
	Write-Host "DEPLOYMENT STARTED"
	
	$DestinationFolderPath = "D:\APPLICATIONS\$ProjectName\"
	$ExecutableFile = "$ProjectName.exe"
	$ExecutableFilePath = Join-Path $DestinationFolderPath $ExecutableFile
	$Session = Get-RemoteSession -Environment $Environment -Account $Account -Password $Password -Type "Console"

	# Stop and kill service
	Invoke-Command -Session $Session -ScriptBlock {
		if (Get-Service $Using:ServiceName -ErrorAction SilentlyContinue) {
			Write-Host "Stopping service '$Using:ServiceName'" -NoNewline
			Get-Service -ServiceName $Using:ServiceName | Stop-Service
			Write-Host "Stopped!"
		} else {
			if ($Using:ServiceType -eq "Native") {
				Write-Host "No service exists, creating service '$Using:ServiceName'"
				sc.exe create $Using:ServiceName binPath=$Using:ExecutableFilePath
				Write-Host "Service created"
			}
		}
		if (Get-Process $Using:ExecutableFile -ErrorAction SilentlyContinue) {
			Write-Host "Killing process '$Using:ExecutableFile'... " -NoNewline
			Get-Process $Using:ExecutableFile -ErrorAction SilentlyContinue | Stop-Process -PassThru -Force
			Write-Host "Killed!"
		}
	}
	
	Start-Sleep -Milliseconds 10000 # wait 10 seconds
	Copy-FilesToRemoteSession -Session $Session -SourcePath .\$ProjectName\bin\$Environment -RemotePath $DestinationFolderPath
	
	Write-Host "Installing and starting service... "

	# Install and start service
	switch ($ServiceType) {
		"Topshelf" {
			Invoke-Command -Session $Session -ScriptBlock {
				cd $Using:DestinationFolderPath 
				& .\$($Using:ExecutableFile) install
				Start-Service -Name $Using:ServiceName
				Write-Host "Installed and started !"
			}
		}
		"Native" {
			Invoke-Command -Session $Session -ScriptBlock {
				Start-Service -Name $Using:ServiceName
				Write-Host "Installed and started !"
			}
		}
	}
}