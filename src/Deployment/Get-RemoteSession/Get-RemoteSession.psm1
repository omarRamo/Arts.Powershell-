<#
.SYNOPSIS
    Get remote session from hosting infrastructure
.DESCRIPTION
    This script allows you to copy the files resulting from the generation of a 
    console application to a hosting environment.

    It is particularly useful in a deployment pipeline.
#>
function Get-RemoteSession {
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

    $Environments = @("Development", "Integration", "Preproduction", "Production")

    $Machinename = switch ($Type) {
        "Web" { 
            Switch ($Environment) {
                $Environments[0] { "wdvpaap000lzzzx" }
                $Environments[1] { "wivpaap000lzzzy" }
                $Environments[2] { "EMAPPA2142" }
                $Environments[3] { "EMAPPA2143" }
            }
        }
        "Console" { 
            Switch ($Environment) {
                $Environments[0] { "wdvpaap000lzzzp" }
                $Environments[1] { "wivpaap000mzzz0" }
                $Environments[2] { "EMAPPA2142" }
                $Environments[3] { "EMAPPA2143" }
            }
        }
    }

    if ($null -eq $Machinename) {
        Write-Error "Environment '$Environment' is not taken in account. Available : ($Environments)" -ErrorAction Stop
        exit 1
    }
    else {
        Write-Host "Opening session on remote host '$MachineName'..." -NoNewline
        $Credential = New-Object System.Management.Automation.PSCredential($Account, (ConvertTo-SecureString $Password -AsPlainText -Force))
        $Session = New-PSSession -ComputerName $Machinename -Credential $Credential
        Write-Host "Opened!"
        return $Session
    }
}