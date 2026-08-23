<#
    build.ps1 -- compile the thesis with LuaLaTeX and biber.  Windows.

    You do not run this directly: double-click build-Windows.bat in the folder
    above, which calls this script.  From PowerShell you can also run
        ..\build-Windows.bat -Clean

    The finished PDF is copied into the template root under the name set by
    output-name in config/thesis-config.tex; build\ holds the working files.
    -Clean empties build\ but never touches the delivered PDF.
    macOS / Linux: use build-Mac-Linux.sh instead.  Do not edit.
#>
[CmdletBinding()]
param([switch]$Clean)

$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$build   = Join-Path $root 'build'

# NOTE: the jobname is deliberately NOT the name of the delivered PDF.
# On a fatal error lualatex deletes <jobname>.pdf relative to the CURRENT
# DIRECTORY, ignoring -output-directory. Since lualatex is run from the
# template root (so \input paths resolve), a jobname matching the delivered
# file would make a failed build silently destroy it. Keeping the two names
# distinct removes the hazard by construction rather than by cleanup.
$jobname = 'thesis-build'

# The delivered file name comes from config/thesis-config.tex, which is the
# single place it is written down. Dot-source-free, tolerant parse: the first
# uncommented output-name = {...} wins.
. (Join-Path $PSScriptRoot 'output-name.ps1')
$deliver = Join-Path $root ((Get-ThesisOutputName -Root $root -JobName $jobname) + '.pdf')

Set-Location $root

if ($Clean -and (Test-Path $build)) {
    Remove-Item -Recurse -Force $build
    Write-Host "Cleaned $build"
    # OneDrive can hold the just-deleted directory open for a moment, which
    # makes the first lualatex pass fail with a non-LaTeX exit code.
    Start-Sleep -Milliseconds 500
}
if (-not (Test-Path $build)) { New-Item -ItemType Directory -Path $build | Out-Null }

$texArgs = @(
    '-interaction=nonstopmode',
    '-halt-on-error',
    '-file-line-error',
    "-output-directory=$build",
    "-jobname=$jobname",
    'main.tex'
)

function Invoke-Pass([int]$n) {
    Write-Host "== lualatex pass $n =="
    & lualatex @texArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "lualatex failed on pass $n; see $build\$jobname.log"
        exit $LASTEXITCODE
    }
}

Invoke-Pass 1

Write-Host "== biber =="
& biber --input-directory $build --output-directory $build $jobname
if ($LASTEXITCODE -ne 0) {
    Write-Host "biber failed; see $build\$jobname.blg"
    exit $LASTEXITCODE
}

Invoke-Pass 2
Invoke-Pass 3
# A fourth pass, because pass 2 is the first one that knows how many appendices
# the document has and so is the first that can un-letter a lone one. That
# changes the table of contents entry, which shifts every structure number
# after it; pass 3 lays the shifted numbers down and pass 4 is the one that
# reads them back consistently. Cheaper than asking anyone to notice.
Invoke-Pass 4

# Put the finished PDF where you can find it: in the template root, not buried
# in build\. This copy is the one you submit or send to your committee. It is
# written only after all passes succeed, so a failed build leaves the previous
# good copy exactly as it was. -Clean does not delete it either: it is a
# deliverable, not a build artefact, and it is what a fresh clone ships.
Copy-Item (Join-Path $build "$jobname.pdf") $deliver -Force

Write-Host "OK: $deliver  (working files in $build\)"
exit 0
