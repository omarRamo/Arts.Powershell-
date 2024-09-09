<#
.SYNOPSIS
    Deploy Angular applications on different environments
.DESCRIPTION
    This script allows you to copy the files resulting from the generation of a 
    Angular application to a hosting environment.

    It is particularly useful in a deployment pipeline.
#>
function Send-AngularApp {
    param(
        # Environment name
        [string] $Environment,
        # Project name
        [string] $ProjectName,
        # Name of the user executing the pipeline
        [string] $Account,
        # Password of the user executing the pipeline
        [string] $Password,
        # NVM Version
        [string] $NvmVersion
    )
    Write-Host "DEPLOYMENT STARTED"
    
    # Installing Node JS using Node Version Manager (NVM)
    nvm install $NvmVersion
    nvm use $NvmVersion
    npm install
    # Build solution
    npm run build -- --configuration $Environment
    
    $sessions = Get-RemoteSessions $Environment $Account $Password -Type "Web"
    foreach($session in $sessions) {
         Copy-FilesToRemoteSession -Session $Session -SourcePath ".\dist" -RemotePath "D:/INETPUB/ARTS/$ProjectName"
         Remove-PSSession $session
    }

    Write-Host "DEPLOYMENT FINISHED"
}
