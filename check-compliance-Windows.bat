@echo off
REM Check the built thesis on Windows: PDF/UA-2 conformance, text extraction,
REM character encoding, figure alt text, and build-log warnings.
REM Run build-Windows.bat first.
REM
REM Writes docs\compliance-report.txt and, if veraPDF is installed,
REM compliance-report.html beside this file.
REM
REM This is a shim: the real script is util\check-compliance.ps1. Do not edit
REM either.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0util\check-compliance.ps1" %*
REM No "pause" here on purpose: it would hang any script or CI job that calls
REM this file. If the window closes before you can read the summary, the same
REM information is in docs\compliance-report.txt.
exit /b %ERRORLEVEL%
