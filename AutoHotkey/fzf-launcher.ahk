class FzfLauncher {
  static g := 0
  static edit := 0
  static lb := 0
  static items := []
  static shown := []
  static onSelect := 0
  static boundFilter := 0

  static Windows() {
    items := []
    self := this.g ? this.g.Hwnd : 0
    for hwnd in WinGetList() {
      if (hwnd = self || !DllCall("IsWindowVisible", "ptr", hwnd, "int"))
        continue
      try title := this.OneLine(WinGetTitle(hwnd))
      catch
        continue
      if title = ""
        continue
      try proc := RegExReplace(WinGetProcessName(hwnd), "i)\.exe$")
      catch
        continue
      items.Push({text: proc "  " title, hwnd: hwnd})
    }
    this.Show(items, (item) => this.Activate(item.hwnd), "Windows")
  }

  static Passwords() {
    ToolTip("Loading passwords")
    try text := this.Gopass("list -f")
    catch as e {
      ToolTip()
      this.Show([{text: e.Message}], (*) => 0, "Passwords")
      return
    }
    ToolTip()
    items := []
    for line in StrSplit(RTrim(text, "`r`n"), "`n", "`r")
      if line != ""
        items.Push({text: line})
    this.Show(items, (item) => this.CopySecret(item.text), "Passwords")
  }

  static CopySecret(name) {
    try {
      this.Gopass("show -c -- " this.QuoteArg(name))
      ToolTip("Copied")
    } catch as e {
      ToolTip(e.Message)
    }
    SetTimer(ToolTip, -1200)
  }

  static Show(items, onSelect, cue) {
    this.Close()
    if !this.boundFilter
      this.boundFilter := this.ApplyFilter.Bind(this)
    this.items := items
    this.onSelect := onSelect
    light := 1
    try light := RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
    this.g := Gui("+AlwaysOnTop -Caption +ToolWindow +Border", "fzf")
    this.g.OnEvent("Escape", (*) => this.Close())
    this.g.OnEvent("Close", (*) => this.Close())
    this.g.MarginX := 12
    this.g.MarginY := 12
    this.g.SetFont("s11", "Segoe UI")
    editOpt := "w600"
    listOpt := "w600 r10 y+8"
    if !light {
      this.g.BackColor := "1f1f1f"
      editOpt .= " Background1f1f1f cE8E8E8"
      listOpt .= " Background1f1f1f cE8E8E8"
    }
    this.edit := this.g.Add("Edit", editOpt)
    this.lb := this.g.Add("ListBox", listOpt)
    this.edit.OnEvent("Change", (*) => this.ScheduleFilter())
    this.lb.OnEvent("DoubleClick", (*) => this.Accept())
    SendMessage(0x1501, 1, StrPtr(cue), , "ahk_id " this.edit.Hwnd)
    if !light {
      DllCall("uxtheme\SetWindowTheme", "ptr", this.edit.Hwnd, "str", "DarkMode_CFD", "ptr", 0)
      DllCall("uxtheme\SetWindowTheme", "ptr", this.lb.Hwnd, "str", "DarkMode_Explorer", "ptr", 0)
    }
    this.ApplyFilter()
    this.g.Show("Hide")
    this.Place()
    pref := 2
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", this.g.Hwnd, "int", 33, "int*", &pref, "int", 4)
    this.edit.Focus()
  }

  static Close() {
    if this.boundFilter
      SetTimer(this.boundFilter, 0)
    if !this.g
      return
    g := this.g
    this.g := this.edit := this.lb := 0
    this.items := this.shown := []
    this.onSelect := 0
    g.Destroy()
  }

  static ScheduleFilter(*) => SetTimer(this.boundFilter, -40)

  static ApplyFilter(*) {
    if !this.g
      return
    q := Trim(this.edit.Text)
    this.shown := []
    names := []
    try {
      if q = "" {
        for item in this.items {
          this.shown.Push(item)
          names.Push(item.text)
        }
      } else {
        lines := []
        for i, item in this.items
          lines.Push(i "`t" item.text)
        for raw in StrSplit(RTrim(this.Rank(lines, q), "`r`n"), "`n", "`r") {
          if raw = ""
            continue
          item := this.items[Integer(StrSplit(raw, "`t", , 2)[1])]
          this.shown.Push(item)
          names.Push(item.text)
        }
      }
    } catch as e {
      this.shown := []
      names := [e.Message]
    }
    this.lb.Delete()
    if names.Length
      this.lb.Add(names)
    if this.shown.Length
      this.lb.Choose(1)
  }

  static Move(d) {
    n := this.shown.Length
    if !n
      return
    i := this.lb.Value
    this.lb.Choose(i ? Min(Max(i + d, 1), n) : (d > 0 ? 1 : n))
  }

  static Accept() {
    if !this.shown.Length
      return
    item := this.shown[this.lb.Value || 1]
    cb := this.onSelect
    this.Close()
    cb(item)
  }

  static Activate(hwnd) {
    if !WinExist(hwnd)
      return
    try {
      if WinGetMinMax(hwnd) = -1
        WinRestore hwnd
      WinActivate hwnd
    }
  }

  static Active() => this.g && WinExist(this.g.Hwnd)

  static Rank(lines, query) {
    inPath := A_Temp "\ahk-fzf.in"
    outPath := A_Temp "\ahk-fzf.out"
    body := ""
    for line in lines
      body .= line "`n"
    f := FileOpen(inPath, "w", "UTF-8-RAW")
    f.Write(body)
    f.Close()
    cmd := this.QuoteArg(this.FzfPath()) " --filter=" this.QuoteArg(query)
      . " --delimiter=" this.QuoteArg("`t") " --with-nth=2"
    try {
      code := this.RunIo(cmd, inPath, outPath, 5000)
      text := FileExist(outPath) ? FileRead(outPath, "UTF-8-RAW") : ""
      if (code = 2)
        throw Error("fzf failed")
      return text
    } finally {
      this.Cleanup(inPath)
      this.Cleanup(outPath)
    }
  }

  static FzfPath() {
    p := EnvGet("USERPROFILE") "\scoop\apps\fzf\current\fzf.exe"
    return FileExist(p) ? p : "fzf.exe"
  }

  static GopassPath() {
    p := EnvGet("USERPROFILE") "\scoop\apps\gopass\current\gopass.exe"
    return FileExist(p) ? p : "gopass.exe"
  }

  static Gopass(args) {
    gpg := EnvGet("USERPROFILE") "\scoop\apps\gpg4win\current\GnuPG\bin"
    userPath := ""
    try userPath := RegRead("HKCU\Environment", "Path")
    old := EnvGet("Path")
    EnvSet("Path", gpg ";" userPath ";" old)
    try return this.Capture(this.QuoteArg(this.GopassPath()) " " args, 0xFFFFFFFF)
    finally EnvSet("Path", old)
  }

  static Capture(cmd, timeout) {
    inPath := A_Temp "\ahk-cap.in"
    outPath := A_Temp "\ahk-cap.out"
    errPath := A_Temp "\ahk-cap.err"
    f := FileOpen(inPath, "w", "UTF-8-RAW")
    f.Close()
    try {
      code := this.RunIo(cmd, inPath, outPath, timeout, errPath)
      text := FileExist(outPath) ? FileRead(outPath, "UTF-8-RAW") : ""
      err := FileExist(errPath) ? Trim(FileRead(errPath, "UTF-8-RAW"), "`r`n") : ""
      if (code != 0)
        throw Error(err != "" ? err : "command failed (" code ")")
      return text
    } finally {
      this.Cleanup(inPath)
      this.Cleanup(outPath)
      this.Cleanup(errPath)
    }
  }

  static RunIo(cmd, inPath, outPath, timeout, errPath := "") {
    sa := Buffer(A_PtrSize * 3, 0)
    NumPut("uint", sa.Size, sa)
    NumPut("int", 1, sa, A_PtrSize * 2)
    hIn := DllCall("CreateFileW", "str", inPath, "uint", 0x80000000, "uint", 1, "ptr", sa, "uint", 3, "uint", 0x80, "ptr", 0, "ptr")
    hOut := DllCall("CreateFileW", "str", outPath, "uint", 0x40000000, "uint", 1, "ptr", sa, "uint", 2, "uint", 0x80, "ptr", 0, "ptr")
    hErr := errPath = ""
      ? DllCall("CreateFileW", "str", "NUL", "uint", 0x40000000, "uint", 1, "ptr", sa, "uint", 3, "uint", 0x80, "ptr", 0, "ptr")
      : DllCall("CreateFileW", "str", errPath, "uint", 0x40000000, "uint", 1, "ptr", sa, "uint", 2, "uint", 0x80, "ptr", 0, "ptr")
    if (hIn = -1 || !hIn || hOut = -1 || !hOut)
      throw OSError(A_LastError, "CreateFile")
    siSize := A_PtrSize = 8 ? 104 : 68
    si := Buffer(siSize, 0)
    NumPut("uint", siSize, si)
    NumPut("uint", 0x100, si, A_PtrSize = 8 ? 60 : 44)
    NumPut("ptr", hIn, si, A_PtrSize = 8 ? 80 : 56)
    NumPut("ptr", hOut, si, A_PtrSize = 8 ? 88 : 60)
    NumPut("ptr", hErr = -1 ? hOut : hErr, si, A_PtrSize = 8 ? 96 : 64)
    pi := Buffer(A_PtrSize * 2 + 8, 0)
    cmdBuf := Buffer(StrPut(cmd, "UTF-16") * 2, 0)
    StrPut(cmd, cmdBuf, "UTF-16")
    ok := DllCall("CreateProcessW", "ptr", 0, "ptr", cmdBuf, "ptr", 0, "ptr", 0, "int", 1
      , "uint", 0x08000000, "ptr", 0, "ptr", 0, "ptr", si, "ptr", pi)
    err := A_LastError
    DllCall("CloseHandle", "ptr", hIn)
    DllCall("CloseHandle", "ptr", hOut)
    if (hErr != -1)
      DllCall("CloseHandle", "ptr", hErr)
    if !ok
      throw OSError(err, "CreateProcess")
    hProc := NumGet(pi, 0, "ptr")
    hThread := NumGet(pi, A_PtrSize, "ptr")
    DllCall("WaitForSingleObject", "ptr", hProc, "uint", timeout)
    exitCode := 0
    DllCall("GetExitCodeProcess", "ptr", hProc, "uint*", &exitCode)
    DllCall("CloseHandle", "ptr", hProc)
    DllCall("CloseHandle", "ptr", hThread)
    return exitCode
  }

  static QuoteArg(arg) {
    if (arg != "" && !RegExMatch(arg, "[ \t`"`r`n]"))
      return arg
    out := '"'
    bs := 0
    loop parse arg {
      if (A_LoopField = "\") {
        bs++
        continue
      }
      if (A_LoopField = '"') {
        loop (bs * 2 + 1)
          out .= "\"
        out .= '"'
      } else {
        loop bs
          out .= "\"
        out .= A_LoopField
      }
      bs := 0
    }
    loop (bs * 2)
      out .= "\"
    return out '"'
  }

  static OneLine(s) => Trim(StrReplace(StrReplace(StrReplace(s, "`t", " "), "`r", " "), "`n", " "))

  static Cleanup(path) {
    try {
      if FileExist(path)
        FileDelete(path)
    }
  }

  static Place() {
    this.g.GetPos(, , &w, &h)
    saved := A_CoordModeMouse
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    CoordMode("Mouse", saved)
    mon := 1
    loop MonitorGetCount() {
      MonitorGet(A_Index, &l, &t, &r, &b)
      if (mx >= l && mx < r && my >= t && my < b) {
        mon := A_Index
        break
      }
    }
    MonitorGetWorkArea(mon, &l, &t, &r, &b)
    x := l + (r - l - w) // 2
    y := t + Round((b - t) * 0.18)
    this.g.Show("x" x " y" y)
  }
}

#HotIf FzfLauncher.Active()
Enter::FzfLauncher.Accept()
NumpadEnter::FzfLauncher.Accept()
Esc::FzfLauncher.Close()
Down::FzfLauncher.Move(1)
Up::FzfLauncher.Move(-1)
^n::FzfLauncher.Move(1)
^p::FzfLauncher.Move(-1)
^j::FzfLauncher.Move(1)
^k::FzfLauncher.Move(-1)
#HotIf
