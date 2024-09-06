function Invoke-SqlScripts {
    param (
        #Path to SQL scripts folder
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptsPath,
        #Path to log folder
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LogPath
    )

    # Vérifier si le dossier existe
    if (-Not (Test-Path -Path $ScriptsPath -PathType Container)) {
        Write-Error "Le dossier spécifié n'existe pas : $ScriptsPath"
        exit
    }

    $LogFileFullPath = Join-Path $LogPath "Invoke-SqlScripts.$(Get-Date -Format "yyyy-MM-dd").log"

    # Définir la chaîne de connexion à partir de la variable d'environnement
    $ConnectionString = [Environment]::GetEnvironmentVariable("ConnectionStrings.Fim", "User")

    # Récupérer la liste des fichiers SQL dans le dossier
    $sqlFiles = Get-ChildItem -Path $ScriptsPath -Filter *.sql

    # Boucle pour exécuter chaque fichier SQL et enregistrer les logs
    foreach ($file in $sqlFiles) {
        $logMessage = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        try {
            $logMessage += " Executing script '$file'... "
            Invoke-Sqlcmd -ConnectionString $ConnectionString -InputFile $file.FullName -ErrorAction Stop
            $logMessage += "Done!"
        } catch {
            $logMessage += "Cannot be executed for the following reason: $($_.Exception.Message)"
        } finally {
            Write-Host $logMessage
            Add-Content -Path $LogFileFullPath -Value $logMessage
        }
    }
}