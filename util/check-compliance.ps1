<#
    check-compliance.ps1 -- accessibility and formatting checks on the built
    thesis.  Windows.  Run build-Windows.bat first.

    You do not run this directly: double-click check-compliance-Windows.bat
    beside this file, which calls this script.

    Writes compliance-report.txt (all checks) and, when veraPDF is
    installed, compliance-report.html, both in the template root.  The HTML
    one is veraPDF's own report, openable in a browser.  Both are
    overwritten each run.
    macOS / Linux: use check-compliance-Mac-Linux.sh instead.  Do not edit.
#>
[CmdletBinding()]
param([ValidateSet('ua2','ua1')][string]$Flavour = 'ua2')

$root    = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$build   = Join-Path $root 'build'
$jobname = 'thesis-build'
$pdf     = Join-Path $build "$jobname.pdf"
$log     = Join-Path $build "$jobname.log"
$fail    = 0
$lines   = @()

. (Join-Path $PSScriptRoot 'output-name.ps1')
$deliver = Join-Path $root ((Get-ThesisOutputName -Root $root -JobName $jobname) + '.pdf')

function Add-Result([string]$status, [string]$check, [string]$detail) {
    $script:lines += ("[{0}] {1}" -f $status.PadRight(4), $check)
    if ($detail) { $script:lines += ("       " + $detail) }
    if ($status -eq 'FAIL') { $script:fail = 1 }
}

Set-Location $root   # the second build below resolves \input paths from here

if (-not (Test-Path $pdf)) {
    Write-Host "No $pdf -- run build-Windows.bat first."
    exit 1
}
$lines += "Texas Tech University thesis template -- compliance report"
$lines += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$lines += "Checked:   $pdf"
$lines += "Delivered: $deliver"
$lines += ""

# --- 1. veraPDF ------------------------------------------------------------
Write-Host "== veraPDF ($Flavour) =="
$vera = $null
foreach ($c in @(
        "$env:USERPROFILE\Tools\veraPDF\verapdf.bat",
        "$env:LOCALAPPDATA\veraPDF\verapdf.bat",
        "$env:ProgramFiles\veraPDF\verapdf.bat")) {
    if (Test-Path $c) { $vera = $c; break }
}
if (-not $vera) {
    $cmd = Get-Command verapdf -ErrorAction SilentlyContinue
    if ($cmd) { $vera = $cmd.Source }
}

