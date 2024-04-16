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

XButton2::StartPan()
XButton2 Up::StopPan()
panCenterX := 0
panCenterY := 0
StartPan() {
  global panCenterX, panCenterY
  MouseGetPos &panCenterX, &panCenterY
  SetTimer DoPan, 200
  DoPan()
}
StopPan() {
  SetTimer DoPan, 0
}
DoPan() {
  global panCenterX, panCenterY
  MouseGetPos &x, &y
  xInterval := 400
  yInterval := 400
  if (x + 100 < panCenterX) {
    xInterval := Floor(40000 / (panCenterX - x))
    Send "{WheelLeft}"
  } else if (x > panCenterX + 100) {
    xInterval := Floor(40000 / (x - panCenterX))
    Send "{WheelRight}"
  }
  if (y + 100 < panCenterY) {
    yInterval := Floor(40000 / (panCenterY - y))
    Send "{WheelUp}"
  } else if (y > panCenterY + 144) {
    yInterval := Floor(40000 / (y - panCenterY))
    Send "{WheelDown}"
  }
  if (xInterval < yInterval) {
    SetTimer DoPan, xInterval
  } else {
    SetTimer DoPan, yInterval
  }
}

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
