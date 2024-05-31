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
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        # Project name
        [string] $ProjectName,
        # Name of the user executing the pipeline
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Account,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        # Password of the user executing the pipeline
        [string] $Password
    )
    Write-Host "DEPLOYMENT STARTED"

    $Session = Get-RemoteSession $Environment $Account $Password -Type "Console"
    Copy-AppToRemoteSession -Session $Session -SourcePath .\$ProjectName\bin\$Environment\* -RemotePath "D:/APPLICATIONS/$ProjectName"
    Remove-PSSession $Session

    Write-Host "DEPLOYMENT FINISHED"
}