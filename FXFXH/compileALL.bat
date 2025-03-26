@echo off
setlocal

:: Define the output directory
set OUTPUT_DIR=FXO

:: Check if the FXO directory exists; if not, create it
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%"
)

:: Compile all .fx files starting with "object" or "building"
for %%f in (object*.fx building*.fx) do (
    echo Compiling %%f...
    fxc.exe /O2 /T fx_2_0 /Fo "%OUTPUT_DIR%\%%~nf.fxo" "%%f"
    if errorlevel 1 (
        echo Error compiling %%f
    ) else (
        echo %%f compiled successfully
    )
)

endlocal
echo Compilation process completed.
pause
