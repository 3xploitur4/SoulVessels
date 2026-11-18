@echo off
rem Soul Vessels - jump straight to a part of the game to test it.
rem These runs use their own save folder, so your real saves are never touched.
cd /d "%~dp0"
set GODOT=engine\godot\Godot_v4.7.2-stable_win64.exe
echo.
echo   SOUL VESSELS - test launcher
echo   ----------------------------
echo   1  A new game from the very start   (the wisp, Caelan, Zone 1)
echo   2  Zone 2, the Mycelium Forest       (Nyra)
echo   3  Zone 3, the Sunken Palace         (Seris, rune puzzles)
echo   4  Boss: the Weeping Sovereign
echo   5  Zone 4, the Sealed Rift           (Darius under the rubble)
echo   6  Boss: the Guardian Below
echo   7  Boss: the Abyssal Leviathan
echo   8  Ilyr's awakening and the end of Chapter I
echo   9  Combat sandbox                    (all four Vessels, a Soul Altar)
echo.
choice /c 123456789 /n /m "  Pick 1-9: "
set N=%errorlevel%
set ARGS=--save-dir user://playtest_mvp
if %N%==1 set ARGS=%ARGS% --new-game 0
if %N%==2 set ARGS=%ARGS% --room z2_01 --loadout caelan
if %N%==3 set ARGS=%ARGS% --room z3_01 --loadout caelan,nyra
if %N%==4 set ARGS=%ARGS% --room z3_16 --loadout caelan,nyra,seris
if %N%==5 set ARGS=%ARGS% --room z4_01 --loadout caelan,nyra,seris
if %N%==6 set ARGS=%ARGS% --room z4_09 --loadout caelan,seris,darius
if %N%==7 set ARGS=%ARGS% --room z4_12 --loadout caelan,seris,darius
if %N%==8 set ARGS=%ARGS% --room z4_14 --loadout caelan,seris,darius
if %N%==9 set ARGS=%ARGS% --room z4_04 --loadout caelan,nyra,darius
start "" "%GODOT%" --path . -- %ARGS%
