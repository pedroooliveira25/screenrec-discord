@echo off
REM Atalho ScreenRec — duplo clique para abrir o app (sem janela preta).
start "" /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0app\ScreenRec.ps1"
