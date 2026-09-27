#SingleInstance Force

AgentStatus.Show()

class AgentStatus {
  static g := 0, txt := 0
  static interval := 2000
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
      this.g.Show("x" A_ScreenWidth - w * 2 " y" A_ScreenHeight - h * 2 " NoActivate")
    }
    this.Poll()
  }

  static Poll() {
    if !this.g
      return
    status := "idle", n := 0
    try {
      tmp := A_Temp "\agent-status.json"
      RunWait A_ComSpec ' /c agent-berth stats --json > "' tmp '"', , "Hide"
      json := FileRead(tmp)
      doc := ComObject("htmlfile")
      doc.write("<meta http-equiv='X-UA-Compatible' content='IE=edge'>")
      js := "(function(d){var c=[0,0,0,0];for(var i=0;i<d.length;i++){c[0]+=d[i].waiting;c[1]+=d[i].running;c[2]+=d[i].idle;c[3]+=d[i].done;}return c.join(',');})(" json ")"
      counts := StrSplit(doc.parentWindow.eval(js), ",")
      for i, s in ["waiting", "running", "idle", "done"]
        if Integer(counts[i]) {
          status := s, n := counts[i]
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
    if status != "error"
      SetTimer this.pollTimer, -this.interval
  }
}