$htmlReport = Join-Path $root 'compliance-report.html'
if (-not $vera) {
    Write-Host "  SKIP: veraPDF not found."
    Write-Host "        Install it (free) from https://verapdf.org/software/"
    Write-Host "        Looked in %USERPROFILE%\Tools\veraPDF, %LOCALAPPDATA%\veraPDF,"
    Write-Host "        %ProgramFiles%\veraPDF, and PATH."
    Add-Result 'SKIP' "PDF/UA-$($Flavour.Substring(2)) conformance (veraPDF)" `
               "veraPDF is not installed, so conformance was NOT checked."
} else {
    $xml = Join-Path $build 'verapdf-report.xml'
    # No 2>&1 here: PowerShell 5.1 wraps a native command's stderr lines in
    # NativeCommandError records when redirected into a file, and veraPDF's
    # own parser warnings (plus a stack banner naming this machine's paths)
    # would otherwise land inside the report, above its <!DOCTYPE>. veraPDF's
    # stderr chatter is discarded here; its actual result comes from the xml
    # and html report files it writes on stdout.
    & $vera --flavour $Flavour --format xml $pdf 2>$null > $xml
    & $vera --flavour $Flavour --format html $pdf 2>$null > $htmlReport
    # Defensive: strip anything that ended up before the HTML report's real
    # start, in case some future veraPDF build writes to stdout too. Also
    # normalizes the file to plain UTF-8: PowerShell's redirection writes
    # veraPDF's stdout as UTF-16LE, which is valid HTML but round-trips
    # oddly through plain-text tooling, so re-save it as UTF-8 either way.
    # ReadAllText auto-detects the source encoding from its byte-order mark.
    if (Test-Path $htmlReport) {
        $htmlText = [System.IO.File]::ReadAllText($htmlReport)
        $docIndex = $htmlText.IndexOf('<!DOCTYPE')
        if ($docIndex -gt 0) { $htmlText = $htmlText.Substring($docIndex) }
        [System.IO.File]::WriteAllText($htmlReport, $htmlText, [System.Text.UTF8Encoding]::new($false))
    }
    $detail = (Select-String -Path $xml -Pattern '<details passedRules[^>]*>' |
               ForEach-Object { $_.Matches[0].Value }) -join ' '
    if (Select-String -Path $xml -Pattern 'isCompliant="true"' -Quiet) {
        Write-Host "  PASS ($Flavour)"
        Add-Result 'PASS' "PDF/UA-$($Flavour.Substring(2)) conformance (veraPDF)" $detail
    } else {
        Write-Host "  FAIL ($Flavour) -- failed rules:"
        $rules = Select-String -Path $xml -Pattern '<rule .*status="FAILED"' |
                 ForEach-Object { $_.Line.Trim() }
        $rules | ForEach-Object { Write-Host "    $_" }
        Add-Result 'FAIL' "PDF/UA-$($Flavour.Substring(2)) conformance (veraPDF)" `
                   (($detail, ($rules -join "`n       ")) -join "`n       ")
    }
}

# --- 2. Text extraction ----------------------------------------------------
Write-Host "== pdftotext =="
# pdftotext must be Poppler's. Several unrelated programs ship a pdftotext of
# the same name; the old xpdf one cannot read PDF 2.0 and reports the whole
# document as unmappable characters, which looks exactly like a real encoding
# failure. So resolve it explicitly and check what answered.
function Test-PopplerPdftotext([string]$path) {
    try { $out = (& $path -v 2>&1 | Out-String) } catch { return $false }
    if ($out -notmatch 'Poppler') { return $false }
    if ($out -match 'pdftotext\s+version\s+(\d+)') { return ([int]$Matches[1] -ge 24) }
    return $false
}
$pdftotext = $null
$candidates = @("$env:LOCALAPPDATA\Programs\MiKTeX\miktex\bin\x64\pdftotext.exe",
                "$env:LOCALAPPDATA\Programs\MiKTeX\miktex\bin\pdftotext.exe",
                "$env:ProgramFiles\MiKTeX\miktex\bin\x64\pdftotext.exe",
                'C:\texlive\bin\windows\pdftotext.exe')
$candidates += (Get-Command pdftotext -All -ErrorAction SilentlyContinue |
                ForEach-Object { $_.Source })
foreach ($c in $candidates) {
    if ($c -and (Test-Path $c) -and (Test-PopplerPdftotext $c)) { $pdftotext = $c; break }
}

