#requires -Version 5.1

# ============================================================================
# New NB - Universelle Softwareinstallation mit WinGet
# ============================================================================
#
# Profile:
#   1 = Standard Notebook
#   2 = Power User
#   3 = IT / Admin
#   4 = Grafik
#
# Funktionen:
#   - Automatische Administratorrechte
#   - WinGet-Prüfung
#   - Profilauswahl
#   - Erkennung bereits installierter Software
#   - Optionales Aktualisieren installierter Software
#   - Silent Installation
#   - Detailliertes Logging
#   - Zusammenfassung am Schluss
#
# ============================================================================


# ============================================================================
# EINSTELLUNGEN
# ============================================================================

# Bereits installierte Programme aktualisieren?
$UpdateExistingSoftware = $true

# Log-Verzeichnis
$LogDirectory = "C:\Temp"

# WinGet Source vor Installation aktualisieren?
$UpdateWingetSources = $true


# ============================================================================
# ADMINISTRATORRECHTE
# ============================================================================

$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()

$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentUser)

$IsAdmin = $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdmin) {

    Write-Host ""
    Write-Host "Administratorrechte werden benötigt." -ForegroundColor Yellow
    Write-Host "Das Skript wird als Administrator neu gestartet..." -ForegroundColor Yellow
    Write-Host ""

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""

    exit
}


# ============================================================================
# LOGDATEI
# ============================================================================

if (-not (Test-Path $LogDirectory)) {

    New-Item `
        -Path $LogDirectory `
        -ItemType Directory `
        -Force | Out-Null
}

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$LogFile = Join-Path `
    $LogDirectory `
    "NewNB-$env:COMPUTERNAME-$Timestamp.log"


function Write-Log {

    param (

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet(
            "INFO",
            "OK",
            "WARNING",
            "ERROR"
        )]
        [string]$Level = "INFO"
    )

    $Time = Get-Date -Format "HH:mm:ss"

    $LogMessage = "[$Time] [$Level] $Message"

    Add-Content `
        -Path $LogFile `
        -Value $LogMessage `
        -Encoding UTF8
}


# ============================================================================
# HEADER
# ============================================================================

Clear-Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " NEW NB - Software Installation" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Computer : $env:COMPUTERNAME"
Write-Host "Benutzer : $env:USERNAME"
Write-Host "Datum     : $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')"
Write-Host ""

Write-Host "Logdatei:" -ForegroundColor DarkGray
Write-Host $LogFile -ForegroundColor DarkGray
Write-Host ""

Write-Log "============================================================"
Write-Log "New NB - Software Installation"
Write-Log "Computer: $env:COMPUTERNAME"
Write-Log "Benutzer: $env:USERNAME"
Write-Log "Start: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')"
Write-Log "============================================================"


# ============================================================================
# WINGET PRÜFEN
# ============================================================================

Write-Host "Prüfe WinGet..." -ForegroundColor Yellow

$Winget = Get-Command winget.exe -ErrorAction SilentlyContinue

if (-not $Winget) {

    Write-Host ""
    Write-Host "FEHLER: WinGet wurde nicht gefunden!" -ForegroundColor Red
    Write-Host ""

    Write-Log "WinGet wurde nicht gefunden." "ERROR"

    Read-Host "ENTER drücken zum Beenden"

    exit 1
}

$WingetVersion = winget --version

Write-Host "WinGet gefunden: $WingetVersion" -ForegroundColor Green
Write-Host ""

Write-Log "WinGet gefunden: $WingetVersion" "OK"


# ============================================================================
# SOFTWARELISTEN
# ============================================================================


# ----------------------------------------------------------------------------
# STANDARD
# ----------------------------------------------------------------------------

$StandardSoftware = @(

    # Archiv
    "7zip.7zip"

    # Browser
    "Google.Chrome"
    "Mozilla.Firefox"

    # PDF
    "Adobe.Acrobat.Reader.64-bit"

    # Multimedia
    "VideoLAN.VLC"

    # Bildbetrachter
    "IrfanSkiljan.IrfanView"

    # Texteditor
    "Notepad++.Notepad++"

    # Passwortmanager
    "KeePassXCTeam.KeePassXC"

    # Windows Erweiterungen
    "Microsoft.PowerToys"

    # Dateisuche
    "voidtools.Everything"

    # Speicheranalyse
    "JAMSoftware.TreeSize.Free"

    # PowerShell
    "Microsoft.PowerShell"
)


