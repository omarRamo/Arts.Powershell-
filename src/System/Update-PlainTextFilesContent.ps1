<#
  .Synopsis
  Update recursivly plain text files content given a mapping file

  .Description
  Given a JSON mapping files, it replaces every occurences on files located on specified directories.

  .Example
  Update-PlainTextFilesContent -LogPath \\cmfrfi002\ARTSSHARE\Logs\ConnectionStringsMigration -ConfigPath \\cmfrfi002\ARTSSHARE\UpdateConnectionStrings.json
#>
 function Update-PlainTextFilesContent {
    param(
        # Json mapping file (dictionnary structure)
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ConfigPath,
        # Log file
        [ValidateNotNullOrEmpty()]
        [string] $LogPath = ".\"

    )
    $ErrorActionPreference = "Stop"
    $logFullPath = Join-Path $LogPath "$(hostname)_$(Get-Date -Format "yyyyMMddTHHmmssffff").log"
    $filesToUpdateInfos = @()
    $Exclusions = @("*.exe", "*.dll", "*.pdb", "*.log", "*.log.*", "*.pdf", "*.docx", "*.xlsx", "*.zip", "*.css", "*.js", "*.html", "*.msu", "*.msi", "*.jar")
    $config = Get-Content -Path $ConfigPath | Out-String | ConvertFrom-Json
    
    foreach($directoryPath in $config.IncludedPaths) {
        # Create list of files to check
        "Searching for files to update on directory '$directoryPath'..." | Tee-Object -FilePath $logFullPath -Append | Write-Host -ForegroundColor Yellow
    
        $files = Get-ChildItem -Path $directoryPath -Recurse -File -Exclude $Exclusions -ErrorAction SilentlyContinue
        if($null -ne $config.Excludeds) {
            $files = $files | Where-Object {
                $isExcluded = $false
                foreach($excluded in $config.Excludeds) {
                    if($_ -like "*$excluded*") {
                        $isExcluded = $true
                    }
                }

                -not $isExcluded
             }
        }
        $filenumber = 0

        # Check files one by one
        foreach($file in $files) {
            $filenumber++
    
            Write-Progress -Activity "Analyzing file $($file.FullName)" -Status "$filenumber/$($files.Count)" -PercentComplete (($filenumber / $files.Count) * 100)
            $content = Get-Content -Path $file.FullName -ErrorAction SilentlyContinue
            if ($null -ne $content) {
                $isBinaryFile = (New-Object System.Text.RegularExpressions.Regex('[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\xFF]')).IsMatch($content)
                
                if (!$isBinaryFile) {
                    $linenumber = 0
                    foreach ($line in $content) {
                        $linenumber++
                        foreach ($mapping in $config.Mappings) {
                            if ($line -match $mapping.From) {
                                
                                # Cache file update infos
                                $fileToUpdateInfos = [PSCustomObject]@{
                                    FullPath   = $file.FullName
                                    Line       = $line.Trim()
                                    LineNumber = $linenumber
                                    Match      = $mapping.From
                                    ReplaceBy  = $mapping.To
                                }
                                $filesToUpdateInfos += $fileToUpdateInfos
                                
                                # Logging
                                $fileToUpdateInfos | Format-List | Tee-Object -FilePath $logFullPath -Append
                            }
                        }
                    }
                }
            }
        }
    }

    # Ask user confirmation to apply changes
    if ( $filesToUpdateInfos.Count -gt 0) {
        while ($true) {
            Write-Host "Do you want to update $($filesToUpdateInfos.Count) files (y/n) ? " -NoNewline -ForegroundColor Yellow
            $confirmation = Read-Host
    
            # Apply action desired by the user
            switch ($confirmation) {
                'y' {
                    foreach ($fileToUpdateInfos in $filesToUpdateInfos) {
                        "Updating file '$($fileToUpdateInfos.FullPath)' " | Tee-Object -FilePath $logFullPath -Append | Write-Host -NoNewline
                        $content = Get-Content $fileToUpdateInfos.FullPath
                        $content -ireplace [regex]::Escape($fileToUpdateInfos.Match), $fileToUpdateInfos.ReplaceBy | Set-Content $fileToUpdateInfos.FullPath
                        "Updated!" | Tee-Object -FilePath $logFullPath -Append | Write-Host 
                    }
                    return
                }
                'n' {
                    "Update canceled. No files has been updated" | Tee-Object -FilePath $logFullPath -Append | Write-Host 
                    return
                }
                default {
                    continue
                }
            }
        }
        else {
            "No files to update!" | Tee-Object -FilePath $logFullPath -Append | Write-Host
        }
    }
}