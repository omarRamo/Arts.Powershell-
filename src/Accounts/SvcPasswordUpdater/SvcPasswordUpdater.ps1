# Imports
$isWebAdministrationAvailable = Get-Module -ListAvailable -Name WebAdministration
if ($isWebAdministrationAvailable) {
    Import-Module WebAdministration
    $iisPools = Get-ChildItem IIS:\AppPools
}

# Constants
$currentDir = Get-Location
$config = Get-Content -Path config.json -Raw | ConvertFrom-Json
$updatesFile = "$currentDir/DataFiles/$env:COMPUTERNAME" + "_Updates_DataFile.txt"
$deletionsFile = "$currentDir/DataFiles/$env:COMPUTERNAME" + "_Deletions_DataFile.txt"

$task1 = "List IIS application pools"
$task2 = "Edit IIS application pools"
$task3 = "Search for accounts data in all files"
$task4 = "Search for account in determined files"
$task6 = "Replace account data in determinated files"

Set-Location C:\ # Prevent CMD display warning when execution is done from UNC folder

class Replace {
    [string]$From
    [string]$To
}

try {
    # Functions
    function Prompt-ChooseAccountAndPassword {
        $result = New-Object PSObject
        Add-Member -InputObject $result -MemberType NoteProperty -Name AccountName -Value $null
        Add-Member -InputObject $result -MemberType NoteProperty -Name AccountPassword -Value $null
        Write-Host "Step 1" -ForegroundColor Yellow
        for (($i = 0); $i -lt 2; $i++) {
            Write-Host "`t$($i+1). $($config.Accounts[$i].Name)"
        }
        Write-Host "Please choose the account : " -NoNewline
        $accountChoice = choice /C 123456789 /N
        $accountName = "$($config.Accounts[$accountChoice - 1].Domain)\\$($config.Accounts[$accountChoice - 1].User)"
        Write-Host $accountName -ForegroundColor Green
        Write-Host
        Write-Host "Step 2" -ForegroundColor Yellow
        Write-Host "`t1. Old password"
        Write-Host "`t2. New password"
        Write-Host "Please choose the password : " -NoNewline
        $passwordChoice = choice /C 12 /N

        switch ($passwordChoice) {
            1 {
                $accountPassword = $config.Accounts[$accountChoice - 1].OldPassword
                Write-Host "old password" -ForegroundColor Green
            }
            2 {
                $accountPassword = $config.Accounts[$accountChoice - 1].NewPassword
                Write-Host "new password" -ForegroundColor Green
            }

        }
        Write-Host "1" -ForegroundColor Green
        Write-Host
        $result.AccountName = $accountName
        $result.AccountPassword = $accountPassword
        return $result
    }
    <#
    .SYNOPSIS
        Ask user for accounts to replace and to be replaced, and return their index.
    #>
    function Prompt-ChooseAccountToBeReplaced {
        $result = [PSCustomObject]@{
            AccountToBeReplacedIndex = $null;
            AccountReplacementIndex  = $null;
            UseNewPassword           = $false;
        }

        # Account to be replaced selection
        $accountToBeReplacedChoices = ""
        Write-Host "Step 1" -ForegroundColor Yellow
        for (($i = 0); $i -lt $config.Accounts.Count; $i++) {
            Write-Host "`t$($i+1). $($config.Accounts[$i].Name)"
            $accountToBeReplacedChoices += $i + 1
        }
        Write-Host "Please choose the account to be replaced : " -NoNewline
        $accountToBeReplacedChoice = choice /C $accountToBeReplacedChoices /N
        $result.AccountToBeReplacedIndex = $accountToBeReplacedChoice - 1 
        
        # Remplacement account selection
        $accountReplacementChoices = ""
        Write-Host "Step 2" -ForegroundColor Yellow
        for (($i = 0); $i -lt $config.Accounts.Count; $i++) {
            Write-Host "`t$($i+1). $($config.Accounts[$i].Name)"
            $accountReplacementChoices = $i + 1
        }
        Write-Host "Please choose the replacement account : " -NoNewline
        $accountReplacementChoice = choice /C $accountReplacementChoices /N
        $result.AccountReplacementIndex = $accountReplacementChoice - 1

        # Use new or old password selection
        Write-Host "Step 3" -ForegroundColor Yellow
        Write-Host "Do you want to use (N)ew or (O)ld password ?" -NoNewline
        $passwordAccountChoice = choice /C ON /N
        $result.UseNewPassword = $passwordAccountChoice -eq "Y"
        
        return $result
    }

    <#
    .SYNOPSIS
        According to 
    #>
    function Replace-AccountInFile {
        param (
            [Parameter(Mandatory = $true)]  [int32]$AccountToBeReplacedIndex,
            [Parameter(Mandatory = $true)]  [int32]$ReplacementAccountIndex,
            [Parameter(Mandatory = $true)]  [bool]$UseNewPassword,
            [Parameter(Mandatory = $true)]  [String]$FilePath
        )

        $AccountToBeReplaced = $config.Account[$AccountToBeReplacedIndex]
        $ReplacementAccount = $config.Account[$ReplacementAccountIndex]

        $content = Get-Content $FilePath
        
        $content = $content -replace "$($AccountToBeReplaced.Domain)\$($AccountToBeReplaced.User)", "$($ReplacementAccount.Domain)\$($ReplacementAccount.User)"
        if ($UseNewPassword) {
            $content = $content -replace $AccountToBeReplaced.OldPassword, $ReplacementAccount.NewPassword
        }
        else {
            $content = $content -replace $AccountToBeReplaced.NewPassword, $ReplacementAccount.OldPassword
        }
        Set-Content -LiteralPath $FilePath -Value $content
    }

    function Find-File($filepath) {
        $result = $null
        Get-Content -LiteralPath $filepath -ReadCount 500 | ForEach-Object {
            foreach ($account in $config.Accounts) {
                $isNameFound = $_ -match "$($account.Domain)\\$($account.User)"
                $isOldPasswordFound = $_ -match $account.OldPassword
                $isNewPasswordFound = $_ -match $account.NewPassword
                
                if ($isNameFound -or $isOldPasswordFound -or $isNewPasswordFound) {
                    $result = [PSCustomObject]@{
                        File        = $filepath;
                        AccountName = $null;
                        Password    = $null;
                    }
                    if ($isNameFound) {
                        $result.AccountName = "$($account.Domain)\\$($account.User)"
                    }
                    if ($isOldPasswordFound) {
                        $result.Password = $account.OldPassword
                    }
                    if ($isNewPasswordFound) {
                        $result.Password = $account.NewPassword
                    }
                    $result | Format-List | Out-String | Write-Host
                }
            }
        }
        return $result
    }

    Write-Host 
    if ($isWebAdministrationAvailable) {
        Write-Host "                         IIS                         " -ForegroundColor White
        Write-Host "`t1: $task1" -ForegroundColor Yellow
        Write-Host "`t2: $task2" -ForegroundColor Yellow
        Write-Host
    }
    Write-Host
    Write-Host "                   FILESYSTEM SEARCH                 " -ForegroundColor White
    Write-Host "`t3: $task3" -ForegroundColor Yellow
    Write-Host "`t4: $task4" -ForegroundColor Yellow
    Write-Host
    Write-Host
    Write-Host "                  FILESYSTEM DELETION                " -ForegroundColor White
    Write-Host "`t5: Check files deletion" -ForegroundColor Yellow
    Write-Host
    Write-Host
    Write-Host "                  FILESYSTEM REPLACE                 " -ForegroundColor White
    Write-Host "`t6: $task6"
    Write-Host 
    Write-Host "Please choose an option : " -NoNewline
    $choice = choice /C 12345 /N
    
    switch ($choice) {
        1 {
            if ($isWebAdministrationAvailable) {
                Write-Host $task1 -ForegroundColor Green
                $iisPools = Get-ChildItem IIS:\AppPools
                foreach ($iisPool in $iisPools) {
                    if ($iisPool.processModel.userName -eq $config.Accounts[0].Name -or $iisPool.processModel.userName -eq $config.Accounts[1].Name) {
                        [PSCustomObject]@{
                            ApplicationPool = $iisPool.Name;
                            AccountName     = $iisPool.processModel.userName;
                            Password        = $iisPool.processModel.password;
                            Status          = $iisPool.State;
                        }
                    }
                }
            }
        }
        2 {
            if ($isWebAdministrationAvailable) {
                Write-Host $task2 -ForegroundColor Green
                $result = Prompt-ChooseAccountAndPassword
                Write-Host "Updating..." -ForegroundColor Yellow
    
                foreach ($iisPool in $iisPools) {
                    if ($iisPool.processModel.userName -eq $config.Accounts[0].Name -or $iisPool.processModel.userName -eq $config.Accounts[1].Name) {
                        $iisPool.processModel.userName = $result.AccountName
                        $iisPool.processModel.password = $result.AccountPassword
                        $iisPool | Set-Item
                    }
                }
    
                Write-Host "Update sucessful!" -ForegroundColor Green
            }
        }
        3 {
            Write-Host $task3 -ForegroundColor Green
            Write-Host "Available local drive on the machine : "
            Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -ne 4 } | Select-Object DeviceId | Out-String | Write-Host
            Write-Host "Select the drive ID on which you wish to search : " -NoNewline
            $driveLetter = choice /C ABCDEFGHIJKL /N
            Write-Host $driveLetter
            Write-Host "Determining files to explore (can take 30s to 5 minutes)..." -ForegroundColor Yellow
            $dirsToScan = Get-ChildItem -Path "${driveLetter}:\"  -Directory | Where-Object { $_.FullName -notlike "$($env:windir)*" } | ForEach-Object { $_.FullName }  
            $filecount = 0
            $files = Get-ChildItem -Recurse -File -LiteralPath $dirsToScan -Exclude *.exe, *.dll, *.so, *.bin, *.dat, *.o, *.obj, *.pyc, *.pyo, *.class, *.lib, *.a, *.pdb, *.dmg, *.iso, *.img, *.msi, *.pdf, *.docx, *.pptx, *.xlsx, *.jpg, *.jpeg, *.png, *.gif, *.bmp, *.tiff, *.ico, *.svg, *.mp3, *.wav, *.ogg, *.flac, *.m4a, *.mp4, *.avi, *.mkv, *.flv, *.mov, *.wmv, *.zip, *.rar, *.tar, *.gz, *.bz2, *.7z
            $totalFilesCount = ($files | Measure-Object).Count
            $results = @()
            $files | ForEach-Object {
                $filecount++
                Write-Host "`rSearching... ($fileCount / $totalFilesCount)" -ForegroundColor Yellow -NoNewline
                $result = Find-File($_.FullName)
                if ($result -ne $null) {
                    $results += $result
                }
            }
            Write-Host "`nSearch done!" -ForegroundColor Yellow
            Write-Host "Would you like to save the file list into a file ? (Y/N)" -ForegroundColor Yellow
            $saveChoice = choice /C YN /N
            if ($saveChoice -eq "Y") {
                $savepath = "$($home)\svcpasswordmodifier_$((Get-Date).ToString("ddMMyyyy_HHmmss"))_$(hostname)_Drive$($driveLetter).txt"
                Write-Host "Saving into file..." -ForegroundColor Yellow
                $results | ForEach-Object {
                    Add-Content -Path $savepath -Value $_.File
                }
                Write-Host "File saved into '$($savepath)'!" -ForegroundColor Yellow
            }

        }
        4 {
            Write-Host $task4 -ForegroundColor Green
            $table = New-Object PSObject
            Add-Member -InputObject $table -MemberType NoteProperty -Name File -Value $null
            Add-Member -InputObject $table -MemberType NoteProperty -Name AccountName -Value $null
            Add-Member -InputObject $table -MemberType NoteProperty -Name AccountPassword -Value $null
            Write-Host "Checking"
            Get-Content $updatesFile | ForEach-Object {
                Find-File($_)
            }
            $table
            Write-Host "Check done!" -ForegroundColor Green

        }
        5 {
            Write-Host "Check files deletion" -ForegroundColor Green
            Write-Host "Checking deletion..." -ForegroundColor Yellow
            Get-Content $deletionsFile | ForEach-Object {
                if (Test-Path $_) {
                    Write-Host "File or directory $_ still exists" -ForegroundColor Red
                }
                else {
                    Write-Host "File or directory $_ still exists" -ForegroundColor Green
                }
            }
            Write-Host "Check done!" -ForegroundColor Yellow
        }
        6 {
            Write-Host $task6 -ForegroundColor Green
            $accountReplacement = Prompt-ChooseAccountToBeReplaced

            $replacements = $(
                @($accountToBeReplaced.Name, )
            )




        }
    }
}
finally {
    Set-Location $currentDir
}