# ----------------------------------------------------------------------------
# POWER USER
# ----------------------------------------------------------------------------

$PowerUserSoftware = @(

    # Screenshot Tool
    "ShareX.ShareX"

    # Automation
    "AutoHotkey.AutoHotkey"

    # Erweiterter PDF Editor
    "PDFgear.PDFgear"

    # Windows Terminal
    "Microsoft.WindowsTerminal"
)


# ----------------------------------------------------------------------------
# IT / ADMIN
# ----------------------------------------------------------------------------

$ITSoftware = @(

    # Code Editor
    "Microsoft.VisualStudioCode"

    # Git
    "Git.Git"

    # SCP / SFTP
    "WinSCP.WinSCP"

    # SSH / Telnet
    "PuTTY.PuTTY"

    # Netzwerk Analyse
    "WiresharkFoundation.Wireshark"

    # Microsoft Sysinternals
    "Microsoft.Sysinternals"
)


# ----------------------------------------------------------------------------
# GRAFIK
# ----------------------------------------------------------------------------

$GraphicsSoftware = @(

    # Vektorgrafik
    "Inkscape.Inkscape"

    # Screenshot / Bildbearbeitung
    "ShareX.ShareX"

    # Erweiterter PDF Editor
    "PDFgear.PDFgear"
)


# ============================================================================
# PROFILAUSWAHL
# ============================================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Installationsprofil auswählen" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1] Standard Notebook" -ForegroundColor White
Write-Host "    Allgemeine Software für normale Windows Notebooks"
Write-Host ""

Write-Host "[2] Power User" -ForegroundColor Green
Write-Host "    Standard + ShareX + AutoHotkey + PDFgear + Terminal"
Write-Host ""

Write-Host "[3] IT / Admin" -ForegroundColor Yellow
Write-Host "    Standard + Power User + IT/Admin Tools"
Write-Host ""

Write-Host "[4] Grafik" -ForegroundColor Magenta
Write-Host "    Standard + Inkscape + ShareX + PDFgear"
Write-Host ""

Write-Host "------------------------------------------------------------"
Write-Host ""

do {

    $ProfileSelection = Read-Host "Profil auswählen [1-4]"

} until ($ProfileSelection -match '^[1-4]$')


# ============================================================================
# SOFTWARELISTE ERSTELLEN
# ============================================================================

switch ($ProfileSelection) {

    "1" {

        $ProfileName = "Standard Notebook"

        $Software = $StandardSoftware
    }


    "2" {

        $ProfileName = "Power User"

        $Software = @(
            $StandardSoftware
            $PowerUserSoftware
        )
    }


    "3" {

        $ProfileName = "IT / Admin"

        $Software = @(
            $StandardSoftware
            $PowerUserSoftware
            $ITSoftware
        )
    }


    "4" {

        $ProfileName = "Grafik"

        $Software = @(
            $StandardSoftware
            $GraphicsSoftware
        )
    }
}


# Doppelte Einträge entfernen

$Software = $Software |
    Sort-Object -Unique


Clear-Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Profil: $ProfileName" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Folgende Software wird verarbeitet:" -ForegroundColor Yellow
Write-Host ""

foreach ($Package in $Software) {

    Write-Host "  $Package"
}

Write-Host ""
Write-Host "Programme insgesamt: $($Software.Count)" -ForegroundColor Cyan
Write-Host ""

Write-Log "Gewähltes Profil: $ProfileName"
Write-Log "Anzahl Pakete: $($Software.Count)"


# ============================================================================
# BESTÄTIGUNG
# ============================================================================

$Confirmation = Read-Host "Installation starten? [J/N]"

if ($Confirmation -notmatch '^[JjYy]$') {

    Write-Host ""
    Write-Host "Installation abgebrochen." -ForegroundColor Yellow

    Write-Log "Installation durch Benutzer abgebrochen." "WARNING"

    Start-Sleep -Seconds 2

    exit
}


