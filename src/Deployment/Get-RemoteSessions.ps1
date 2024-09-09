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

    $Environments = @("Development", "Integration", "Preproduction", "Production")

    $Machinenames = switch ($Type) {
        "Web" { 
            Switch ($Environment) {
                $Environments[0] { @("wdvpaap000lzzzx") }
                $Environments[1] { @("wivpaap000lzzzy") }
                $Environments[2] { @("wqvpaap000nzzz2", "wqvpaap000nzzz3") }
                $Environments[3] { @("wpvpaap000ozzzg", "wpvpaap000ozzze") }
            }
        }
        "Console" { 
            Switch ($Environment) {
                $Environments[0] { "wdvpaap000lzzzp" }
                $Environments[1] { "wivpaap000mzzz0" }
                $Environments[2] { "wqvpaap000ozzz1" }
                $Environments[3] { "wpvpaap000ozzzh" }
            }
        }
    }

    if ($null -eq $Machinenames) {
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