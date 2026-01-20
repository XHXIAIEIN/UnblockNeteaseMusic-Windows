Set shell = CreateObject("Shell.Application")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
ps1 = scriptDir & "\res\UnblockNeteaseMusic.ps1"
shell.ShellExecute "powershell", "-ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1 & """", "", "runas", 0
