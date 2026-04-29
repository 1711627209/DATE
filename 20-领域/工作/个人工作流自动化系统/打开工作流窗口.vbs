Dim shell, fso, scriptFolder, command
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptFolder = fso.GetParentFolderName(WScript.ScriptFullName)
command = "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptFolder & "\launch-workflow-gui.ps1"""
shell.Run command, 0, False