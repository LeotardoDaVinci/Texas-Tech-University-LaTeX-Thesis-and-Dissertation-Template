#!/usr/bin/env bash
#
# Build the thesis on macOS or Linux. The finished PDF appears beside this
# script under the name set by output-name in config/thesis-config.tex.
#
#   ./build-Mac-Linux.sh            build
#   ./build-Mac-Linux.sh --clean    empty build/ first, then build
#
# Windows: use build-Windows.bat instead. Do not edit.
#
# HONEST NOTE: this script was written on a Windows-only machine. It has been
# syntax-checked (bash -n) and mirrors util/build.ps1 step for step, but it has
# never been run end to end on macOS or Linux. If it misbehaves, util/build.ps1
# is the reference implementation.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build="$root/build"

# NOTE: the jobname is deliberately NOT the name of the delivered PDF.
# On a fatal error lualatex deletes <jobname>.pdf relative to the CURRENT
# DIRECTORY, ignoring -output-directory. Since lualatex is run from the
# template root (so \input paths resolve), a jobname matching the delivered
# file would make a failed build silently destroy it. Keeping the two names
# distinct removes the hazard by construction rather than by cleanup.
jobname="thesis-build"

# The delivered file name comes from config/thesis-config.tex, which is the
# single place it is written down.
# shellcheck source=util/output-name.sh
. "$root/util/output-name.sh"
thesis_output_name "$root" "$jobname" || exit 1
deliver="$root/$THESIS_OUTPUT_NAME.pdf"

cd "$root"

clean=0
for arg in "$@"; do
    case "$arg" in
        --clean|-c) clean=1 ;;
        *) echo "Unknown option: $arg" >&2
           echo "Usage: ./build-Mac-Linux.sh [--clean]" >&2
           exit 2 ;;
    esac
done

for tool in lualatex biber; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "$tool was not found on PATH." >&2
        echo "Install a TeX distribution that provides it (MacTeX on macOS," >&2
        echo "TeX Live on Linux), then re-run this script." >&2
        exit 1
    fi
done

if [ "$clean" -eq 1 ] && [ -d "$build" ]; then
    rm -rf "$build"
    echo "Cleaned $build"
fi
mkdir -p "$build"

texargs=(
    -interaction=nonstopmode
    -halt-on-error
    -file-line-error
    "-output-directory=$build"
    "-jobname=$jobname"
    main.tex
)

run_pass() {
    local n="$1"
    echo "== lualatex pass $n =="
    if ! lualatex "${texargs[@]}"; then
        echo "lualatex failed on pass $n; see $build/$jobname.log" >&2
        exit 1
    fi
}

run_pass 1

echo "== biber =="
if ! biber --input-directory "$build" --output-directory "$build" "$jobname"; then
    echo "biber failed; see $build/$jobname.blg" >&2
    exit 1
fi

run_pass 2
run_pass 3
# A fourth pass, because pass 2 is the first one that knows how many appendices
# the document has and so is the first that can un-letter a lone one. That
# changes the table of contents entry, which shifts every structure number
# after it; pass 3 lays the shifted numbers down and pass 4 is the one that
# reads them back consistently. Cheaper than asking anyone to notice.
run_pass 4

# Put the finished PDF where you can find it: in the template root, not buried
# in build/. This copy is the one you submit or send to your committee. It is
# written only after all passes succeed, so a failed build leaves the previous
# good copy exactly as it was. --clean does not delete it either: it is a
# deliverable, not a build artefact, and it is what a fresh clone ships.
cp -f "$build/$jobname.pdf" "$deliver"

echo "OK: $deliver  (working files in $build/)"
exit 0
