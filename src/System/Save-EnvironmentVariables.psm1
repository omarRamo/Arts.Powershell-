<#
.SYNOPSIS
    Save filtered environment variables from machine to file
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
        [string] $Contains
    )
    $FullPath = Join-Path $Path "EncryptedEnvVars_$(hostname).json"
    $EnvTypes = @("User", "Machine")
    $FileContent = @{}
    $Key = New-Object Byte[] 16
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)

    foreach ($EnvType in $EnvTypes) {
        $EnvVars = [Environment]::GetEnvironmentVariables($EnvType)
        $FileContent | Add-Member -Name $EnvType -Value (New-Object System.Collections.Generic.List[Object]) -MemberType NoteProperty

        foreach ($EnvVarName in $EnvVars.Keys) {
            $EnvVarValue = $EnvVars[$EnvVarName]

            # Filter env variables having value
            if ($EnvVarValue -and $EnvVarName -like "*$Contains*") {
                $EncryptedEnvVarValue = $EnvVars[$EnvVarName] | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -key $Key
                $FileContent.$EnvType.Add([PSCustomObject]@{$EnvVarName = $EncryptedEnvVarValue })
            }
        }
    }

    $FileContent | ConvertTo-Json | Out-File $FullPath -ErrorAction Stop
    Write-Host "File successfuly saved into '$FullPath'" -ForegroundColor Green
    Write-Host "To decrypt the file, use the following 16 bits key:"
    Write-Host
    Write-Host "($($Key -join ", "))"
}