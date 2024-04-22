TraySetIcon "DDORes.dll", 32

; Holding Tab as a Mouse layer.

;START OF CONFIG SECTION

#SingleInstance
A_MaxHotkeysPerInterval := 500

; Using the keyboard hook to implement the Numpad hotkeys prevents
; them from interfering with the generation of ANSI characters such
; as à.  This is because AutoHotkey generates such characters
; by holding down ALT and sending a series of Numpad keystrokes.
; Hook hotkeys are smart enough to ignore such keystrokes.
#UseHook

g_MouseSpeed := 5
g_MouseAccelerationSpeed := 100
g_MouseMaxSpeed := 50

;Mouse wheel speed is also set on Control Panel. As that
;will affect the normal mouse behavior, the real speed of
;these three below are times the normal mouse wheel speed.
g_MouseWheelSpeed := 1
g_MouseWheelAccelerationSpeed := 1
g_MouseWheelMaxSpeed := 5

;END OF CONFIG SECTION

;This is needed or key presses would faulty send their natural
;actions. Like NumpadDiv would send sometimes "/" to the
;screen.
InstallKeybdHook

g_Temp := 0
g_Temp2 := 0

g_MouseCurrentAccelerationSpeed := 0
g_MouseCurrentSpeed := g_MouseSpeed
g_MouseCurrentSpeedToDirection := 0
g_MouseCurrentSpeedToSide := 0

g_MouseWheelCurrentAccelerationSpeed := 0
g_MouseWheelCurrentSpeed := g_MouseSpeed
g_MouseWheelAccelerationSpeedReal := 0
g_MouseWheelMaxSpeedReal := 0
g_MouseWheelSpeedReal := 0

g_Button := 0

SetKeyDelay -1
SetMouseDelay -1

*Tab::Send "{Blind}{Tab}"
Tab & Space::LButton
Tab & RAlt::RButton
Tab & M::MButton

Hotkey "Tab & y", ButtonWheelAcceleration
Hotkey "Tab & h", ButtonWheelAcceleration
Hotkey "Tab & u", ButtonWheelAcceleration
Hotkey "Tab & o", ButtonWheelAcceleration

Hotkey "Tab & i", ButtonAcceleration
Hotkey "Tab & k", ButtonAcceleration
Hotkey "Tab & j", ButtonAcceleration
Hotkey "Tab & l", ButtonAcceleration

ButtonAcceleration(ThisHotkey)
{
    global
    if g_Button != 0
    {
        if !InStr(ThisHotkey, g_Button)
        {
            g_MouseCurrentAccelerationSpeed := 0
            g_MouseCurrentSpeed := g_MouseSpeed
        }
    }
    g_Button := StrReplace(ThisHotkey, "Tab & ")
    ButtonAccelerationStart
}

ButtonAccelerationStart()
{
    global

    if g_MouseAccelerationSpeed >= 1
    {
        if g_MouseMaxSpeed > g_MouseCurrentSpeed
        {
            g_Temp := 0.001
            g_Temp *= g_MouseAccelerationSpeed
            g_MouseCurrentAccelerationSpeed += g_Temp
            g_MouseCurrentSpeed += g_MouseCurrentAccelerationSpeed
        }
    }

    if g_Button = "i"
    {
        MouseMove 0, -2 * g_MouseCurrentSpeed, 0, "R"
    }
    else if g_Button = "k"
    {
        MouseMove 0, 2 * g_MouseCurrentSpeed, 0, "R"
    }
    else if g_Button = "j"
    {
        MouseMove -2 * g_MouseCurrentSpeed, 0, 0, "R"
    }
    else if g_Button = "l"
    {
        MouseMove 2 * g_MouseCurrentSpeed, 0, 0, "R"
    }

    SetTimer ButtonAccelerationEnd, 10
}

ButtonAccelerationEnd()
{
    global

    if GetKeyState(g_Button, "P")
    {
        ButtonAccelerationStart
        return
    }

    SetTimer , 0
    g_MouseCurrentAccelerationSpeed := 0
    g_MouseCurrentSpeed := g_MouseSpeed
    g_Button := 0
}

ButtonWheelAcceleration(ThisHotkey)
{
    global
    if g_Button != 0
    {
        if g_Button != ThisHotkey
        {
            g_MouseWheelCurrentAccelerationSpeed := 0
            g_MouseWheelCurrentSpeed := g_MouseWheelSpeed
        }
    }
    g_Button := StrReplace(ThisHotkey, "Tab & ")
    ButtonWheelAccelerationStart
}

ButtonWheelAccelerationStart()
{
    global

    if g_MouseWheelAccelerationSpeed >= 1
    {
        if g_MouseWheelMaxSpeed > g_MouseWheelCurrentSpeed
        {
            g_Temp := 0.001
            g_Temp *= g_MouseWheelAccelerationSpeed
            g_MouseWheelCurrentAccelerationSpeed += g_Temp
            g_MouseWheelCurrentSpeed += g_MouseWheelCurrentAccelerationSpeed
        }
    }

    if g_Button = "y"
        MouseClick "WheelUp",,, g_MouseWheelCurrentSpeed, 0, "D"
    else if g_Button = "h"
        MouseClick "WheelDown",,, g_MouseWheelCurrentSpeed, 0, "D"
    else if g_Button = "u"
        MouseClick "WheelLeft",,, g_MouseWheelCurrentSpeed, 0, "D"
    else if g_Button = "o"
        MouseClick "WheelRight",,, g_MouseWheelCurrentSpeed, 0, "D"

    SetTimer ButtonWheelAccelerationEnd, 100
}

ButtonWheelAccelerationEnd()
{
    global

    if GetKeyState(g_Button, "P")
    {
        ButtonWheelAccelerationStart
        return
    }

    g_MouseWheelCurrentAccelerationSpeed := 0
    g_MouseWheelCurrentSpeed := g_MouseWheelSpeed
    g_Button := 0
}
