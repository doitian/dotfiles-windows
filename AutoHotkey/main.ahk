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

#F12::Reload

XButton2::Send "{XButton2}"
XButton2 & e::WheelUp
XButton2 & d::WheelDown
XButton2 & s::WheelLeft
XButton2 & f::WheelRight
XButton1::Send "{XButton1}"
XButton1 & e::Send "{WheelUp 3}"
XButton1 & d::Send "{WheelDown 3}"
XButton1 & s::Send "{WheelLeft 3}"
XButton1 & f::Send "{WheelRight 3}"

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
