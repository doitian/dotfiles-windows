#Requires AutoHotkey v2.0
#SingleInstance Force
A_MaxHotkeysPerInterval := 200
TraySetIcon "joy.cpl", 1

; Gamepad-to-Keyboard/Mouse Mapper (XInput)
;
; Left Stick  = Mouse move    | Press = Left Click
; Right Stick = Scroll        | Press = Right Click
; D-Pad       = Arrow keys
; LT = Shift, LB = Ctrl, RB = Alt
; RT + A = Enter, RT + B = Backspace, RT + X = PageDown, RT + Y = PageUp
; RT + LS = Back, RT + RS = Forward
; A = Space, B = Esc, X = [, Y = ]
; View (hold) = precise mouse, Menu = toggle left click hold

; ===== Tuning =====
MouseSpeed       := 60
PreciseSpeed     := 20
ScrollSpeed      := 0.3
StickCurve       := 3      ; response curve exponent (2=quadratic, 3=cubic, 4=aggressive)
StickDeadZone    := 7850   ; Microsoft recommended: 7849 left, 8689 right
TriggerThreshold := 30     ; Microsoft recommended: 30 (out of 255)

; ===== XInput button flags =====
BTN_DPAD_UP    := 0x0001, BTN_DPAD_DOWN := 0x0002
BTN_DPAD_LEFT  := 0x0004, BTN_DPAD_RIGHT := 0x0008
BTN_MENU       := 0x0010, BTN_VIEW := 0x0020
BTN_LS         := 0x0040, BTN_RS := 0x0080
BTN_LB         := 0x0100, BTN_RB := 0x0200
BTN_A          := 0x1000, BTN_B := 0x2000
BTN_X          := 0x4000, BTN_Y := 0x8000

; ===== State =====
xinState     := Buffer(16, 0)
prevButtons  := 0
prevLT       := 0
lClickLocked := 0
preciseMode  := 0
viewHeldT    := 0
ViewTapMax   := 20   ; max ticks to count as tap (20 * 10ms = 200ms)
scrollAccY   := 0.0
scrollAccX   := 0.0

; Button repeat: ticks held (0 = not held)
dpadUpT := 0, dpadDownT := 0, dpadLeftT := 0, dpadRightT := 0
btnAT := 0, btnBT := 0, btnXT := 0, btnYT := 0
RepeatDelay := 20   ; ticks before repeat starts (20 * 10ms = 200ms)
RepeatRate  := 2    ; ticks between repeats      (2  * 10ms = 20ms)

SetTimer(Poll, 10)

