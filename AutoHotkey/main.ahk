CapsLock::Ctrl
~CapsLock Up::Send "{Ctrl up}" (A_PriorKey = "CapsLock" ? "{Esc}" : "")
>^CapsLock::SetCapsLockState !GetKeyState("CapsLock", "T")

; Append a dummy win to prevent toggle Chinese/English for IM
<+Space::Send (A_PriorKey = "LShift" ? "+{Space}" : "{Blind}{Shift up}{Space}{Shift down}{LWin}")
>+Space::Send (A_PriorKey = "RShift" ? "+{Space}" : "{Blind}{Shift up}{Space}{Shift down}{LWin}")

>!j::Left
>!l::Right
>!i::Up
>!k::Down

#^t::WinSetAlwaysOnTop -1, "A"

+F12::Run "wt -w _quake nt --title fpass fpass.cmd"
#F12::Reload

;; App Specific
PasteFromClipman := true
#HotIf WinActive("ahk_exe WindowsTerminal.exe") || WinActive("ahk_exe nvim-qt.exe")
#v::{
  global
  PasteFromClipman := true
  Send "#v"
}
^v::{
  global
  if (PasteFromClipman) {
    PasteFromClipman := false
    Send "^+v"
  } else {
    Send "^v"
  }
}
#HotIf

;; Snippets
:*:ddate::{
  Send FormatTime(, "yyyy-MM-dd")
}
