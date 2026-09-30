#requires -Version 5.1

# ============================================================================
# New NB - Universelle Softwareinstallation mit WinGet
# ============================================================================


# ============================================================================
# EINSTELLUNGEN
# ============================================================================

$UpdateExistingSoftware = $true
$UpdateWingetSources    = $true
$LogDirectory           = "C:\Temp"


# ============================================================================
# ADMINISTRATORRECHTE
# ============================================================================

$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal   = New-Object Security.Principal.WindowsPrincipal($CurrentUser)

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
        [AllowEmptyString()]
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

    Write-Log "WinGet wurde nicht gefunden." "ERROR"

    Write-Host ""
    Read-Host "ENTER drücken zum Beenden"

    exit 1
}

$WingetVersion = winget --version

Write-Host "WinGet gefunden: $WingetVersion" -ForegroundColor Green
Write-Host ""

Write-Log "WinGet gefunden: $WingetVersion" "OK"


# ============================================================================
# WINGET FUNKTIONSTEST
# ============================================================================

function Test-WingetSource {

    Write-Host "Teste WinGet Quelle..." -ForegroundColor Yellow
    Write-Log "Teste WinGet Quelle."

    $null = & winget search `
        --id "7zip.7zip" `
        --exact `
        --accept-source-agreements `
        2>&1

    $ExitCode = $LASTEXITCODE

    if ($ExitCode -eq 0) {

        Write-Host "WinGet Quelle funktioniert." -ForegroundColor Green
        Write-Log "WinGet Quelle funktioniert." "OK"

        return $true
    }

    Write-Host "WinGet Quelle ist fehlerhaft." -ForegroundColor Red
    Write-Log "WinGet Quellentest fehlgeschlagen. ExitCode: $ExitCode" "ERROR"

    return $false
}


# ============================================================================
# WINGET QUELLE REPARIEREN
# ============================================================================

function Repair-WingetSource {

    Write-Host ""
    Write-Host "WinGet Quelle wird repariert..." -ForegroundColor Yellow
    Write-Log "WinGet Quellenreparatur gestartet."

    $ResetOutput = & winget source reset --force 2>&1

    foreach ($Line in $ResetOutput) {

        Write-Host $Line
        Write-Log "WinGet: $Line"
    }

    Write-Host ""

    $UpdateOutput = & winget source update 2>&1

    foreach ($Line in $UpdateOutput) {

        Write-Host $Line
        Write-Log "WinGet: $Line"
    }

    Write-Host ""
    Write-Log "WinGet Quellenreparatur beendet."
}


# ============================================================================
# QUELLE VOR START TESTEN
# ============================================================================

$WingetSourceOK = Test-WingetSource

if (-not $WingetSourceOK) {

    Repair-WingetSource

    Write-Host ""
    Write-Host "Teste WinGet Quelle erneut..." -ForegroundColor Yellow

    $WingetSourceOK = Test-WingetSource
}


if (-not $WingetSourceOK) {

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host " FEHLER" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host ""

    Write-Host "Die WinGet Quelle funktioniert weiterhin nicht." -ForegroundColor Red
    Write-Host "Die Installation wird deshalb abgebrochen." -ForegroundColor Red

    Write-Log "WinGet Quelle konnte nicht repariert werden." "ERROR"

    Write-Host ""
    Write-Host "Logdatei:"
    Write-Host $LogFile
    Write-Host ""

    Read-Host "ENTER drücken zum Beenden"

    exit 1
}


# ============================================================================
# SOFTWARELISTEN
# ============================================================================


# ----------------------------------------------------------------------------
# STANDARD
# ----------------------------------------------------------------------------

$StandardSoftware = @(

    "7zip.7zip"

    "Google.Chrome"

    "Mozilla.Firefox"

    "Adobe.Acrobat.Reader.64-bit"

    "VideoLAN.VLC"

    "IrfanSkiljan.IrfanView"

    "Notepad++.Notepad++"

    "KeePassXCTeam.KeePassXC"

    "Microsoft.PowerToys"

    "voidtools.Everything"

    "JAMSoftware.TreeSize.Free"

    "Microsoft.PowerShell"
)


