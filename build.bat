@echo off
REM Builds dji_rcn1_bridge.exe next to this script.
REM Requires: pip install pyinstaller pyserial vgamepad
where pyinstaller >nul 2>nul
if errorlevel 1 (
    echo PyInstaller not found. Installing...
    python -m pip install pyinstaller
)
pyinstaller --noconfirm --onefile --name dji_rcn1_bridge ^
    --collect-all vgamepad ^
    main.py
echo.
echo Build done. The .exe is in dist\dji_rcn1_bridge.exe
echo Copy config.json next to the .exe before running.
pause
