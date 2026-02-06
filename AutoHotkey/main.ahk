#SingleInstance Force
CapsLock::Ctrl
~CapsLock Up::Send "{Ctrl up}" (A_PriorKey = "CapsLock" ? "{Esc}" : "")
>^CapsLock::SetCapsLockState !GetKeyState("CapsLock", "T")

; Append a dummy win to prevent toggle Chinese/English for IM
<+Space::Send (A_PriorKey = "LShift" ? "+{Space}" : "{Blind}{Shift up}{Space}{Shift down}{LWin}")
>+Space::Send (A_PriorKey = "RShift" ? "+{Space}" : "{Blind}{Shift up}{Space}{Shift down}{LWin}")

; Right Alt + jkli: arrows
>!j::Left
>!l::Right
>!i::Up
>!k::Down

; Right Win: typography
>#[::Send "“"
+>#[::Send "”"
>#]::Send "‘"
+>#]::Send "’"
>#'::Send "′"
+>#'::Send "″"
>#-::Send "–"
+>#-::Send "—"

#^t::WinSetAlwaysOnTop -1, "A"

#+p::{
  q := Chr(34)
  Run 'wt -w _fzfpopup nt -d "~" --title "gopass" pwsh -NoProfile -File ' q A_MyDocuments '\PowerShell\bin\fpass-popup.ps1' q
  SetTitleMatchMode 2
  if WinWait("gopass", , 3) {
    WinGetPos &x, &y, &w, &h
    WinMove (A_ScreenWidth - w) // 2, (A_ScreenHeight - h) // 2
    WinActivate
  }
}

#q::Send "!{F4}"

#F11::RunWait('pwsh -NoProfile -File "' A_ScriptDir '\..\bin\kmrb.ps1" -bar', , "Hide")
#F12::Reload

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
