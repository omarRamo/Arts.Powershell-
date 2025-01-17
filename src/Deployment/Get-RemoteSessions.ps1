<#
.SYNOPSIS
    Get remote session from hosting infrastructure
.DESCRIPTION
    This script allows you to copy the files resulting from the generation of a 
    console application to a hosting environment.

    It is particularly useful in a deployment pipeline.
#>
function Get-RemoteSessions {
    param(
        # Environment name
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Environment,
        # Name of the user executing the pipeline
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Account,
        # Password of the user executing the pipeline
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Password,
        # Hosting type
        [Parameter(Mandatory = $true)]
        [ValidateSet("Web", "Console")]
        [string] $Type
    )

    $environments = @("Development", "Integration", "Preproduction", "Production")


    # Using aliases for machines, can be used in PSSession only if hosts are trusted in winrm
    # Use command line winrm set winrm/config/client @{TrustedHosts="alias1, alias2"} to set trusted hosts
    $machinesNames = switch ($Type) {
        "Web" { 
            Switch ($Environment) {
                $Environments[0] { @("artsWeb1-dev") }
                $Environments[1] { @("artsWeb1-int") }
                $Environments[2] { @("artsWeb1-pre", "artsWeb2-pre") }
                $Environments[3] { @("artsWeb1-prd", "artsWeb2-prd") }
            }
        }
        "Console" { 
            Switch ($Environment) {
                $Environments[0] { "artsBatch1-dev" }
                $Environments[1] { "artsBatch1-int" }
                $Environments[2] { "artsBatch1-pre" }
                $Environments[3] { @("artsBatch1-prd", "artsBatch2-prd") }
            }
        }
    }

    if ($null -eq $machinesNames) {
        Write-Error "Environment '$Environment' is not taken in account. Available : ($Environments)" -ErrorAction Stop
        exit 1
    } else {
        $sessions = @()
        foreach($machineName in $machinesNames) {
            Write-Host "Opening session on remote host '$machineName'..." -NoNewline
            $Credential = New-Object System.Management.Automation.PSCredential($Account, (ConvertTo-SecureString $Password -AsPlainText -Force))
            $sessions += New-PSSession -ComputerName $machineName -Credential $Credential
            Write-Host "Opened!"
        }
        return $sessions
    }
}