$txt = Join-Path $build "$jobname.txt"
if (-not $pdftotext) {
    Write-Host "  FAIL: no Poppler pdftotext (version 24 or newer) was found."
    Write-Host "        It ships with MiKTeX; the expected location is"
    Write-Host "        %LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64\pdftotext.exe."
    Write-Host "        A pdftotext from xpdf cannot read PDF 2.0 and is not used."
    Add-Result 'FAIL' 'Text extraction' `
               ('No Poppler pdftotext (>= 24) found. It ships with MiKTeX at ' +
                '%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64. An xpdf pdftotext ' +
                'cannot read PDF 2.0, so it is deliberately not trusted here.')
} else {
    Write-Host "  using $pdftotext"
    & $pdftotext -enc UTF-8 -layout $pdf $txt
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  FAIL: pdftotext failed"
        Add-Result 'FAIL' 'Text extraction' 'pdftotext returned a non-zero exit code.'
    } else {
        $n = (Get-Content $txt).Count
        Write-Host "  extracted $n lines"
        if ($n -lt 50) {
            Add-Result 'FAIL' 'Text extraction' "Only $n lines extracted -- the PDF may be images, not text."
        } else {
            Add-Result 'PASS' 'Text extraction' "$n lines of real text extracted from the PDF."
        }

        # --- 3. Character encoding ----------------------------------------
        Write-Host "== encoding =="
        $content = [System.IO.File]::ReadAllText($txt, [System.Text.Encoding]::UTF8)
        $bad = ([regex]::Matches($content, "\uFFFD")).Count
        if ($bad -gt 0) {
            Write-Host "  FAIL: $bad replacement character(s) in the extracted text"
            Add-Result 'FAIL' 'Character encoding' `
                       "$bad U+FFFD replacement characters found -- some glyphs do not map back to Unicode."
        } else {
            Write-Host "  no replacement characters"
            Add-Result 'PASS' 'Character encoding' `
                       'No U+FFFD replacement characters; quotes, dashes and math symbols round-trip.'
        }
    }
}

# --- 4. Structure tree and alt text ---------------------------------------
Write-Host "== structure tree =="
# Reading the tag tree needs an uncompressed copy of the document. It builds in
# its own subfolder and is deleted at the end, so the only PDF ever left beside
# the final one is the final one.
$work = Join-Path $build 'tagtree'
if (-not (Test-Path $work)) { New-Item -ItemType Directory -Path $work | Out-Null }
$un = Join-Path $work 'thesis-uncompressed.pdf'
if (Test-Path (Join-Path $build "$jobname.bbl")) {
    Copy-Item (Join-Path $build "$jobname.bbl") `
              (Join-Path $work 'thesis-uncompressed.bbl') -Force
}
# main.tex itself is built, with object compression switched off from the
# command line. Compiling a separate copy of the document would mean keeping
# its list of \input lines in step with main.tex forever, and the first time
# they drifted the check would be reading a different document than the one
# being submitted.
# Two passes: the first writes .toc/.lof/.lot, the second typesets them, so
# the dumped structure tree actually contains the contents lists.
$uncompressed = '\pdfvariable compresslevel=0 \pdfvariable objcompresslevel=0 \input{main.tex}'
1..2 | ForEach-Object {
    & lualatex -interaction=nonstopmode -halt-on-error -file-line-error `
        "-output-directory=$work" -jobname=thesis-uncompressed `
        $uncompressed | Out-Null
}

# Python 3, however it is spelled on this machine. Each candidate is asked for
# its version and only accepted if it really answers "Python 3.x": on many
# machines "python" is a stub, an alias, or a Python 2.
$pyExe  = $null
$pyArgs = @()
foreach ($cand in @(
        [pscustomobject]@{ Name = 'py';      Pre = @('-3') },
        [pscustomobject]@{ Name = 'python';  Pre = @()     },
        [pscustomobject]@{ Name = 'python3'; Pre = @()     })) {
    $cmd = Get-Command $cand.Name -ErrorAction SilentlyContinue
    if (-not $cmd) { continue }
    try { $ver = (& $cmd.Source @($cand.Pre) --version 2>&1 | Out-String) } catch { continue }
    if ($ver -match 'Python\s+3\.') { $pyExe = $cmd.Source; $pyArgs = $cand.Pre; break }
}
$python = $pyExe

