# output-name.sh -- read the delivered PDF's file name out of
# config/thesis-config.tex.  Sourced by build-Mac-Linux.sh and
# check-compliance-Mac-Linux.sh so the two can never disagree.  Do not edit.
#
# config/thesis-config.tex is the single place the name is written down:
#
#     output-name = {Lastname-Dissertation},
#
# Empty, missing or commented out gives "thesis".
#
# Usage:  thesis_output_name "$root" "$jobname" || exit 1
#         ...sets THESIS_OUTPUT_NAME to the bare name.

THESIS_OUTPUT_NAME=""

thesis_output_name() {
    local root="$1"
    local jobname="${2:-thesis-build}"
    local config="$root/config/thesis-config.tex"
    local name=""

    if [ -f "$config" ]; then
        # Whole-line comments are skipped by the leading anchor, so a
        # commented-out example never wins.
        name="$(sed -n 's/^[[:space:]]*output-name[[:space:]]*=[[:space:]]*{[[:space:]]*\([^}]*\)[[:space:]]*}.*/\1/p' \
                "$config" | head -1)"
    fi

    # Tolerate a name typed with the extension, and keep it a plain file name.
    name="${name%.pdf}"
    name="$(printf '%s' "$name" | tr '\\/:*?"<>|' '-' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -n "$name" ] || name="thesis"

    # The build jobname must stay distinct from the delivered file: lualatex
    # deletes <jobname>.pdf from the current directory on a fatal error, and
    # the current directory is the template root.
    if [ "$name" = "$jobname" ]; then
        echo "output-name in config/thesis-config.tex must not be '$jobname'." >&2
        echo "That name is reserved for the build's working files: a failed" >&2
        echo "build would delete your delivered PDF. Choose another name." >&2
        return 1
    fi

    THESIS_OUTPUT_NAME="$name"
    return 0
}
