@echo off
REM Gera o atalho ScreenRec.lnk com os caminhos DESTA maquina + icone.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Criar-Atalho.ps1"
pause
