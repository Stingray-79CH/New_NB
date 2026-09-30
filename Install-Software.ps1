# ============================================================
# New NB - Software Installation mit WinGet
# ============================================================

# ============================================================
# Administratorrechte prüfen
# ============================================================

$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentUser)

if (-not $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {

    Write-Host ""
    Write-Host "Administratorrechte werden benötigt..." -ForegroundColor Yellow
    Write-Host "Starte Skript erneut als Administrator." -ForegroundColor Yellow

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""

    exit
}


# ============================================================
# Konfiguration
# ============================================================

$LogDirectory = "C:\Temp"

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$LogFile = Join-Path `
    $LogDirectory `
    "NewNB-$env:COMPUTERNAME-$Timestamp.log"


# ============================================================
# Log-Verzeichnis erstellen
# ============================================================

if (-not (Test-Path $LogDirectory)) {

    New-Item `
        -Path $LogDirectory `
        -ItemType Directory `
        -Force | Out-Null
}


# ============================================================
# Log-Funktion
# ============================================================

function Write-Log {

    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $Time = Get-Date -Format "HH:mm:ss"

    $LogMessage = "[$Time] [$Level] $Message"

    Add-Content `
        -Path $LogFile `
        -Value $LogMessage `
        -Encoding UTF8
}


# ============================================================
# Start
# ============================================================

Clear-Host

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " New NB - Software Installation" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Computer : $env:COMPUTERNAME"
Write-Host "Benutzer : $env:USERNAME"
Write-Host "Logdatei : $LogFile"
Write-Host ""

Write-Log "====================================================="
Write-Log "New NB - Software Installation"
Write-Log "Computer: $env:COMPUTERNAME"
Write-Log "Benutzer: $env:USERNAME"
Write-Log "Start: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')"
Write-Log "====================================================="


# ============================================================
# WinGet prüfen
# ============================================================

Write-Host "Prüfe WinGet..." -ForegroundColor Yellow

$Winget = Get-Command winget.exe -ErrorAction SilentlyContinue

if (-not $Winget) {

    Write-Host ""
    Write-Host "FEHLER: WinGet wurde nicht gefunden!" -ForegroundColor Red

    Write-Log "WinGet wurde nicht gefunden." "ERROR"

    Write-Host ""
    Read-Host "ENTER drücken zum Beenden"

    exit 1
}


$WingetVersion = winget --version

Write-Host "WinGet gefunden: $WingetVersion" -ForegroundColor Green

Write-Log "WinGet gefunden: $WingetVersion"


# ============================================================
# Softwareliste
# ============================================================

$Software = @(

    "7zip.7zip"

    "Adobe.Acrobat.Reader.64-bit"

    "AutoHotkey.AutoHotkey"

    "Google.Chrome"

    "Inkscape.Inkscape"

    "IrfanSkiljan.IrfanView"

    "KeePassXCTeam.KeePassXC"

    "Notepad++.Notepad++"

    "PDFgear.PDFgear"

    "ShareX.ShareX"

    "VideoLAN.VLC"
)


# ============================================================
# WinGet Quellen aktualisieren
# ============================================================

Write-Host ""
Write-Host "Aktualisiere WinGet Quellen..." -ForegroundColor Yellow

Write-Log "WinGet Quellen werden aktualisiert."

$SourceOutput = & winget source update 2>&1

$SourceExitCode = $LASTEXITCODE

foreach ($Line in $SourceOutput) {

    Write-Host $Line

    Write-Log "WinGet: $Line"
}


if ($SourceExitCode -eq 0) {

    Write-Host ""
    Write-Host "WinGet Quellen erfolgreich aktualisiert." -ForegroundColor Green

    Write-Log "WinGet Quellen erfolgreich aktualisiert."

}
else {

    Write-Host ""
    Write-Host "Warnung: WinGet Quellen konnten nicht vollständig aktualisiert werden." `
        -ForegroundColor Yellow

    Write-Log `
        "WinGet Source Update ExitCode: $SourceExitCode" `
        "WARNING"
}


# ============================================================
# Ergebnislisten
# ============================================================

$Success = @()

$Failed = @()


# ============================================================
# Software installieren
# ============================================================

foreach ($Package in $Software) {

    Write-Host ""
    Write-Host "=====================================================" `
        -ForegroundColor DarkGray

    Write-Host "Installiere: $Package" `
        -ForegroundColor Cyan

    Write-Host "=====================================================" `
        -ForegroundColor DarkGray

    Write-Log ""
    Write-Log "Installation gestartet: $Package"


    # --------------------------------------------------------
    # Installation
    # --------------------------------------------------------

    $WingetOutput = & winget install `
        --id $Package `
        --exact `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements `
        --disable-interactivity `
        2>&1


    $ExitCode = $LASTEXITCODE


    # --------------------------------------------------------
    # WinGet Ausgabe anzeigen und protokollieren
    # --------------------------------------------------------

    foreach ($Line in $WingetOutput) {

        Write-Host $Line

        Write-Log "WinGet: $Line"
    }


    # --------------------------------------------------------
    # Ergebnis
    # --------------------------------------------------------

    if ($ExitCode -eq 0) {

        Write-Host ""
        Write-Host "OK: $Package" `
            -ForegroundColor Green

        Write-Log "Erfolgreich: $Package" "OK"

        $Success += $Package

    }
    else {

        Write-Host ""
        Write-Host "FEHLER: $Package" `
            -ForegroundColor Red

        Write-Host "ExitCode: $ExitCode" `
            -ForegroundColor Red

        Write-Log `
            "Fehler bei $Package - ExitCode $ExitCode" `
            "ERROR"

        $Failed += [PSCustomObject]@{

            Package  = $Package
            ExitCode = $ExitCode
        }
    }
}


