# Presentation

```SvcPasswordUpdater``` is intended to update passwords from **filesystem** and **IIS configurations**.

# Architecture

* ```SvcPasswordUpdater``` : script principal listant les différentes tâches que l'utilisateur peut executer.
    * Lister les pools d'applications IIS
    * Editer le compte des pools d'applications IIS
    * Rechercher des occurences du nom du compte de service ou du mot de passe dans tous les fichiers du lecteur selectionné
    * Rechercher des occurences du nom du compte de service ou du mot de passe dans les fichiers repertoriés dans le *datafiles* de la machine
    * Remplacer le nom du compte et/ou le mot de passe dans les fichiers repertoriés dans le *datafiles* de la machine

* ```Modules```
    * ```IIS```
    * ```Filesystem```
        * ```Get-DomainOrUserOrPassword```
        * ```Get-DomainOrUserOrPasswordReplacement```
* ```Config``` :
    * ```Domains``` : Liste de domaines
    * ```Users``` : Liste d'utilisateurs
    * ```Passwords``` : Liste de mots de passe 

# Prompts

```mermaid
---
title: Get-DomainOrUserOrPassword
---
    graph
        A[Start] --> B["`Lister tous les noms des comptes du fichier *config.json*`"]
        B --> C[❓ Demander à l'utilisateur de choisir un compte]
        C --> D{Il n'existe qu'un seul mot de passe pour ce compte}
        D -- Oui --> E[Afficher le mot de passe selectionné automatiquement]
        D -- Non --> F[Lister les mots de passe disponible pour le compte sélectionné]
        F --> G["❓ Demander à l'utilisateur de choisir un mot de passe"]
        G --> H["`Retourner un objet *Account*`"]
        E --> H
```

```mermaid
---
title: Get-DomainOrUserOrPasswordReplacement
---
    graph
        A[Start] --> B["Demander les données à remplacer"]
        B --> C["`Appeller la fonction *Get-DomainOrUserOrPassword*`"]
        C --> D["Demander les données de remplacement"]
        D --> E["`Appeller la fonction *Get-DomainOrUserOrPassword*`"]
        E --> F{Il y a t'il une donnée manquante ?}
        F -- Oui --> G[Indiquer l'erreur à l'utilisateur]
        G --> A
        F -- Non --> H[ Retourner un objet AccountReplace]
```