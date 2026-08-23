<#
    output-name.ps1 -- read the delivered PDF's file name out of
    config/thesis-config.tex.  Dot-sourced by build.ps1 and
    check-compliance.ps1 so the two can never disagree.  Do not edit.

    config/thesis-config.tex is the single place the name is written down:

        output-name = {Lastname-Dissertation},

    Empty, missing or commented out gives "thesis".
#>

function Get-ThesisOutputName {
    param(
        [Parameter(Mandatory)][string]$Root,
        [string]$JobName = 'thesis-build'
    )

    $default = 'thesis'
    $name    = $default
    $config  = Join-Path $Root 'config\thesis-config.tex'

    if (Test-Path $config) {
        foreach ($line in (Get-Content -LiteralPath $config)) {
            # Skip whole-line comments so a commented-out example never wins.
            if ($line -match '^\s*%') { continue }
            if ($line -match 'output-name\s*=\s*\{\s*(.*?)\s*\}') {
                if ($Matches[1]) { $name = $Matches[1] }
                break
            }
        }
    }

    # Tolerate a name typed with the extension, and keep it a plain file name.
    $name = $name -replace '\.pdf$', ''
    $name = ($name -replace '[\\/:*?"<>|]', '-').Trim()
    if (-not $name) { $name = $default }

    # The build jobname must stay distinct from the delivered file: lualatex
    # deletes <jobname>.pdf from the current directory on a fatal error, and
    # the current directory is the template root.
    if ($name -eq $JobName) {
        Write-Host "output-name in config/thesis-config.tex must not be '$JobName'."
        Write-Host "That name is reserved for the build's working files: a failed"
        Write-Host "build would delete your delivered PDF. Choose another name."
        exit 1
    }

    return $name
}
