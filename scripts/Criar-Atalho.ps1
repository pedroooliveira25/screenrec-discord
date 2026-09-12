# Criar-Atalho.ps1 — gera ScreenRec.lnk com os caminhos DESTA máquina + ícone.
# O .lnk do GitHub nunca funciona em outro PC (caminho absoluto), então cada
# máquina gera o seu rodando este script (ou o Criar-Atalho.bat).
$root = Split-Path -Parent $PSScriptRoot
$ps1 = Join-Path $root "app\ScreenRec.ps1"
$ico = Join-Path $root "assets\app.ico"
$lnkPath = Join-Path $root "ScreenRec.lnk"
$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut($lnkPath)
$lnk.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$lnk.Arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $ps1 + '"'
$lnk.WorkingDirectory = $root
if (Test-Path -LiteralPath $ico) { $lnk.IconLocation = $ico }
$lnk.Save()
Write-Output ("Atalho criado: " + $lnkPath)
