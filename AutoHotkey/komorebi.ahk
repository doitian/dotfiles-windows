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

; Move windows
!^h::Komorebic("move left")
!^j::Komorebic("move down")
!^k::Komorebic("move up")
!^l::Komorebic("move right")

; Stack windows
#]::Komorebic("stack right")
#[::Komorebic("stack left")
#,::Komorebic("stack down")
#.::Komorebic("unstack")
#m::Komorebic("cycle-stack next")
#+m::Komorebic("cycle-stack previous")
#^m::Komorebic("unstack-all")

; Resize
#=::Komorebic("resize-axis horizontal increase")
#-::Komorebic("resize-axis horizontal decrease")
#+=::Komorebic("resize-axis vertical increase")
#+_::Komorebic("resize-axis vertical decrease")

; Manipulate windows
#z::Komorebic("toggle-float")
#f::Komorebic("toggle-monocle")

; Focus workspace by ID
#+/::{
    result := InputBox("Enter workspace ID:", "Focus Workspace")
    if (result.Result = "OK" && result.Value != "")
        Komorebic("focus-workspace " (result.Value - 1))
}