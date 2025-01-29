@echo off
SET GAMEDIR="%cd%"
xcopy "%ULTRAENGINE%\Templates\Common\Shaders\" "%GAMEDIR%\Shaders\" /i /d /y /s
xcopy "%ULTRAENGINE%\Templates\Common\Effects\" "%GAMEDIR%\Effects\" /i /d /y /s
pause