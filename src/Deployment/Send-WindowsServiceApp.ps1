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
		[string] $ServiceName,
		# Hosting type
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet("Web", "Console")]
		[string] $HostingType = "Console"
	)
	Write-Host "DEPLOYMENT STARTED"
	
	$DestinationFolderPath = "D:\SOFT\$ProjectName\"
	$ExecutableFile = "$ProjectName.exe"
	$ExecutableFilePath = Join-Path $DestinationFolderPath $ExecutableFile
	$sessions = Get-RemoteSessions -Environment $Environment -Account $Account -Password $Password -Type $HostingType

	foreach($session in $sessions) {
		# Stop and kill service
		Invoke-Command -Session $session -ScriptBlock {
			$SvcArtsUsername = [Environment]::GetEnvironmentVariable("Credentials.Svc.Username", "Machine")
			$SvcArtsPassword = [Environment]::GetEnvironmentVariable("Credentials.Svc.Password", "Machine")
			$Service = Get-Service $Using:ServiceName -ErrorAction SilentlyContinue
			if ($Service) {
				Write-Host "Stopping service '$Using:ServiceName'... " -NoNewline
				Get-Service -ServiceName $Using:ServiceName | Stop-Service
				$Service.WaitForStatus('Stopped')
				Write-Host "Stopped!"
			}
		}

		$SourcePath = (Resolve-Path ".\$ProjectName\bin\*\$Environment" -ErrorAction SilentlyContinue)
		if ($SourcePath.Length -ne 1) {
			$SourcePath = ".\$ProjectName\bin\$Environment"
		} 
		else {
			$SourcePath = $SourcePath.Path
		}
		Copy-FilesToRemoteSession -Session $session -SourcePath $SourcePath -RemotePath $DestinationFolderPath
		
		# Install and start service
		Invoke-Command -Session $session -ScriptBlock {
			switch ($Using:ServiceType) {
				"Topshelf" {
					Write-Host "Installing and starting service... " -NoNewline
					Set-Location $Using:DestinationFolderPath 
					& .\$($Using:ExecutableFile) install -username $SvcArtsUsername -password ""$SvcArtsPassword""
					Start-Service -Name $Using:ServiceName
					Write-Host "Installed and started !"
				}
				"Native" {
					if (!(Get-Service $Using:ServiceName -ErrorAction SilentlyContinue)) {
						$SvcArtsCredential = New-Object System.Management.Automation.PSCredential($SvcArtsUsername, (ConvertTo-SecureString $SvcArtsPassword -AsPlainText -Force))
						Write-Host "No service exists, creating service '$Using:ServiceName'... " -NoNewline
						New-Service -Name $Using:ServiceName -BinaryPathName $Using:ExecutableFilePath -Credential $SvcArtsCredential
						Write-Host "Service created"
					}
					Write-Host "Installing and starting service... " -NoNewline
					Start-Service -Name $Using:ServiceName
					Write-Host "Installed and started !"
				}
			}
		}
	}
	Write-Host "DEPLOYMENT FINISHED"
}