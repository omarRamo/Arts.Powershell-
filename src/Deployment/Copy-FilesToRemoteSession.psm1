<#
.SYNOPSIS
    Copy files recursivly from a local folder to a remote folder over a PS session
#>
function Copy-FilesToRemoteSession {
    param(
        # Remote session
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PsSession] $Session,
        # Source path
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SourcePath,
        # Remote path
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $RemotePath
    )
    Invoke-Command -Session $Session -ScriptBlock {
        if (Test-Path $Using:RemotePath -ErrorAction SilentlyContinue) {
            Write-Host "Folder '$Using:RemotePath' exists. Deleting all contents in folder... " -NoNewline
            Remove-Item -Path (Join-Path $Using:RemotePath "\*") -Recurse -Force
            Write-Host "Deleted!"
        }
        else {
            Write-Host "Folder '$Using:RemotePath' does not exist. Creating folder... " -NoNewline
            New-Item -Path $Using:RemotePath -ItemType Directory -Force | Out-Null            
            Write-Host "Created!"
        }
    }   

    Write-Host "Copying app files from '$SourcePath' to '$RemotePath' on '${Session.ComputerName}'... "
    Copy-Item (Join-Path $SourcePath "\*") -Destination $RemotePath -ToSession $Session -Verbose -Recurse -Force
    Write-Host "All files have been copied!"
}