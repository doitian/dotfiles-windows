#Requires AutoHotkey v2.0.2
#SingleInstance Force

Komorebic(cmd) {
    RunWait(format("komorebic.exe {}", cmd), , "Hide")
}

#+q::{
    Komorebic("stop --bar")
    ExitApp()
}

; Focus windows
!h::Komorebic("focus left")
!j::Komorebic("focus down")
!k::Komorebic("focus up")
!l::Komorebic("focus right")
!y::Komorebic("promote-focus")

; Move windows
!^h::Komorebic("move left")
!^j::Komorebic("move down")
!^k::Komorebic("move up")
!^l::Komorebic("move right")
!^y::Komorebic("promote")

; Stack windows
#]::Komorebic("stack right")
#[::Komorebic("stack left")
#,::Komorebic("stack down")
#+,::Komorebic("stack up")
#.::Komorebic("unstack")
#+.::Komorebic("unstack-all")
#m::Komorebic("cycle-stack next")
#+m::Komorebic("cycle-stack previous")
#^m::Komorebic("toggle-window-container-behaviour")

; Resize
#=::Komorebic("resize-axis horizontal increase")
#-::Komorebic("resize-axis horizontal decrease")
#+=::Komorebic("resize-axis vertical increase")
#+_::Komorebic("resize-axis vertical decrease")

; Manipulate windows
#z::Komorebic("toggle-float")
#f::Komorebic("toggle-monocle")
#\::Komorebic("retile")

; Workspace
#u::Komorebic("cycle-workspace next")
#i::Komorebic("cycle-workspace previous")
#^u::Komorebic("cycle-send-to-workspace next")
#^i::Komorebic("cycle-send-to-workspace previous")
#+/::{
    result := InputBox("Enter workspace ID (0 to close):", "Focus Workspace")
    if (result.Result = "OK" && result.Value != "") {
        if (result.Value = 0)
            Komorebic("close-workspace")
        else
            Komorebic("focus-workspace " (result.Value - 1))
    }
}

; Layout
#;::{
    layouts := ["bsp", "columns", "rows", "vertical-stack", "horizontal-stack", "ultrawide-vertical-stack", "grid", "right-main-vertical-stack"]
    prompt := "Select layout:`n"
    for i, layout in layouts
        prompt .= i ". " layout "`n"
    result := InputBox(prompt, "Change Layout")
    if (result.Result = "OK" && result.Value != "") {
        idx := Integer(result.Value)
        if (idx >= 1 && idx <= layouts.Length)
            Komorebic("change-layout " layouts[idx])
    }
}
#^;::{
    shell := ComObject("WScript.Shell")
    exec := shell.Exec('cmd /c komorebic state | jq -r ".monitors.elements.[].workspaces.elements | map(.layout.Default) | join(^"|^")"')
    layout := Trim(exec.StdOut.ReadAll())
    if (layout != "")
        MsgBox(layout, "Current Layout")
}
