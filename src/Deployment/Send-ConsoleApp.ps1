<#
.SYNOPSIS
    Deploy console applications on different environments
.DESCRIPTION
    This script allows you to copy the files resulting from the generation of a 
    console application to a hosting environment.

    It is particularly useful in a deployment pipeline.
#>
function Send-ConsoleApp {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        # Environment name
        [string] $Environment,
        # Name of the configuration build
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $BuildConfiguration,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        # Project name
        [string] $ProjectName,
        # Name of the user executing the pipeline
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Account,
        # Password of the user executing the pipeline
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Password
    )
    Write-Host "DEPLOYMENT STARTED"

    if(-not $BuildConfiguration) {
        $BuildConfiguration = $Environment
    }

    $sessions = Get-RemoteSessions $Environment $Account $Password -Type "Console"

    foreach ($session in $sessions) {
        Copy-FilesToRemoteSession -Session $session -SourcePath .\$ProjectName\bin\$BuildConfiguration -RemotePath "D:/SOFT/$ProjectName"
        Remove-PSSession $session
    }

    Write-Host "DEPLOYMENT FINISHED"
}