# ============================================================
# Zusammenfassung
# ============================================================

Write-Host ""
Write-Host ""
Write-Host "=====================================================" `
    -ForegroundColor Cyan

Write-Host " Zusammenfassung" `
    -ForegroundColor Cyan

Write-Host "=====================================================" `
    -ForegroundColor Cyan

Write-Host ""


# ------------------------------------------------------------
# Erfolgreich
# ------------------------------------------------------------

Write-Host "Erfolgreich:" `
    -ForegroundColor Green

if ($Success.Count -gt 0) {

    foreach ($Item in $Success) {

        Write-Host "  [OK] $Item" `
            -ForegroundColor Green

        Write-Log "ERFOLGREICH: $Item"
    }

}
else {

    Write-Host "  Keine" `
        -ForegroundColor Yellow
}


Write-Host ""


# ------------------------------------------------------------
# Fehler
# ------------------------------------------------------------

if ($Failed.Count -gt 0) {

    Write-Host "Fehler:" `
        -ForegroundColor Red

    foreach ($Item in $Failed) {

        Write-Host `
            "  [FEHLER] $($Item.Package) - ExitCode $($Item.ExitCode)" `
            -ForegroundColor Red

        Write-Log `
            "FEHLER: $($Item.Package) - ExitCode $($Item.ExitCode)" `
            "ERROR"
    }

}
else {

    Write-Host "Keine Fehler aufgetreten." `
        -ForegroundColor Green

    Write-Log "Alle Installationen erfolgreich abgeschlossen."
}


# ============================================================
# Abschluss
# ============================================================

Write-Log ""
Write-Log "Installation beendet."
Write-Log "Ende: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')"

Write-Host ""
Write-Host "=====================================================" `
    -ForegroundColor Cyan

Write-Host " Installation abgeschlossen" `
    -ForegroundColor Cyan

Write-Host "=====================================================" `
    -ForegroundColor Cyan

Write-Host ""

Write-Host "Erfolgreich : $($Success.Count)" `
    -ForegroundColor Green

Write-Host "Fehler       : $($Failed.Count)" `
    -ForegroundColor $(

        if ($Failed.Count -gt 0) {
            "Red"
        }
        else {
            "Green"
        }
    )

Write-Host ""

Write-Host "Logdatei:" `
    -ForegroundColor Yellow

Write-Host $LogFile `
    -ForegroundColor White

Write-Host ""


# ============================================================
# Logdatei bei Fehler automatisch öffnen
# ============================================================

if ($Failed.Count -gt 0) {

    Write-Host "Es sind Fehler aufgetreten." `
        -ForegroundColor Red

    Write-Host "Die Logdatei wird geöffnet..." `
        -ForegroundColor Yellow

    Start-Process notepad.exe $LogFile
}


Write-Host ""

Read-Host "ENTER drücken zum Beenden"
