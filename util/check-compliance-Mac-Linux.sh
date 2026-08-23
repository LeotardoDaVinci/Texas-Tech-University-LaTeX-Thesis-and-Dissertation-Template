#!/usr/bin/env bash
#
# Check the built thesis on macOS or Linux: PDF/UA-2 conformance, text
# extraction, character encoding, figure alt text, and build-log warnings.
# Run ./build-Mac-Linux.sh first.
#
#   ./util/check-compliance-Mac-Linux.sh            check against PDF/UA-2
#   ./util/check-compliance-Mac-Linux.sh --flavour ua1
#
# Writes compliance-report.txt and, if veraPDF is installed,
# compliance-report.html, both in the template root (the folder above).
# Windows: use util\check-compliance-Windows.bat instead. Do not edit.
#
# HONEST NOTE: this script was written on a Windows-only machine. It has been
# syntax-checked (bash -n) and mirrors util/check-compliance.ps1 step for step,
# but it has never been run end to end on macOS or Linux. If it misbehaves,
# util/check-compliance.ps1 is the reference implementation.

set -uo pipefail   # deliberately not -e: every check must run, then report

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build="$root/build"
jobname="thesis-build"
pdf="$build/$jobname.pdf"
log="$build/$jobname.log"
fail=0

# shellcheck source=util/output-name.sh
. "$root/util/output-name.sh"
thesis_output_name "$root" "$jobname" || exit 1
deliver="$root/$THESIS_OUTPUT_NAME.pdf"

flavour="ua2"
while [ $# -gt 0 ]; do
    case "$1" in
        --flavour) flavour="${2:-}"; shift 2 ;;
        *) echo "Usage: ./check-compliance-Mac-Linux.sh [--flavour ua2|ua1]" >&2; exit 2 ;;
    esac
done
case "$flavour" in
    ua1|ua2) ;;
    *) echo "--flavour must be ua2 or ua1" >&2; exit 2 ;;
esac

cd "$root"   # the second build below resolves \input paths from here

if [ ! -f "$pdf" ]; then
    echo "No $pdf -- run ./build-Mac-Linux.sh first."
    exit 1
fi

txt_report="$root/compliance-report.txt"
html_report="$root/compliance-report.html"
: > "$txt_report"

say() { printf '%s\n' "$1" >> "$txt_report"; }
add_result() {   # $1 status  $2 check  $3 detail
    printf '[%-4s] %s\n' "$1" "$2" >> "$txt_report"
    if [ -n "${3:-}" ]; then printf '       %s\n' "$3" >> "$txt_report"; fi
    if [ "$1" = "FAIL" ]; then fail=1; fi
}

say "Texas Tech University thesis template -- compliance report"
say "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
say "Checked:   $pdf"
say "Delivered: $deliver"
say ""

# --- 1. veraPDF ------------------------------------------------------------
echo "== veraPDF ($flavour) =="
vera=""
for c in \
    "$HOME/Tools/veraPDF/verapdf" \
    "$HOME/veraPDF/verapdf" \
    "/Applications/veraPDF/verapdf" \
    "$HOME/Applications/veraPDF/verapdf" \
    "/opt/verapdf/verapdf" \
    "/usr/local/verapdf/verapdf"
do
    if [ -x "$c" ]; then vera="$c"; break; fi
done
if [ -z "$vera" ] && command -v verapdf >/dev/null 2>&1; then
    vera="$(command -v verapdf)"
fi

if [ -z "$vera" ]; then
    echo "  SKIP: veraPDF not found."
    echo "        Install it (free) from https://verapdf.org/software/"
    echo "        Looked in \$HOME/Tools/veraPDF, \$HOME/veraPDF,"
    echo "        /Applications/veraPDF, \$HOME/Applications/veraPDF,"
    echo "        /opt/verapdf, /usr/local/verapdf, and PATH."
    add_result "SKIP" "PDF/UA-${flavour#ua} conformance (veraPDF)" \
               "veraPDF is not installed, so conformance was NOT checked."
