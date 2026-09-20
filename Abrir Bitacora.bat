@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Bitacora Territorial - Lab-S

echo.
echo   ===========================================
echo    BITACORA TERRITORIAL 1.0.0  -  Lab-S
echo    Alcaldia Municipal de Simiti, Bolivar
echo   ===========================================
echo.
echo    En este computador:
echo      http://localhost:5199/index.html
echo.
echo    En el celular (misma red Wi-Fi):
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /c:"IPv4"') do (
  for /f "tokens=1" %%j in ("%%i") do echo      http://%%j:5199/index.html
)
echo.
echo    NO CIERRES ESTA VENTANA mientras uses la app.
echo    Para cerrar la app: cierra esta ventana.
echo.

start "" cmd /c "timeout /t 2 >nul & start """" http://localhost:5199/index.html"

python -m http.server 5199 --bind 0.0.0.0 >nul 2>&1

echo.
echo    No se pudo iniciar. Revisa que Python este instalado
echo    o que el puerto 5199 no este ocupado.
pause