Poll() {
    global

    if DllCall("xinput1_4\XInputGetState", "UInt", 0, "Ptr", xinState, "UInt") != 0
        return

    buttons  := NumGet(xinState, 4, "UShort")
    lTrigger := NumGet(xinState, 6, "UChar")
    rTrigger := NumGet(xinState, 7, "UChar")
    thumbLX  := NumGet(xinState, 8, "Short")
    thumbLY  := NumGet(xinState, 10, "Short")
    thumbRX  := NumGet(xinState, 12, "Short")
    thumbRY  := NumGet(xinState, 14, "Short")

    ; --- Left Stick -> Mouse ---
    speed := preciseMode ? PreciseSpeed : MouseSpeed
    mx := 0, my := 0
    if Abs(thumbLX) > StickDeadZone {
        n := thumbLX / 32767
        mx := Round(Abs(n) ** StickCurve * (n > 0 ? 1 : -1) * speed)
    }
    if Abs(thumbLY) > StickDeadZone {
        n := thumbLY / 32767
        my := Round(Abs(n) ** StickCurve * (n > 0 ? -1 : 1) * speed)
    }
    if mx != 0 || my != 0
        MouseMove mx, my, 0, "R"

    ; --- Right Stick -> Scroll (accumulator for sub-line precision) ---
    if Abs(thumbRY) > StickDeadZone {
        n := thumbRY / 32767
        scrollAccY += Abs(n) ** StickCurve * (n > 0 ? 1 : -1) * ScrollSpeed
    } else {
        scrollAccY := 0.0
    }
    if Abs(scrollAccY) >= 1 {
        lines := Integer(scrollAccY)
        if lines > 0
            MouseClick "WheelUp",,, lines
        else
            MouseClick "WheelDown",,, Abs(lines)
        scrollAccY -= lines
    }

    if Abs(thumbRX) > StickDeadZone {
        n := thumbRX / 32767
        scrollAccX += Abs(n) ** StickCurve * (n > 0 ? 1 : -1) * ScrollSpeed
    } else {
        scrollAccX := 0.0
    }
    if Abs(scrollAccX) >= 1 {
        cols := Integer(scrollAccX)
        if cols > 0
            MouseClick "WheelRight",,, cols
        else
            MouseClick "WheelLeft",,, Abs(cols)
        scrollAccX -= cols
    }

    ; --- Button edge detection ---
    pressed  := buttons & ~prevButtons
    released := ~buttons & prevButtons
    ; XYAB keys with repeat, RT modifies
    rt := (rTrigger > TriggerThreshold)
    btnAT := BtnRepeat(buttons & BTN_A, btnAT, rt ? "{Enter}" : "{Space}")
    btnBT := BtnRepeat(buttons & BTN_B, btnBT, rt ? "{Backspace}" : "{Escape}")
    btnXT := BtnRepeat(buttons & BTN_X, btnXT, rt ? "{PgDn}" : "[")
    btnYT := BtnRepeat(buttons & BTN_Y, btnYT, rt ? "{PgUp}" : "]")
    if pressed & BTN_VIEW {
        preciseMode := 1
        viewHeldT := 1
    } else if buttons & BTN_VIEW {
        viewHeldT++
    }
    if released & BTN_VIEW {
        preciseMode := 0
        if viewHeldT <= ViewTapMax
            Click
        viewHeldT := 0
    }
    if pressed & BTN_MENU {
        lClickLocked := !lClickLocked
        Click lClickLocked ? "Down" : "Up"
    }

    ; modifiers (hold / release)
    if pressed & BTN_LB
        Send "{LControl Down}"
    if released & BTN_LB
        Send "{LControl Up}"

    if pressed & BTN_RB
        Send "{LAlt Down}"
    if released & BTN_RB
        Send "{LAlt Up}"

    ; stick clicks -> mouse buttons, RT modifies to Back/Forward
    if pressed & BTN_LS {
        if rt {
            Send "{Browser_Back}"
        } else {
            if lClickLocked {
                lClickLocked := 0
                Click "Up"
            }
            Click "Down"
        }
    }
    if released & BTN_LS && !rt
        Click "Up"

    if pressed & BTN_RS {
        if rt {
            Send "{Browser_Forward}"
        } else {
            if lClickLocked {
                lClickLocked := 0
                Click "Up"
            }
            Click "Down Right"
        }
    }
    if released & BTN_RS && !rt
        Click "Up Right"

    ; d-pad -> arrow keys (with key repeat)
    dpadUpT    := BtnRepeat(buttons & BTN_DPAD_UP,    dpadUpT,    "{Up}")
    dpadDownT  := BtnRepeat(buttons & BTN_DPAD_DOWN,  dpadDownT,  "{Down}")
    dpadLeftT  := BtnRepeat(buttons & BTN_DPAD_LEFT,  dpadLeftT,  "{Left}")
    dpadRightT := BtnRepeat(buttons & BTN_DPAD_RIGHT, dpadRightT, "{Right}")

    prevButtons := buttons

    ; --- Triggers ---
    newLT := (lTrigger > TriggerThreshold)
    if newLT && !prevLT
        Send "{LShift Down}"
    else if !newLT && prevLT
        Send "{LShift Up}"
    prevLT := newLT
}

BtnRepeat(held, ticks, key) {
    global RepeatDelay, RepeatRate
    if !held
        return 0
    ticks++
    if ticks = 1 || (ticks > RepeatDelay && Mod(ticks - RepeatDelay, RepeatRate) = 0)
        Send key
    return ticks
}