if (-not $python) {
    Write-Host "  FAIL: Python 3 was not found."
    Write-Host "        Tried py -3, python and python3."
    Write-Host "        Install it from https://www.python.org/downloads/"
    Add-Result 'FAIL' 'Figure alt text' `
               'Python 3 is not installed, so the structure tree could not be read.'
} elseif (-not (Test-Path $un)) {
    Write-Host "  FAIL: could not build the uncompressed copy of the document"
    Add-Result 'FAIL' 'Figure alt text' 'The uncompressed build used to read the tag tree failed.'
} else {
    $dump = Join-Path $build 'structure-dump.txt'
    & $pyExe @pyArgs (Join-Path $root 'util\dump-structure.py') $un > $dump
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  FAIL: dump-structure.py exited with code $LASTEXITCODE"
        Add-Result 'FAIL' 'Figure alt text' "dump-structure.py exited with code $LASTEXITCODE."
    } else {
        Write-Host "  wrote $dump"
        $summary = Select-String -Path $dump -Pattern '^ALT SUMMARY: figures=(\d+) with_alt=(\d+)'
        if (-not $summary) {
            Write-Host "  FAIL: the dump has no ALT SUMMARY line -- tooling mismatch"
            Add-Result 'FAIL' 'Figure alt text' 'The structure dump produced no ALT SUMMARY line.'
        } else {
            $figs = [int]$summary.Matches[0].Groups[1].Value
            $alts = [int]$summary.Matches[0].Groups[2].Value
            if ($figs -eq 0) {
                Write-Host "  no /Figure elements to check"
                Add-Result 'PASS' 'Figure alt text' 'The document contains no figures.'
            } elseif ($alts -lt $figs) {
                Write-Host "  FAIL: $($figs - $alts) of $figs figures have no usable /Alt text."
                Write-Host "        Add alt={...} to the \includegraphics call, or artifact"
                Write-Host "        if the image is purely decorative. Omitting alt= makes"
                Write-Host "        LaTeX fall back to the FILE NAME, which counts as missing."
                Add-Result 'FAIL' 'Figure alt text' `
                    ("$($figs - $alts) of $figs figures lack usable alt text. Add alt={...} to " +
                     "the \includegraphics call, or artifact if purely decorative. Note that " +
                     "omitting alt= makes LaTeX write the FILE NAME as the alt text, which " +
                     "counts as missing here. Details in $dump.")
            } else {
                Write-Host "  alt text present on all $figs figure(s)"
                Add-Result 'PASS' 'Figure alt text' `
                           "All $figs figure(s) carry descriptive alt text (not a file name)."
            }
        }
    }
}
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue

# --- 5. Build log ----------------------------------------------------------
Write-Host "== log =="
$bad = Select-String -Path $log -Pattern 'tagpdf.*(Warning|Error)|Overfull|Underfull|undefined (references|citations)|LaTeX Warning: Reference'
if ($bad) {
    $bad | ForEach-Object { Write-Host ("  " + $_.Line.Trim()) }
    Add-Result 'FAIL' 'Build log' (($bad | ForEach-Object { $_.Line.Trim() }) -join "`n       ")
} else {
    Write-Host "  clean: no tagpdf warnings, no unresolved references"
    Add-Result 'PASS' 'Build log' `
        'No tagging warnings, no unresolved references, no over/underfull lines (which would mean text outside the margins).'
}

# --- report ----------------------------------------------------------------
$lines += ""
$lines += if ($fail) { "RESULT: problems found -- see the FAIL lines above." }
          else       { "RESULT: all checks passed." }
$txtReport = Join-Path $root 'compliance-report.txt'
# Explicit UTF-8 write (not Set-Content -Encoding UTF8, which can double
# -encode already-UTF-8 text on PowerShell 5.1) so the report round-trips
# cleanly, and its content is exactly $lines -- nothing from an external
# tool's stderr can appear in it.
$txtText = ($lines -join "`r`n") + "`r`n"
[System.IO.File]::WriteAllText($txtReport, $txtText, [System.Text.UTF8Encoding]::new($false))

Write-Host ""
if ($fail) { Write-Host "COMPLIANCE CHECK: problems found (see above)." }
else       { Write-Host "COMPLIANCE CHECK: all checks passed." }
Write-Host "Report: $txtReport"
if ($vera) { Write-Host "        $htmlReport  (open in a browser)" }
exit $fail
