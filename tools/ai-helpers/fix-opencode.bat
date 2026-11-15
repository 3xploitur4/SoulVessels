@echo off
echo Finishing OpenCode setup (downloads its program file)...
call npm install -g --allow-scripts=opencode-ai opencode-ai@latest
call opencode --version
echo.
echo Done. You can close this window.
pause
