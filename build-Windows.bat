@echo off
REM Build the thesis on Windows. Double-click this file, or run it from a
REM terminal. The finished PDF appears beside this script, named by
REM output-name in config\thesis-config.tex.
REM
REM   build-Windows.bat            build
REM   build-Windows.bat -Clean     empty build\ first, then build
REM
REM This is a shim: the real script is util\build.ps1. Do not edit either.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0util\build.ps1" %*
REM No "pause" here on purpose: it would hang any script or CI job that calls
REM this file, and the result is durable anyway -- the finished PDF is left in
REM this folder.
exit /b %ERRORLEVEL%
