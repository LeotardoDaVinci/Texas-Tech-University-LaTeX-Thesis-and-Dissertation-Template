# util/

Build and compliance-check machinery. **Nothing here is needed to write a
thesis** — you never have to open this folder. The four scripts in the template
root are the entry points; two of them just call the PowerShell files here.

| File | What it does |
| --- | --- |
| `build.ps1` | The real Windows build: lualatex → biber → lualatex → lualatex, then copies the finished PDF into the template root under the name from `output-name`. Called by `build-Windows.bat`. |
| `check-compliance.ps1` | The real Windows compliance check: veraPDF conformance, text extraction, character encoding, figure alt text, build-log triage. Writes `docs/compliance-report.txt` and `compliance-report.html` in the root. Called by `check-compliance-Windows.bat`. |
| `output-name.ps1`, `output-name.sh` | Read `output-name` out of `config/thesis-config.tex` and hand back the delivered PDF's file name. Shared by the build and check scripts on each platform so the two can never disagree about what the file is called. |
| `dump-structure.py` | Walks the PDF's `/StructTreeRoot` and prints an indented outline of the tag tree, a tag-name histogram, and every `/Alt` and `/ActualText` string decoded — including the UTF-16BE hex form (`/Alt <FEFF0041…>`) that LaTeX actually writes. It ends with a machine-readable `ALT SUMMARY:` line the check scripts assert on, and flags any `/Alt` that is merely the graphic's file name. Requires Python 3; no third-party packages. |

The macOS/Linux scripts (`build-Mac-Linux.sh`, `check-compliance-Mac-Linux.sh`)
carry their logic inline in the root rather than shimming to anything here,
because on those platforms they *are* the entry point. The one exception is
`output-name.sh`, which they source.

Three details worth knowing if you ever change the scripts:

- **The build jobname is `thesis-build`, and the delivered PDF must never be
  called that.** On a fatal error lualatex deletes `<jobname>.pdf` relative to
  the *current directory*, ignoring `-output-directory`. lualatex runs from the
  template root so that `\input` paths resolve, so a jobname matching the
  delivered file would make a failed build silently delete it. The name
  resolver refuses `thesis-build` as an `output-name` for exactly this reason.
- **The tag-tree build goes into `build/tagtree/` and that folder is deleted**
  when the check finishes, so the only PDF ever left beside the working files
  is the working copy itself. It compiles `main.tex` itself with
  `\pdfvariable compresslevel=0`, rather than a second copy of the document
  with `uncompress` in its `\DocumentMetadata`, so the tree that is checked can
  never belong to a document that has drifted out of step with the real one.
- **`pdftotext` is resolved explicitly, not taken from PATH.** Only Poppler's
  build, version 24 or newer, can read PDF 2.0; an xpdf `pdftotext` of the same
  name reports the whole document as unmappable characters, which looks exactly
  like a real encoding failure. The check scripts verify `pdftotext -v` before
  trusting whatever they found.
