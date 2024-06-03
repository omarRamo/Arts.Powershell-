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
			Write-Host "Stopping service '$Using:ServiceName'... " -NoNewline
			Get-Service -ServiceName $Using:ServiceName | Stop-Service
			if (Get-Process -Name $Using:ProjectName -ErrorAction SilentlyContinue) {
				Write-Host "Stopping process ... " -NoNewline
				Wait-Process -Name $Using:ProjectName
				Write-Host "Process stopped"
			}
			Write-Host "Stopped!"
		}
	}
	
	Copy-FilesToRemoteSession -Session $Session -SourcePath .\$ProjectName\bin\$Environment -RemotePath $DestinationFolderPath
	
	# Install and start service
	switch ($ServiceType) {
		"Topshelf" {
			Invoke-Command -Session $Session -ScriptBlock {
				Write-Host "Installing and starting service... " -NoNewline
				cd $Using:DestinationFolderPath 
				& .\$($Using:ExecutableFile) install
				Start-Service -Name $Using:ServiceName
				Write-Host "Installed and started !"
			}
		}
		"Native" {
			Invoke-Command -Session $Session -ScriptBlock {
				if (!(Get-Service $Using:ServiceName -ErrorAction SilentlyContinue)) {
					Write-Host "No service exists, creating service '$Using:ServiceName'... " -NoNewline
					sc.exe create $Using:ServiceName binPath=$Using:ExecutableFilePath
					Write-Host "Service created"
				}
				Write-Host "Installing and starting service... " -NoNewline
				Start-Service -Name $Using:ServiceName
				Write-Host "Installed and started !"
			}
		}
	}
}