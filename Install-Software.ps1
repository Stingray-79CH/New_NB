# ============================================================
# Software Installation mit WinGet
# ============================================================

# --- Administratorrechte prüfen ---
$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal   = New-Object Security.Principal.WindowsPrincipal($CurrentUser)

if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Host "Starte Skript mit Administratorrechten..." -ForegroundColor Yellow

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""

    exit
}

Clear-Host

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Software Installation" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# --- Prüfen ob WinGet vorhanden ist ---
if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {

    Write-Host "FEHLER: WinGet wurde nicht gefunden!" -ForegroundColor Red
    Write-Host ""
    Read-Host "ENTER drücken zum Beenden"
    exit 1
}


# --- Softwareliste ---
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


# --- WinGet Quellen aktualisieren ---
Write-Host "WinGet Quellen werden aktualisiert..." -ForegroundColor Yellow

winget source update

Write-Host ""


# --- Ergebnislisten ---
$Success = @()
$Failed  = @()


foreach ($Package in $Software) {

    Write-Host "-----------------------------------------" -ForegroundColor DarkGray
    Write-Host "Installiere: $Package" -ForegroundColor Cyan
    Write-Host "-----------------------------------------" -ForegroundColor DarkGray

    winget install `
        --id $Package `
        --exact `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements `
        --disable-interactivity

    $ExitCode = $LASTEXITCODE

    if ($ExitCode -eq 0) {

        Write-Host ""
        Write-Host "OK: $Package" -ForegroundColor Green

        $Success += $Package

    }
    else {

        Write-Host ""
        Write-Host "FEHLER bei $Package (ExitCode: $ExitCode)" -ForegroundColor Red

        $Failed += "$Package (ExitCode $ExitCode)"
    }

    Write-Host ""
}


# ============================================================
# Zusammenfassung
# ============================================================

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Zusammenfassung" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Erfolgreich:" -ForegroundColor Green

foreach ($Item in $Success) {
    Write-Host "  ✓ $Item" -ForegroundColor Green
}

Write-Host ""

if ($Failed.Count -gt 0) {

    Write-Host "Fehler:" -ForegroundColor Red

    foreach ($Item in $Failed) {
        Write-Host "  ✗ $Item" -ForegroundColor Red
    }

}
else {

    Write-Host "Keine Fehler aufgetreten." -ForegroundColor Green
}


Write-Host ""
Write-Host "Installation abgeschlossen." -ForegroundColor Cyan
Write-Host ""

Read-Host "ENTER drücken zum Beenden"
