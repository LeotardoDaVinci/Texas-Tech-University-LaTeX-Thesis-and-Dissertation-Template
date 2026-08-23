@echo off
REM Check the built thesis on Windows: PDF/UA-2 conformance, text extraction,
REM character encoding, figure alt text, and build-log warnings.
REM Run build-Windows.bat first.
REM
REM Writes compliance-report.txt and, if veraPDF is installed,
REM compliance-report.html, both in the template root (the folder above).
REM
REM This is a shim: the real script is check-compliance.ps1 beside it. Do not
REM edit either.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check-compliance.ps1" %*
REM No "pause" here on purpose: it would hang any script or CI job that calls
REM this file. If the window closes before you can read the summary, the same
REM information is in compliance-report.txt.
exit /b %ERRORLEVEL%