# ============================================================================
# WINGET SOURCES AKTUALISIEREN
# ============================================================================

if ($UpdateWingetSources) {

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " WinGet Quellen aktualisieren" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Log "WinGet Quellen werden aktualisiert."

    $SourceOutput = & winget source update 2>&1

    $SourceExitCode = $LASTEXITCODE

    foreach ($Line in $SourceOutput) {

        Write-Host $Line

        Write-Log "WinGet: $Line"
    }


    if ($SourceExitCode -eq 0) {

        Write-Host ""
        Write-Host "WinGet Quellen aktualisiert." -ForegroundColor Green

        Write-Log "WinGet Quellen aktualisiert." "OK"
    }
    else {

        Write-Host ""
        Write-Host "WARNUNG: Source Update mit Fehler beendet." -ForegroundColor Yellow

        Write-Log `
            "Winget Source Update ExitCode: $SourceExitCode" `
            "WARNING"
    }
}


# ============================================================================
# ERGEBNISLISTEN
# ============================================================================

$Installed = @()

$Updated = @()

$AlreadyInstalled = @()

$Failed = @()


# ============================================================================
# SOFTWARE INSTALLIEREN
# ============================================================================

foreach ($Package in $Software) {

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor DarkGray
    Write-Host " $Package" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor DarkGray
    Write-Host ""

    Write-Log ""
    Write-Log "Verarbeite Paket: $Package"


    # ========================================================================
    # PRÜFEN OB INSTALLIERT
    # ========================================================================

    $null = & winget list `
        --id $Package `
        --exact `
        --accept-source-agreements `
        2>$null

    $ListExitCode = $LASTEXITCODE


    # ========================================================================
    # BEREITS INSTALLIERT
    # ========================================================================

    if ($ListExitCode -eq 0) {

        Write-Host "Bereits installiert." -ForegroundColor Yellow

        Write-Log "$Package ist bereits installiert."


        # --------------------------------------------------------------------
        # UPDATE
        # --------------------------------------------------------------------

        if ($UpdateExistingSoftware) {

            Write-Host "Prüfe auf Update..." -ForegroundColor Yellow
            Write-Host ""

            Write-Log "Prüfe Update für $Package."


            $WingetOutput = & winget upgrade `
                --id $Package `
                --exact `
                --silent `
                --accept-package-agreements `
                --accept-source-agreements `
                --disable-interactivity `
                2>&1


            $ExitCode = $LASTEXITCODE


            foreach ($Line in $WingetOutput) {

                Write-Host $Line

                Write-Log "WinGet: $Line"
            }


            if ($ExitCode -eq 0) {

                Write-Host ""
                Write-Host "OK: $Package verarbeitet." -ForegroundColor Green

                Write-Log "$Package Update erfolgreich verarbeitet." "OK"

                $Updated += $Package
            }
            else {

                # Winget liefert bei fehlendem Update je nach Version ebenfalls
                # einen eigenen Rückgabecode. Deshalb nicht sofort als
                # Installationsfehler behandeln.

                Write-Host ""
                Write-Host "Kein Update durchgeführt." -ForegroundColor DarkYellow

                Write-Log `
                    "$Package: Kein Update durchgeführt. ExitCode $ExitCode" `
                    "WARNING"

                $AlreadyInstalled += $Package
            }
        }
        else {

            Write-Host "Update deaktiviert - wird übersprungen." -ForegroundColor DarkGray

            Write-Log "$Package wird übersprungen."

            $AlreadyInstalled += $Package
        }


        continue
    }


    # ========================================================================
    # NEU INSTALLIEREN
    # ========================================================================

    Write-Host "Nicht installiert." -ForegroundColor DarkGray
    Write-Host "Installation wird gestartet..." -ForegroundColor Yellow
    Write-Host ""

    Write-Log "Installation gestartet: $Package"


    $WingetOutput = & winget install `
        --id $Package `
        --exact `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements `
        --disable-interactivity `
        2>&1


    $ExitCode = $LASTEXITCODE


    foreach ($Line in $WingetOutput) {

        Write-Host $Line

        Write-Log "WinGet: $Line"
    }


    # ========================================================================
    # ERGEBNIS
    # ========================================================================

    if ($ExitCode -eq 0) {

        Write-Host ""
        Write-Host "OK: $Package wurde installiert." -ForegroundColor Green

        Write-Log "$Package wurde erfolgreich installiert." "OK"

        $Installed += $Package
    }
    else {

        Write-Host ""
        Write-Host "FEHLER bei $Package" -ForegroundColor Red
        Write-Host "ExitCode: $ExitCode" -ForegroundColor Red

        Write-Log `
            "Fehler bei $Package - ExitCode $ExitCode" `
            "ERROR"

        $Failed += [PSCustomObject]@{

            Package  = $Package
            ExitCode = $ExitCode
        }
    }
}


# ============================================================================
# ZUSAMMENFASSUNG
# ============================================================================

Clear-Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Installation abgeschlossen" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Computer : $env:COMPUTERNAME"
Write-Host "Profil   : $ProfileName"
Write-Host ""


# ----------------------------------------------------------------------------
# NEU INSTALLIERT
# ----------------------------------------------------------------------------

Write-Host "Neu installiert: $($Installed.Count)" -ForegroundColor Green

foreach ($Item in $Installed) {

    Write-Host "  [INSTALLIERT] $Item" -ForegroundColor Green
}

Write-Host ""


# ----------------------------------------------------------------------------
# AKTUALISIERT
# ----------------------------------------------------------------------------

Write-Host "Aktualisiert/verarbeitet: $($Updated.Count)" -ForegroundColor Cyan

foreach ($Item in $Updated) {

    Write-Host "  [UPDATE] $Item" -ForegroundColor Cyan
}

Write-Host ""


# ----------------------------------------------------------------------------
# BEREITS INSTALLIERT
# ----------------------------------------------------------------------------

Write-Host "Bereits installiert / kein Update: $($AlreadyInstalled.Count)" `
    -ForegroundColor Yellow

foreach ($Item in $AlreadyInstalled) {

    Write-Host "  [VORHANDEN] $Item" -ForegroundColor Yellow
}

Write-Host ""


# ----------------------------------------------------------------------------
# FEHLER
# ----------------------------------------------------------------------------

if ($Failed.Count -gt 0) {

    Write-Host "Fehler: $($Failed.Count)" -ForegroundColor Red

    foreach ($Item in $Failed) {

        Write-Host `
            "  [FEHLER] $($Item.Package) - ExitCode $($Item.ExitCode)" `
            -ForegroundColor Red
    }
}
else {

    Write-Host "Fehler: 0" -ForegroundColor Green
}

Write-Host ""


# ============================================================================
# LOG ZUSAMMENFASSUNG
# ============================================================================

Write-Log ""
Write-Log "============================================================"
Write-Log "ZUSAMMENFASSUNG"
Write-Log "Profil: $ProfileName"
Write-Log "Neu installiert: $($Installed.Count)"
Write-Log "Updates: $($Updated.Count)"
Write-Log "Bereits vorhanden: $($AlreadyInstalled.Count)"
Write-Log "Fehler: $($Failed.Count)"
Write-Log "Ende: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')"
Write-Log "============================================================"


# ============================================================================
# ABSCHLUSS
# ============================================================================

Write-Host "------------------------------------------------------------"
Write-Host ""

Write-Host "Logdatei:" -ForegroundColor Yellow
Write-Host $LogFile -ForegroundColor White

Write-Host ""


# Bei Fehlern Logdatei automatisch öffnen

if ($Failed.Count -gt 0) {

    Write-Host "Es sind Installationsfehler aufgetreten." -ForegroundColor Red
    Write-Host "Die Logdatei wird automatisch geöffnet." -ForegroundColor Yellow
    Write-Host ""

    Start-Process notepad.exe $LogFile
}
else {

    Write-Host "Alle Installationen wurden verarbeitet." -ForegroundColor Green
}


Write-Host ""
Read-Host "ENTER drücken zum Beenden"
