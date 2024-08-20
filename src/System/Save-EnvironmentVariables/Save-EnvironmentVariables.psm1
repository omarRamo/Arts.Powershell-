<#
.SYNOPSIS
    Save filtered environment variables from computer to file
#>
function Save-EnvironmentVariables {
    param(
        # file path to save the result
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Path = ".\",
        # Filter environment variable names containing the pattern
        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [string] $Contains,
        # Symetric key
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Byte[]] $Key
    )
    $ErrorActionPreference = "Stop"
    $FullPath = Join-Path $Path "EncryptedEnvVars_$(hostname).json"
    $EnvTypes = @("User", "Machine")
    $FileContent = New-Object System.Collections.Generic.List[Object]
    if (-not $Key) {
        $Key = New-Object Byte[] 16
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
    }

    foreach ($EnvType in $EnvTypes) {
        $EnvVars = [Environment]::GetEnvironmentVariables($EnvType)
        $FileContentEnvVars = New-Object System.Collections.Generic.List[Object]

        foreach ($EnvVarName in $EnvVars.Keys) {

            # Filter out user specific variables
            if ($EnvVarName == "PATH" -or $EnvVarName == "TEMP" -or $EnvVarName == "TMP") {
                continue
            }

            # Filter env variables having value and name match pattern
            if ($EnvVars[$EnvVarName] -and $EnvVarName -like "*$Contains*") {
                $EncryptedEnvVarValue = $EnvVars[$EnvVarName] | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -key $Key
                $FileContentEnvVars.Add([PSCustomObject]@{
                        "Name"           = $EnvVarName
                        "EncryptedValue" = $EncryptedEnvVarValue 
                    })
            }

        }
        
        # Add Environment variables to file content
        if ($FileContentEnvVars.Count -gt 0) {
            $FileContent.Add([PSCustomObject]@{
                    "Name"      = $EnvType 
                    "Variables" = $FileContentEnvVars
                })
        }
    }

    $FileContent | ConvertTo-Json -Depth 3 | Out-File $FullPath
    Write-Host "Computer's environment variables have been successfuly saved into '$FullPath'" -ForegroundColor Green
    Write-Host "To decrypt the file, use the following 16 bits key:"
    Write-Host
    Write-Host "($($Key -join ", "))"
}