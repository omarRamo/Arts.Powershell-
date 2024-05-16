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
    Import-Module ActiveDirectory

    $Environments = @("development", "integration", "preproduction", "production")
    $Machinename = Switch ($Environment) {
        $Environments[0] { "wdvpaap000lzzzx" }
        $Environments[1] { "wivpaap000lzzzy"}
        $Environments[2] { "EMAPPA2142" }
        $Environments[3] { "EMAPPA2143" }
    }

    if($null -eq $Machinename) {
        Write-Error "Environment '$Environment' is not taken in account. Available : ($Environments)"
    } else {

        # Installing Node JS using Node Version Manager (NVM)
        nvm install $NvmVersion
        nvm use $NvmVersion
        npm install
        # Build solution
        npm run build -- --configuration $Environment

        $DestinationAbsolutePath = "D:/INETPUB/ARTS/$ProjectName"
        $Session = New-PSSession -ComputerName $Machinename -Credential (New-Object System.Management.Automation.PSCredential($Account, (ConvertTo-SecureString $Password -AsPlainText -Force)))

        Write-Host "Deployment will be done on machine '$Machinename' in directory '$DestinationAbsolutePath'"
        if($null -ne $session) {
            if (Test-Path $DestinationAbsolutePath -ErrorAction SilentlyContinue) {
                Write-Host "Folder '$DestinationAbsolutePath' exists. Deleting all contents in folder... " -NoNewline
                Remove-Item -Path $DestinationAbsolutePath -Recurse -Force
                Write-Host "Deleted!"
            }
            else {
                Write-Host "Folder '$DestinationAbsolutePath' does not exist. Creating folder... " -NoNewline
                New-Item -Path $DestinationAbsolutePath -ItemType Directory -Force | Out-Null            
                Write-Host "Created!"
            }

            Write-Host "Copying files..."
            Copy-Item  -Recurse -Force -Path ".\dist\*" -Destination $DestinationAbsolutePath -ToSession $Session -Verbose -ErrorAction Stop
            Write-Host "All files have been copied!"

            Write-Host "DEPLOYMENT FINISHED"
        }
    }
}
