<#
.SYNOPSIS
    Deploy windows service applications on different environments
.DESCRIPTION
    This script allows you to copy the files resulting from the generation of a windows service. It also kills the associated process, and restarts the service.
#>
function Send-WindowsServiceApp {
	param(
		 # Environment name
		[string] $Environment,
		# Username of a user with access to the environments
		[string] $User,
		# Password of that user
		[string] $Password,
		# Name of the application, that will be used to create service name and path to installation directory
		[string] $ApplicationName,
		# Path to the binaries of the application after build
		[string] $BinFolderPath,
		# Executable file name
		[string] $ExeFileName
	)
	
	$ServiceName = $ApplicationName + "Service"
	$DestinationFolderPath = "D:\Applications\$ServiceName\"
	$DestinationFolderPathWithDescendants = "D:\Applications\$ServiceName\*"
	
	Write-Host "Environment is $Environment, User is $User"
	
	$DestinationServer = "";
	
	switch ($Environment)
	{
		"DEV" {$DestinationServer="wdvpaap000lzzzx"}
		"INT" {$DestinationServer="wivpaap000lzzzy"}
		"PRE" {$DestinationServer="EMAPPA2142"}
		"PRD" {$DestinationServer="EMAPPA2143"}
		"PRD2" {$DestinationServer="WPVPAAP00000PZJ"}
	}
	
	Write-Host "DestinationFolderPath is $DestinationFolderPath, ServiceName is $ServiceName"
	
	$PasswordPlainText = $Password | ConvertTo-SecureString -asPlainText -Force
	$Credential = New-Object System.Management.Automation.PSCredential($User, $PasswordPlainText)
	
	$UserSession = New-PSSession -ComputerName $DestinationServer -Credential $Credential
	
	Invoke-Command -Session $UserSession -ScriptBlock {
	
		if (Get-Service $($args[0]) -ErrorAction SilentlyContinue)
		{
			Write-Host $($args[0]) "is going to be stopped."
			
			# Stop service
			Get-Service -ServiceName $($args[0]) | Stop-Service
			
			$($args[0]) + " is stopped."
		}
	
	} -ArgumentList ($ServiceName)
	
	Invoke-Command -Session $UserSession -ScriptBlock {
	
		Write-Host "Kill Process " $($args[0]) " started"
	
		Get-Process $($args[0]) -ErrorAction SilentlyContinue | Stop-Process -PassThru -Force
	
		Write-Host "Kill Process " $($args[0]) " finished"
	
	} -ArgumentList ($ServiceProcess)
	
	# wait 10 seconds
	sleep -Milliseconds 10000
	
	Invoke-Command -Session $UserSession -ScriptBlock {
	
		# Delete all files from folder
		if(Test-Path $($args[0]) -ErrorAction SilentlyContinue) 
		{
			Write-Host "Folder $($args[0]) exists."
		
			Remove-Item $($args[1]) -Recurse -Force
			
			Write-Host "All contents in folder $($args[0]) are deleted."
		}
		else {
				
			Write-Host "Folder $($args[0]) does not exist."
			
			New-Item -Path $($args[0]) -ItemType Directory
			
			Write-Host "Folder $($args[0]) created."
		}
	} -ArgumentList ($DestinationFolderPath, $DestinationFolderPathWithDescendants)
	
	Write-Host "Copy Files started."
	
	Copy-Item .\$BinFolderPath\$Environment\* -Destination $DestinationFolderPath -ToSession $UserSession -Verbose -Recurse
	
	Write-Host "Copy Files finished."
	
	Invoke-Command -Session $UserSession -ScriptBlock {
		
		Write-Host "Service installation started."
		cd $($args[1])
		
		& .\$ExeFileName install
	
		Write-Host "Service installation finished."
		
		Start-Service -Name $($args[0])
		
		Write-Host "Service started."
	
	} -ArgumentList ($ServiceName, $DestinationFolderPath)
	
	Remove-PSSession $UserSession
}
