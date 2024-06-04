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
		# Type of service deployed. If it's native, we need to create a service using sc.exe
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet("Topshelf", "Native")]
		[string] $ServiceType,
		# Custom service name
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string] $ServiceName
	)
	Write-Host "DEPLOYMENT STARTED"
	
	$DestinationFolderPath = "D:\APPLICATIONS\$ProjectName\"
	$ExecutableFile = "$ProjectName.exe"
	$ExecutableFilePath = Join-Path $DestinationFolderPath $ExecutableFile
	$Session = Get-RemoteSession -Environment $Environment -Account $Account -Password $Password -Type "Console"

	# Stop and kill service
	Invoke-Command -Session $Session -ScriptBlock {
		$Service = Get-Service $Using:ServiceName -ErrorAction SilentlyContinue
		if ($Service) {
			Write-Host "Stopping service '$Using:ServiceName'... " -NoNewline
			Get-Service -ServiceName $Using:ServiceName | Stop-Service
			$Service.WaitForStatus('Stopped')
			Write-Host "Stopped!"
		}
	}
	Copy-FilesToRemoteSession -Session $Session -SourcePath .\$ProjectName\bin\$Environment -RemotePath $DestinationFolderPath
	
	# Install and start service
	Invoke-Command -Session $Session -ScriptBlock {
		switch ($ServiceType) {
			"Topshelf" {
				Write-Host "Installing and starting service... " -NoNewline
				Set-Location $Using:DestinationFolderPath 
				& .\$($Using:ExecutableFile) install
				Start-Service -Name $Using:ServiceName
				Write-Host "Installed and started !"
			}
			"Native" {
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
	Write-Host "DEPLOYMENT FINISHED"
}