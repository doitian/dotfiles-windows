Set objShell = CreateObject("Wscript.Shell")
Set args = WScript.Arguments

If args.Count = 0 Then
    WScript.Quit 0
End If

' Join all arguments into one command line
cmd = ""
For i = 0 To args.Count - 1
    If i > 0 Then cmd = cmd & " "
    cmd = cmd & args(i)
Next

' Run PowerShell fully hidden
objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command " & _
             """" & cmd & """", 0, False
