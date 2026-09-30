#Requires AutoHotkey v2.0

; Das ist ein AutoHotkey v2 Script

; Modifier-Keys:
; # = Windows-Taste  |  ! = Alt  |  ^ = Ctrl (Strg)  |  + = Shift  |  <^>! = AltGr
; <! = Linke Alt-Taste  |  >! = Rechte Alt-Taste  |  <+ = Linke Shift-Taste  | >^ = Rechte Ctrl-Taste  |  usw.

; Abkürzungen
; :*:wgi::winget install --Source winget --id wird sofort angewant
; ::wgi::winget install --Source winget --id erst nach Leertaste, Tap oder Enter
;Der Stern (*) ersetzt sofort


:*:wgi::winget install --Source winget --id 
:*:GL_::Geschäftsleitung
:*:bei_::Bei Fragen stehe ich Ihnen gerne zur Verfügung
:*:beid_::Bei Fragen stehe ich dir gerne zur Verfügung
:*:fiw_::Firmware
:*:hw_::Hardware
:*:sw_::Software
:*:ho_::Homeoffice
:*:LW_::Laufwerk 
:*:NB__::Notebook
:*:hd_::Harddisk
:*:FrG::Freundliche Grüsse{Enter}Vorname Name
:*:MfG::Freundliche Grüsse{Enter}Vorname Name
:*:fb_::Feedback 
:*:Konfig_::Konfiguration
:*:Stev::Stellvertretung 
:*:Rm_::Rückmeldung
:*:fyi::For your information
:*:AP_::Arbeitsplatz 
:*:M365_::Microsoft 365
:*:email::E-Mail
:*:FW_::Firewall
:*:def.::defektes
:*:re_::Reverse Engineering
:*:ps_::PowerShell
:*:vpni::vpn.intersys.ch

; Test mit formatiertem Text und nach einem (Enter,Tap oder Leertaste)
::_test::Das ist ein Test{Enter}Auf der neuen Zeile 🖖

; Nicht so: ::_test:: sendtext "Das ist ein Test{Enter}Auf der neuen Zeile 🖖"

; Neubelegung Tasten
+ü:: sendtext "Ü"							; Shift und ü senden ein grosses "Ü"
+ö:: sendtext "Ö"							; Shift und ö senden ein grosses "Ö"
+ä:: sendtext "Ä"							; Shift und ä senden ein grosses "Ä"
^ü:: sendtext "è"							; Ctrl (Strg) und ü senden "è"
^ö:: sendtext "é"							; Ctrl (Strg) und ö senden "é"
^ä:: sendtext "à"							; Ctrl (Strg) und ä senden "à"

;Programm Starten
^+p:: run "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Consultinform\Project Account.lnk"

; Mit Chrom im neuen Fester
^u:: run "chrome.exe " "--new-window https://intersys.ch/ueber-uns/#team"

;Dieser Hotkey funktioniert nur in Notepad
;#HotIf WinActive("ahk_exe notepad++.exe")
;F1::MsgBox "Dieser Hotkey funktioniert nur in Notepad++"
;#HotIf
;Erklärung:
;WinActive("ahk_exe notepad.exe") prüft, ob das aktive Fenster zu notepad.exe gehört.
;F1:: ... definiert den Hotkey.
;#HotIf ohne Bedingung beendet die Einschränkung, damit nachfolgende Hotkeys wieder überall gelten.

;Aktuelles Skript Editieren
^+NumpadMult::
{
     Edit
}
;Aktuelles Skript speicher und neu Laden
; Gilt nur in Notepad++
#HotIf WinActive("ahk_exe notepad++.exe")
^+NumpadSub:: {
    Send "^{s}"            ; speichern
    Sleep 200              ; kurzen Moment warten
    ToolTip "Gespeichert … lade Skript neu ..."
    ; Nach 2 s Tooltip ausblenden und Skript neu laden (One-Shot Timer)
    ShowBigToast("Gespeichert – lade Skript neu ...", 2000, 18)
}
#HotIf

ShowBigToast(msg, ms := 2000, fontSize := 18) {
    g := Gui("+AlwaysOnTop -Caption +ToolWindow")
    g.MarginX := 20, g.MarginY := 14
    g.SetFont("s" fontSize " Bold", "Segoe UI")
    g.Add("Text", "Center", msg)
    g.Show("AutoSize Center")        ; zentriert anzeigen
    SetTimer (() => (g.Destroy(), Reload())), -ms
}

;Setzt den Tag Datum und Kürzel
^Numpad0::
{
    datum := FormatTime(, "yyyyMMdd")
    SendText datum "-XX: "
}

;Setzt den Tag Datum Zeit und Kürzel
^Numpad1::
{
    datum := FormatTime(, "yyyyMMdd-HH:mm:ss")
    SendText datum "-XX: "
}

;Setzt den Tag Datum
^Numpad2::
{
    datum := FormatTime(, "yyyyMMdd")
    SendText datum "_"
}