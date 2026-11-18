@echo off
rem Soul Vessels - play the whole game from the title screen (keyboard or gamepad).
rem Saves go to your normal save slots. See PLAYTEST.md for the controls.
cd /d "%~dp0"
start "" "engine\godot\Godot_v4.7.2-stable_win64.exe" --path . 