else
    xml="$build/verapdf-report.xml"
    # stderr is discarded, not merged into the report: veraPDF's parser
    # warnings and any stack trace naming this machine's paths must never
    # land inside the report files.
    "$vera" --flavour "$flavour" --format xml  "$pdf" > "$xml"         2>/dev/null || true
    "$vera" --flavour "$flavour" --format html "$pdf" > "$html_report" 2>/dev/null || true
    # Defensive: strip anything ahead of the HTML report's real start, in
    # case some future veraPDF build writes to stdout too.
    if [ -f "$html_report" ]; then
        doc_line="$(grep -n '<!DOCTYPE' "$html_report" | head -1 | cut -d: -f1 || true)"
        if [ -n "$doc_line" ] && [ "$doc_line" -gt 1 ]; then
            tail -n "+$doc_line" "$html_report" > "$html_report.tmp" && mv "$html_report.tmp" "$html_report"
        fi
    fi
    detail="$(grep -o '<details passedRules[^>]*>' "$xml" | head -1 || true)"
    if grep -q 'isCompliant="true"' "$xml"; then
        echo "  PASS ($flavour)"
        add_result "PASS" "PDF/UA-${flavour#ua} conformance (veraPDF)" "$detail"
    else
        echo "  FAIL ($flavour) -- failed rules:"
        rules="$(grep -o '<rule [^>]*status="FAILED"[^>]*>' "$xml" || true)"
        printf '%s\n' "$rules" | sed 's/^/    /'
        add_result "FAIL" "PDF/UA-${flavour#ua} conformance (veraPDF)" "$detail $rules"
    fi
fi

# --- 2. Text extraction ----------------------------------------------------
echo "== pdftotext =="
# pdftotext must be Poppler's. Several unrelated programs ship a pdftotext of
# the same name; the old xpdf one cannot read PDF 2.0 and reports the whole
# document as unmappable characters, which looks exactly like a real encoding
# failure. So resolve it explicitly and check what answered.
is_poppler_pdftotext() {
    local out major
    out="$("$1" -v 2>&1 || true)"
    case "$out" in *Poppler*|*poppler*) ;; *) return 1 ;; esac
    major="$(printf '%s' "$out" | sed -n 's/.*pdftotext version \([0-9][0-9]*\).*/\1/p' | head -1)"
    [ -n "$major" ] && [ "$major" -ge 24 ]
}

pdftotext_bin=""
candidates=""
if command -v pdftotext >/dev/null 2>&1; then
    candidates="$(command -v pdftotext)"
fi
candidates="$candidates
/usr/local/bin/pdftotext
/opt/homebrew/bin/pdftotext
/usr/bin/pdftotext
/opt/local/bin/pdftotext"
for c in $candidates; do
    if [ -x "$c" ] && is_poppler_pdftotext "$c"; then pdftotext_bin="$c"; break; fi
done

txt="$build/$jobname.txt"
if [ -z "$pdftotext_bin" ]; then
    echo "  FAIL: no Poppler pdftotext (version 24 or newer) was found."
    echo "        Install poppler-utils (Linux) or 'brew install poppler' (macOS);"
    echo "        MacTeX and TeX Live also ship one."
    echo "        A pdftotext from xpdf cannot read PDF 2.0 and is not used."
    add_result "FAIL" "Text extraction" \
        "No Poppler pdftotext (>= 24) found. Install poppler-utils (Linux) or poppler via Homebrew (macOS). An xpdf pdftotext cannot read PDF 2.0, so it is deliberately not trusted here."
elif ! "$pdftotext_bin" -enc UTF-8 -layout "$pdf" "$txt"; then
    echo "  FAIL: pdftotext failed"
    add_result "FAIL" "Text extraction" "pdftotext returned a non-zero exit code."
else
    echo "  using $pdftotext_bin"
    n="$(wc -l < "$txt" | tr -d '[:space:]')"
    echo "  extracted $n lines"
    if [ "$n" -lt 50 ]; then
        add_result "FAIL" "Text extraction" \
                   "Only $n lines extracted -- the PDF may be images, not text."
    else
        add_result "PASS" "Text extraction" "$n lines of real text extracted from the PDF."
    fi

    # --- 3. Character encoding --------------------------------------------
    echo "== encoding =="
    bad="$(grep -c $'\xef\xbf\xbd' "$txt" || true)"
    if [ "${bad:-0}" -gt 0 ]; then
        echo "  FAIL: replacement characters in the extracted text"
        add_result "FAIL" "Character encoding" \
                   "U+FFFD replacement characters found on $bad line(s) -- some glyphs do not map back to Unicode."
    else
        echo "  no replacement characters"
        add_result "PASS" "Character encoding" \
                   "No U+FFFD replacement characters; quotes, dashes and math symbols round-trip."
    fi
fi

# --- 4. Structure tree and alt text ---------------------------------------
echo "== structure tree =="
# Reading the tag tree needs an uncompressed copy of the document. It builds in
# its own subfolder and is deleted at the end, so the only PDF ever left beside
# the final one is the final one.
work="$build/tagtree"
mkdir -p "$work"
un="$work/thesis-uncompressed.pdf"
if [ -f "$build/$jobname.bbl" ]; then
    cp -f "$build/$jobname.bbl" "$work/thesis-uncompressed.bbl"
