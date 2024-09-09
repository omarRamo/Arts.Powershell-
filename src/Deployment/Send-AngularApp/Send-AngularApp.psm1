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

    $Session = Get-RemoteSession $Environment $Account $Password -Type "Web"
    
    # Installing Node JS using Node Version Manager (NVM)
    nvm install $NvmVersion
    nvm use $NvmVersion
    npm install
    # Build solution
    npm run build -- --configuration $Environment

    Copy-FilesToRemoteSession -Session $Session -SourcePath ".\dist" -RemotePath "D:/INETPUB/ARTS/$ProjectName"

    if ($Environment -eq "Preproduction") {
        $Session2 = Get-RemoteSession PreproductionWeb2 $Account $Password -Type "Web"
        Copy-FilesToRemoteSession -Session $Session2 -SourcePath ".\dist" -RemotePath "D:/INETPUB/ARTS/$ProjectName"
    }
    Write-Host "DEPLOYMENT FINISHED"
}
