#SingleInstance Force
CapsLock::Ctrl
~CapsLock Up::Send "{Ctrl up}" (A_PriorKey = "CapsLock" ? "{Esc}" : "")
>+CapsLock::SetCapsLockState !GetKeyState("CapsLock", "T")

; Append a dummy win to prevent toggle Chinese/English for IM
<+Space::Send (A_PriorKey = "LShift" ? "+{Space}" : "{Blind}{Shift up}{Space}{Shift down}{LWin}")
>+Space::Send (A_PriorKey = "RShift" ? "+{Space}" : "{Blind}{Shift up}{Space}{Shift down}{LWin}")

; Typography
^!#[::Send "“"  ; LEFT DOUBLE QUOTATION MARK 201C
+^!#[::Send "”" ; RIGHT SINGLE QUOTATION MARK 201D
^!#]::Send "‘"  ; LEFT SINGLE QUOTATION MARK 2018
+^!#]::Send "’" ; RIGHT SINGLE QUOTATION MARK 2019
^!#'::Send "′"  ; PRIME 2032
+^!#'::Send "″" ; DOUBLE PRIME 2033
^!#-::Send "–"  ; EN DASH 2013
+^!#-::Send "—" ; EM DASH 2014
^!#\::Send "–"  ; EN DASH 2013
+^!#\::Send "—" ; EM DASH 2014

#^t::WinSetAlwaysOnTop -1, "A"

#+p::{
  q := Chr(34)
  Run 'wt nt -d "~" --title "fpass" pwsh -NoProfile -NoLogo -File ' q A_MyDocuments '\PowerShell\bin\fpass-popup.ps1' q
  SetTitleMatchMode 2
  if hwnd := WinWait("fpass", , 3) {
    WinGetPos &x, &y, &w, &h, hwnd
    WinMove (A_ScreenWidth - w) // 2, (A_ScreenHeight - h) // 2, , , hwnd
    WinActivate hwnd
  }
}

#y::{
  q := Chr(34)
  Run 'wt nt -d "~" --title "fwin" pwsh -NoProfile -NoLogo -File ' q A_MyDocuments '\PowerShell\bin\fwin-popup.ps1' q
  SetTitleMatchMode 2
  if hwnd := WinWait("fwin", , 3) {
    WinGetPos &x, &y, &w, &h, hwnd
    WinMove (A_ScreenWidth - w) // 2, (A_ScreenHeight - h) // 2, , , hwnd
    WinActivate hwnd
  }
}

#q::!F4
#^q::#^F4

#F11::RunWait('pwsh -NoProfile -File "' A_ScriptDir '\..\bin\kmrb.ps1"', , "Hide")
#F12::Reload

!Volume_Up::Run 'monctl -b 1+ -m 1',, "Hide"
!Volume_Down::Run 'monctl -b 1- -m 1',, "Hide"
Launch_Mail::Run 'monctl 5 -m 1',, "Hide"
#!o::{
  Run 'monctl 5 -m 1',, "Hide"
  Run 'displayswitch /internal',, "Hide"
}
#!p::{
  Run 'monctl 15 -m 1',, "Hide"
  Run 'displayswitch /external',, "Hide"
}
+#!p::{
  Run 'monctl 15 -m 1',, "Hide"
  Run 'displayswitch /extend',, "Hide"
}

XButton2::Send "{XButton2}"
XButton2 & WheelUp::Send "{WheelLeft}"
XButton2 & WheelDown::Send "{WheelRight}"

;; App Specific
PasteFromClipman := false
#HotIf WinActive("ahk_exe WindowsTerminal.exe") || WinActive("ahk_exe nvim-qt.exe")
~#v::global PasteFromClipman := true
#HotIf PasteFromClipman
^v::{
  Send "^+v"
  global PasteFromClipman := false
}
#HotIf

;; Snippets
:*:ddate::{
  Send FormatTime(, "yyyy-MM-dd")
}
