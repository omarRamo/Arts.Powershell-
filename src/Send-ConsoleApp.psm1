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
        # Environment name
        [string] $Environment,
        # Project name
        [string] $ProjectName,
        # Name of the user executing the pipeline
        [string] $Account,
        # Password of the user executing the pipeline
        [string] $Password
    )
    Write-Host "DEPLOYMENT STARTED"
    Import-Module ActiveDirectory

    $Environments = @("Development", "Integration", "Preproduction", "Production")
    $Machinename = Switch ($Environment) {
        $Environments[0] { "wdvpaap000lzzzp" }
        $Environments[1] { "wivpaap000mzzz0"}
        $Environments[2] { "EMAPPA2142" }
        $Environments[3] { "EMAPPA2143" }
    }

    if($null -eq $Machinename) {
        Write-Error "Environment '$Environment' is not taken in account. Available : ($Environments)"
    } else {
        $DestinationAbsolutePath = "D:/APPLICATIONS/$ProjectName"
        $Session = New-PSSession -ComputerName $Machinename -Credential (New-Object System.Management.Automation.PSCredential($Account, (ConvertTo-SecureString $Password -AsPlainText -Force)))

        Write-Host "Deployment will be done on machine '$Machinename' in directory '$DestinationAbsolutePath'"
        if($session -ne $null) {
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
            Copy-Item .\$ProjectName\bin\$Environment\* -Destination $DestinationAbsolutePath -ToSession $Session -Verbose -Recurse -Force
            Write-Host "All files have been copied!"

            Write-Host "DEPLOYMENT FINISHED"
        }
    }
}