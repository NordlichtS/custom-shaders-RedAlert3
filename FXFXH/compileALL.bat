@echo off
setlocal

:: Set the path to fxc.exe (assuming it's in the same directory as this script)
set FXC_PATH=fxc.exe

:: Set the output directory (same as the script directory)
set OUTPUT_DIR=.

:: Find and compile all .fx files starting with "object" or "building"
for %%f in (object*.fx building*.fx) do (
    echo Compiling %%f...
    %FXC_PATH% /O2 /T fx_2_0 /Fo %%~nf.fxo %%f
    if errorlevel 1 (
        echo Error compiling %%f
    ) else (
        echo %%f compiled successfully
    )
)

endlocal
echo Compilation process completed.
pause
