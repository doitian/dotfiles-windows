#SingleInstance Force
CapsLock::Ctrl
~CapsLock Up::Send "{Ctrl up}" (A_PriorKey = "CapsLock" ? "{Esc}" : "")
>+CapsLock::SetCapsLockState !GetKeyState("CapsLock", "T")
~RControl Up::Send "{Ctrl up}" (A_PriorKey = "RControl" ? "{Esc}" : "")

*<+<#f23:: {
    Send("{Blind}{LShift Up}{LWin Up}{RWin Down}")
    KeyWait("F23")
    Send("{RWin up}")
}

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
^!#/::Send "⋯"  ; MIDLINE HORIZONTAL ELLIPSIS
+^!#/::Send "…" ; HORIZONTAL ELLIPSIS

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

#F11::ScriptManager.Show()
#F12::Reload

!Volume_Up::Run 'monctl -b 1+ -m G95NC',, "Hide"
!Volume_Down::Run 'monctl -b 1- -m G95NC',, "Hide"
Launch_Mail::Run 'monctl 5 -m G95NC',, "Hide"
#!o::{
  Run 'monctl 5 -m G95NC',, "Hide"
  Run 'displayswitch /internal',, "Hide"
}
#!p::{
  Run 'monctl 15 -m G95NC',, "Hide"
  Run 'displayswitch /external',, "Hide"
}
+#!p::{
  Run 'monctl 15 -m G95NC',, "Hide"
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

; File Explorer
#HotIf WinActive("ahk_class CabinetWClass")
^!l::ExploreTo("shell:Downloads")
^+d::ExploreTo("shell:Desktop")
^+h::ExploreTo("shell:Profile")
#HotIf

ExploreTo(target) {
    ; Alt+D focuses address bar, then we type the shell path
    Send "!d"                 ; focus address bar
    Sleep 50                  ; tiny pause so Explorer catches up
    Send target "{Enter}"     ; navigate current window
}

; OneNote
#HotIf WinActive("ahk_exe ONENOTE.EXE")
+WheelDown::Send("{WheelRight}")
+WheelUp::Send("{WheelLeft}")

WheelUp::Send("{WheelUp}")
WheelDown::Send("{WheelDown}")
#HotIf

;; Snippets
:*:ddate::{
  Send FormatTime(, "yyyy-MM-dd")
}

class ScriptManager {
  static g := 0, lv := 0, btnStart := 0, btnStop := 0, btnReload := 0

  static Show() {
    if this.g
      this.g.Destroy()
    this.g := Gui("+AlwaysOnTop", "AHK Script Manager")
    this.g.OnEvent("Close", (*) => this.g.Destroy())
    this.g.OnEvent("Escape", (*) => this.g.Destroy())
    this.lv := this.g.Add("ListView", "w400 r10 -Multi +Grid", ["Script", "Status"])
    this.btnStart := this.g.Add("Button", "Section w80 Disabled", "&Start")
    this.btnStop := this.g.Add("Button", "x+10 w80 Disabled", "S&top")
    this.btnReload := this.g.Add("Button", "x+10 w80 Disabled", "&Reload")
    this.g.Add("Button", "x+10 w80", "Re&fresh").OnEvent("Click", (*) => this.Refresh())
    this.lv.OnEvent("ItemSelect", (*) => this.UpdateButtons())
    this.btnStart.OnEvent("Click", (*) => this.DoAction("start"))
    this.btnStop.OnEvent("Click", (*) => this.DoAction("stop"))
    this.btnReload.OnEvent("Click", (*) => this.DoAction("reload"))
    this.Refresh()
    this.g.Show()
  }

  static Refresh() {
    this.lv.Delete()
    saved := A_DetectHiddenWindows
    DetectHiddenWindows true
    loop Files A_ScriptDir "\*.ahk"
      this.lv.Add(, A_LoopFileName,
        WinExist(A_LoopFileFullPath " ahk_class AutoHotkey") ? "Running" : "Stopped")
    DetectHiddenWindows saved
    this.lv.ModifyCol(1, 260)
    this.lv.ModifyCol(2, 100)
    this.UpdateButtons()
  }

  static UpdateButtons() {
    row := this.lv.GetNext()
    if !row {
      this.btnStart.Enabled := false
      this.btnStop.Enabled := false
      this.btnReload.Enabled := false
      return
    }
    running := this.lv.GetText(row, 2) = "Running"
    this.btnStart.Enabled := !running
    this.btnStop.Enabled := running
    this.btnReload.Enabled := running
  }

  static DoAction(action) {
    row := this.lv.GetNext()
    if !row
      return
    path := A_ScriptDir "\" this.lv.GetText(row, 1)
    if action = "start" {
      saved := A_DetectHiddenWindows
      DetectHiddenWindows true
      if !WinExist(path " ahk_class AutoHotkey")
        Run path
      DetectHiddenWindows saved
    } else {
      saved := A_DetectHiddenWindows
      DetectHiddenWindows true
      if WinExist(path " ahk_class AutoHotkey")
        PostMessage 0x0111, action = "reload" ? 65303 : 65307
      DetectHiddenWindows saved
    }
    Sleep 500
    this.Refresh()
  }
}