# ----------------------------------------------------------------------------
# POWER USER
# ----------------------------------------------------------------------------

$PowerUserSoftware = @(

    "ShareX.ShareX"

    "AutoHotkey.AutoHotkey"

    "PDFgear.PDFgear"

    "Microsoft.WindowsTerminal"
)


# ----------------------------------------------------------------------------
# IT / ADMIN
# ----------------------------------------------------------------------------

$ITSoftware = @(

    "Microsoft.VisualStudioCode"

    "Git.Git"

    "WinSCP.WinSCP"

    "PuTTY.PuTTY"

    "WiresharkFoundation.Wireshark"

    "Microsoft.Sysinternals.Suite"
)


# ----------------------------------------------------------------------------
# GRAFIK
# ----------------------------------------------------------------------------

$GraphicsSoftware = @(

    "Inkscape.Inkscape"

    "ShareX.ShareX"

    "PDFgear.PDFgear"
)


# ============================================================================
# PROFILAUSWAHL
# ============================================================================

Clear-Host

Write-Host ""
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


$Software = $Software | Sort-Object -Unique


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
# WINGET QUELLEN AKTUALISIEREN
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
        Write-Host "Warnung: WinGet Source Update nicht vollständig erfolgreich." `
            -ForegroundColor Yellow

        Write-Log `
            "WinGet Source Update ExitCode: $SourceExitCode" `
            "WARNING"
    }
}


# ============================================================================
# ERGEBNISLISTEN
# ============================================================================

$Installed        = @()
$Updated          = @()
$AlreadyInstalled = @()
$Failed           = @()


# ============================================================================
# SOFTWARE VERARBEITEN
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
                Write-Host "OK: $Package wurde aktualisiert." -ForegroundColor Green

                Write-Log "$Package wurde erfolgreich aktualisiert." "OK"

                $Updated += $Package
            }
            elseif ($ExitCode -eq -1978335189) {

                Write-Host ""
                Write-Host "OK: $Package ist bereits aktuell." -ForegroundColor Green

                Write-Log "$Package ist bereits aktuell." "OK"

                $AlreadyInstalled += $Package
            }
            else {

                Write-Host ""
                Write-Host "FEHLER beim Update von $Package" -ForegroundColor Red
                Write-Host "ExitCode: $ExitCode" -ForegroundColor Red

                Write-Log `
                    "Fehler beim Update von $Package - ExitCode $ExitCode" `
                    "ERROR"

                $Failed += [PSCustomObject]@{

                    Package  = $Package
                    ExitCode = $ExitCode
                }
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

Write-Host "Neu installiert: $($Installed.Count)" -ForegroundColor Green

foreach ($Item in $Installed) {

    Write-Host "  [INSTALLIERT] $Item" -ForegroundColor Green
}

Write-Host ""

Write-Host "Aktualisiert: $($Updated.Count)" -ForegroundColor Cyan

foreach ($Item in $Updated) {

    Write-Host "  [UPDATE] $Item" -ForegroundColor Cyan
}

Write-Host ""

Write-Host "Bereits aktuell / vorhanden: $($AlreadyInstalled.Count)" `
    -ForegroundColor Green

foreach ($Item in $AlreadyInstalled) {

    Write-Host "  [AKTUELL] $Item" -ForegroundColor Green
}

Write-Host ""

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
Write-Log "Bereits aktuell/vorhanden: $($AlreadyInstalled.Count)"
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


if ($Failed.Count -gt 0) {

    Write-Host "Es sind Installationsfehler aufgetreten." -ForegroundColor Red
    Write-Host "Die Logdatei wird automatisch geöffnet." -ForegroundColor Yellow
    Write-Host ""

    Start-Process notepad.exe $LogFile
}
else {

    Write-Host "Alle Installationen wurden erfolgreich verarbeitet." `
        -ForegroundColor Green
}


Write-Host ""
Read-Host "ENTER drücken zum Beenden"
