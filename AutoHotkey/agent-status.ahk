#Requires AutoHotkey v2.0
#SingleInstance Force

AgentStatus.Show()

class AgentStatus {
  static g := 0, txt := 0
  static interval := 2000
  static errorInterval := 10000
  static pollTimer := () => AgentStatus.Poll()
  static hook := OnMessage(0x201, (w, l, m, hwnd) =>
    (AgentStatus.g && GuiFromHwnd(hwnd) = AgentStatus.g) &&
    PostMessage(0xA1, 2, , , "ahk_id " AgentStatus.g.Hwnd))
  static styles := Map(
    "waiting", {icon: "⏳", color: "FFD700"},
    "running", {icon: "▶", color: "00C853"},
    "idle",    {icon: "💤", color: "AAAAAA"},
    "done",    {icon: "✔", color: "40C4FF"},
    "error",   {icon: "⚠", color: "FF5252"}
  )

  static Show() {
    if !this.g {
      this.g := Gui("+AlwaysOnTop -Caption +ToolWindow", "Agent Status")
      this.g.BackColor := "1E1E1E"
      this.g.MarginX := 8, this.g.MarginY := 5
      this.g.SetFont("s10 cWhite", "Segoe UI")
      this.txt := this.g.Add("Text", "w45 Center")
      this.g.OnEvent("ContextMenu", (*) => ExitApp())
      this.g.Show("Hide")
      this.g.GetPos(, , &w, &h)
      this.g.Show("x1 y" A_ScreenHeight - h * 2 " NoActivate")
    }
    this.Poll()
  }

  static Poll() {
    if !this.g
      return
    status := "idle", n := 0
    try {
      tmp := A_Temp "\agent-status.json"
      if RunWait(A_ComSpec ' /c agent-berth stats --json > "' tmp '"', , "Hide")
        throw Error("agent-berth failed")
      json := FileRead(tmp)
      for s in ["waiting", "running", "idle", "done"]
        if count := this.SumField(json, s) {
          status := s, n := count
          break
        }
    } catch {
      status := "error"
    }
    if this.g {
      style := this.styles[status]
      this.txt.Opt("c" style.color)
      this.txt.Value := style.icon " " n
    }
    SetTimer this.pollTimer, -(status = "error" ? this.errorInterval : this.interval)
  }

  static SumField(json, key) {
    total := 0, pos := 1
    while pos := RegExMatch(json, '"' key '"\s*:\s*(\d+)', &m, pos) {
      total += m[1]
      pos += m.Len
    }
    return total
  }
}
