<#
.SYNOPSIS
    Restore environment variables from file to computer
#>
function Restore-EnvironmentVariables {
    param(
        # file path to save the result
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,
        # Filter environment variable names containing the pattern
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [Byte[]] $Key
    )
    $ErrorActionPreference = "Stop"
    $Envs = Get-Content $Path | ConvertFrom-Json
    foreach ($Env in $Envs) {
        Write-Host $EnvType
        foreach ($EnvVar in $Env.Variables) {
            $EnvVarValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(($EnvVar.EncryptedValue | ConvertTo-SecureString -Key $Key)))
            [Environment]::SetEnvironmentVariable($EnvVar.Name, $EnvVarValue, $Env.Name)
        }
    }
    Write-Host "File's environment variables '$Path' have been successfuly saved on the computer" -ForegroundColor Green
}