fi
# main.tex itself is built, with object compression switched off from the
# command line. Compiling a separate copy of the document would mean keeping
# its list of \input lines in step with main.tex forever, and the first time
# they drifted the check would be reading a different document than the one
# being submitted.
# Two passes: the first writes .toc/.lof/.lot, the second typesets them, so
# the dumped structure tree actually contains the contents lists.
uncompressed='\pdfvariable compresslevel=0 \pdfvariable objcompresslevel=0 \input{main.tex}'
for _ in 1 2; do
    lualatex -interaction=nonstopmode -halt-on-error -file-line-error \
        "-output-directory=$work" -jobname=thesis-uncompressed \
        "$uncompressed" >/dev/null 2>&1 || true
done

# Python 3, however it is spelled on this machine. Each candidate is asked for
# its version and only accepted if it really answers "Python 3.x".
python=""
for p in python3 python; do
    if command -v "$p" >/dev/null 2>&1; then
        if "$p" --version 2>&1 | grep -qE '^Python 3\.'; then python="$p"; break; fi
    fi
done

if [ -z "$python" ]; then
    echo "  FAIL: Python 3 was not found."
    echo "        Tried python3 and python."
    echo "        Install it from https://www.python.org/downloads/"
    add_result "FAIL" "Figure alt text" \
               "Python 3 is not installed, so the structure tree could not be read."
elif [ ! -f "$un" ]; then
    echo "  FAIL: could not build the uncompressed copy of the document"
    add_result "FAIL" "Figure alt text" "The uncompressed build used to read the tag tree failed."
else
    dump="$build/structure-dump.txt"
    if ! "$python" "$root/util/dump-structure.py" "$un" > "$dump"; then
        echo "  FAIL: dump-structure.py exited non-zero"
        add_result "FAIL" "Figure alt text" "dump-structure.py exited non-zero."
    else
        echo "  wrote $dump"
        summary="$(grep -E '^ALT SUMMARY: figures=[0-9]+ with_alt=[0-9]+' "$dump" || true)"
        if [ -z "$summary" ]; then
            echo "  FAIL: the dump has no ALT SUMMARY line -- tooling mismatch"
            add_result "FAIL" "Figure alt text" "The structure dump produced no ALT SUMMARY line."
        else
            figs="$(printf '%s' "$summary" | sed -E 's/.*figures=([0-9]+).*/\1/')"
            alts="$(printf '%s' "$summary" | sed -E 's/.*with_alt=([0-9]+).*/\1/')"
            if [ "$figs" -eq 0 ]; then
                echo "  no /Figure elements to check"
                add_result "PASS" "Figure alt text" "The document contains no figures."
            elif [ "$alts" -lt "$figs" ]; then
                echo "  FAIL: $((figs - alts)) of $figs figures have no usable /Alt text."
                echo "        Add alt={...} to the \\includegraphics call, or artifact"
                echo "        if the image is purely decorative. Omitting alt= makes"
                echo "        LaTeX fall back to the FILE NAME, which counts as missing."
                add_result "FAIL" "Figure alt text" \
                    "$((figs - alts)) of $figs figures lack usable alt text. Add alt={...} to the \\includegraphics call, or artifact if purely decorative. Note that omitting alt= makes LaTeX write the FILE NAME as the alt text, which counts as missing here. Details in $dump."
            else
                echo "  alt text present on all $figs figure(s)"
                add_result "PASS" "Figure alt text" \
                           "All $figs figure(s) carry descriptive alt text (not a file name)."
            fi
        fi
    fi
fi
rm -rf "$work"

# --- 5. Build log ----------------------------------------------------------
echo "== log =="
bad="$(grep -E 'tagpdf.*(Warning|Error)|Overfull|Underfull|undefined (references|citations)|LaTeX Warning: Reference' "$log" || true)"
if [ -n "$bad" ]; then
    printf '%s\n' "$bad" | sed 's/^/  /'
    add_result "FAIL" "Build log" "$bad"
else
    echo "  clean: no tagpdf warnings, no unresolved references"
    add_result "PASS" "Build log" \
        "No tagging warnings, no unresolved references, no over/underfull lines (which would mean text outside the margins)."
fi

# --- report ----------------------------------------------------------------
say ""
if [ "$fail" -ne 0 ]; then
    say "RESULT: problems found -- see the FAIL lines above."
else
    say "RESULT: all checks passed."
fi

echo
if [ "$fail" -ne 0 ]; then
    echo "COMPLIANCE CHECK: problems found (see above)."
else
    echo "COMPLIANCE CHECK: all checks passed."
fi
echo "Report: $txt_report"
if [ -n "$vera" ]; then echo "        $html_report  (open in a browser)"; fi
exit "$fail"
