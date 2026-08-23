# Texas Tech University Thesis Template 2026

A LaTeX template for Texas Tech University theses and dissertations. It
follows the Graduate School's formatting manual (rev. February 2026) and
produces a properly tagged, PDF/UA-2 compliant PDF, which is required to pass
the Graduate School's accessibility check starting Spring 2026.

Template by Joseph L. Micus, Texas Tech University, PhD Class of 2026.

**To write and build:** **MiKTeX**, a free download from
<https://miktex.org/download> (it brings **LuaLaTeX** and **biber** with it),
plus the `tex-gyre` and `tex-gyre-math` font packages, which MiKTeX offers to
install the first time they are needed.

**To run `util\check-compliance-Windows.bat` as well:** **Python 3** on your
PATH (it reads the PDF's tag tree) and **veraPDF**, a free download from
<https://verapdf.org/software/> (it checks PDF/UA-2 conformance). Neither is
needed to produce the PDF, only to check it before you submit.
`util\check-compliance-Windows.bat` tells you plainly if either is missing.

---

## Quick start

1. Copy this whole folder and give it your own name.
2. Open `config/thesis-config.tex`. Set `output-name` to what the finished
   PDF should be called, then fill in your name, title, department, degree,
   committee, and graduation date.
3. In the same file choose your `left-margin` (`1in` or `1.5in`) and
   `line-spacing` (`onehalf` or `double`). Your name is assembled from
   `first-name`, `middle-initial`, `last-name` and `credentials`: the title
   page shows all four, the running header and copyright page show just
   `First M. Last`. Empty fields disappear cleanly.
4. Write your acknowledgments and abstract in `frontmatter/`.
5. List your abbreviations in `frontmatter/abbreviations.tex`, or delete its
   `\input` line from `main.tex` if you have none.
6. Read `chapters/chapter-style-example.tex` once. Every element you will ever
   need is in it, each preceded by a `% HOW TO:` comment you can copy.
7. For each new chapter: copy `chapters/chapter-style-example.tex`, rename it,
   and add one `\input` line to the **ADD YOUR CHAPTERS HERE** block in
   `main.tex`.
8. Put your references in `bibliography/references.bib` and cite them with
   `\cite{key}`.
9. Double-click **`build-Windows.bat`** (macOS/Linux: run
   `./build-Mac-Linux.sh`). Your PDF appears beside the script, named by
   `output-name`.
10. Run **`util\check-compliance-Windows.bat`** (macOS/Linux:
    `./util/check-compliance-Mac-Linux.sh`) before you submit.

## The files you edit — and the ones you don't

Everything you write lives in six places: `main.tex` (the list of chapters),
`config/` (your details and choices), and the `chapters/`, `frontmatter/`,
`figures/` and `bibliography/` folders. Those are yours, change them freely.

Everything else is formatting machinery: `ttuthesis2026.cls`, the build
scripts, and all of `util/`. Those files encode the Graduate School's rules
and the PDF tagging setup, and editing them risks damage that does not show
up until the accessibility check fails, formatting is wrong, or the document cannot compile.
 If something seems to require touching one of them, and it almost never does, the answer is 
in this README or in `chapters/chapter-style-example.tex`. Edit at your own risk, 
unless you are really good with LaTeX, in which case make it better and put in a request. 

## Masters thesis or dissertation?

Long documents are divided into chapters; a masters thesis is often short
enough that it reads better as a plain run of numbered sections. One key in
`config/thesis-config.tex` chooses between the two:

```latex
structure = {chapters},   % CHAPTER I, CHAPTER II, ...   (the default)
structure = {sections},   % 1. INTRODUCTION, 2. METHOD, ...
```

In `sections` mode there are no chapter banner pages. `\section` becomes your
top-level command, styled like a chapters-mode `\section` rather than a
chapter title, still listed in the table of contents, and every level below it
moves up one step. Only the first `\section` of the body starts a new page;
later ones run on like any other heading:

| chapters mode | sections mode | prints as |
| --- | --- | --- |
| `\chapter` | `\section` | `1. INTRODUCTION` |
| `\section` | `\subsection` | `1.1` |
| `\subsection` | `\subsubsection` | `1.1.1` |
| `\subsubsection` | `\paragraph` | unnumbered |
| `\paragraph` | `\subparagraph` | unnumbered, run-in |

Figures, tables and equations restart in each top-level section and take its
number — Figure 1.1, Table 2.3 — which is the same decimal scheme the chapter
mode uses, as the manual requires once you number anything decimally (p.22).
Appendices still work through `\ThesisAppendices`, which letters them from how
many there are; their titles are `\section` in this mode. The
front and back matter — title page, table of contents, abstract, the two
lists, bibliography — are untouched and stay top-level headings, and the
running header, margins, page numbering and tagging are identical in both
modes.

**The one manual step:** the switch does not rewrite your content, so point
`main.tex` at section-style files. Two samples ship for exactly this:

```latex
\input{chapters/section-style-example}     % instead of chapters/chapter-style-example
...
\ThesisAppendices
\input{chapters/section-style-appendix}    % instead of chapters/chapter-style-appendix
```

Copy those two the way you would copy `chapter-style-example.tex`. If you leave
a `\chapter` command in a `sections` document the build stops and tells you to
use `\section` instead, so a half-converted file cannot slip through.

## Which script do I run?

| Platform | Build | Check before submitting |
| --- | --- | --- |
| Windows | `build-Windows.bat` — double-click it, or run it from PowerShell | `util\check-compliance-Windows.bat` |
| macOS / Linux | `./build-Mac-Linux.sh` | `./util/check-compliance-Mac-Linux.sh` |

Each `.bat` file is a one-line shim around the matching PowerShell script in
`util/`, so double-clicking works without opening a terminal. Nothing in
`util/` is ever edited, only run.

**The `.sh` scripts are honestly untested.** This template was developed on a
Windows-only machine; `build-Mac-Linux.sh` and
`check-compliance-Mac-Linux.sh` mirror the PowerShell versions step for step
and have been syntax-checked, but they have never been run end to end on macOS
or Linux. If one misbehaves, the `.ps1` version is the reference implementation — the two are meant to do exactly the same thing.

### Build versus compliance check

**Build** makes the PDF: it runs LuaLaTeX, then biber for the bibliography,
then LuaLaTeX twice more so cross-references and the table of contents settle.
Run it as often as you like.

**The compliance check** runs the accessibility check the Graduate School
requires — PDF/UA-2 tagging and figure alt text, verified with veraPDF — and
alongside it the formatting health of the document: layout warnings from the
build log, and whether the text still extracts and round-trips as correct
characters. Run it before you submit; it is slower than a build and needs two
extra tools, so it is not something to run on every compile.

It prints a summary and also saves a report, overwritten each run:

- **`compliance-report.txt`** — every check with a `[PASS]` / `[FAIL]`
  line, a short explanation, and a timestamp. In the template root.
- **`compliance-report.html`** — veraPDF's own detailed report, also in the
  template root. Open it in a browser. Written only if veraPDF is installed.

### Generating the report by hand

The check script writes the report each time it runs, and it only reads the
PDF that the build script leaves in `build\`. So if you compile some other
way (clicking Typeset in TeXworks, running `lualatex` yourself, using an
editor plugin), you can still get the report: just let the build script
produce the copy the check knows how to find.

```powershell
.\build-Windows.bat                     # writes build\thesis-build.pdf
.\util\check-compliance-Windows.bat     # checks it, writes both reports
```

(macOS/Linux: `./build-Mac-Linux.sh` then `./util/check-compliance-Mac-Linux.sh`.)
Both reports land in the template root, overwritten each run. Neither is part
of your document; they exist so you can read them and fix what they flag
before you submit.

## Which file do I edit for what?

| I want to change...                      | Edit this file                         |
| ---------------------------------------- | -------------------------------------- |
| The finished PDF's file name             | `config/thesis-config.tex`             |
| My name, title, committee, degree, date  | `config/thesis-config.tex`             |
| Left margin (1" or 1.5") or line spacing | `config/thesis-config.tex`             |
| Chapters or plain numbered sections      | `config/thesis-config.tex`             |
| Abbreviated vs. full journal names       | `config/thesis-config.tex`             |
| Acknowledgments text                     | `frontmatter/acknowledgments.tex`      |
| Abstract text                            | `frontmatter/abstract.tex`             |
| List of abbreviations                    | `frontmatter/abbreviations.tex`        |
| Chapter text                             | `chapters/chapter-style-example.tex`, and yours |
| Which chapters appear, and their order   | `main.tex` (the banner block)          |
| Appendices                               | `chapters/chapter-style-appendix.tex`  |
| References                               | `bibliography/references.bib`          |

### Never edit these

`ttuthesis2026.cls`, the two build scripts in the root, and everything in
`util/`.

They encode the Graduate School's requirements and the PDF tagging setup.
Editing them is how a document stops being compliant. The class in
particular contains several fixes that look removable and are not.

---

## FAQ

### 1. What do I edit first?

`config/thesis-config.tex`. Nothing else needs touching to get a correctly
formatted document with your name on it.

### 2. How do I set the title and my name?

```latex
\ThesisSetup{
  title          = {Laser Diagnostics of Turbulent Premixed Flames},
  first-name     = {Jane},
  middle-initial = {Q},          % just the letter, or leave empty
  last-name      = {Doe},
  credentials    = {B.S., M.S.}, % or leave empty
}
```

The title has a 238-character limit; the build warns you if you exceed it. It
is used in three places at once: the title page, the PDF's own title metadata
(what a viewer shows in its title bar and what a screen reader announces on
opening), and the document properties. Setting it here is all that is needed;
until you do, every one of those reads "Texas Tech University Thesis Template
2026".

### 3. How do I choose the margin and spacing options?

```latex
left-margin  = {1in},      % or {1.5in}
line-spacing = {onehalf},  % or {double}
```

Both are document-wide choices the manual permits. Change them any time and
rebuild.

### 4. How do I add a chapter?

Copy `chapters/chapter-style-example.tex` to a new name, then add one line to
`main.tex`:

```latex
%% ==== ADD YOUR CHAPTERS HERE ====
\input{chapters/chapter-style-example}
\input{chapters/ch2-methods}     <-- your new line
```

### 5. How do I add a figure with alt text?

```latex
Figure~\ref{fig:spectra} shows the measured emission spectra.

\begin{figure}
  \centering
  \includegraphics[width=4in,
    alt={Emission spectrum from 400 to 700 nanometres with a single sharp
         peak near 589 nanometres and a broad shoulder above 600.}]{figures/spectra.pdf}
  \caption{Emission spectrum of the sodium-seeded flame.}
  \label{fig:spectra}
\end{figure}
```

The `alt=` key is required on every informative figure: one or two sentences
describing what the figure *shows*, which is not what the caption says. A
purely decorative image uses `artifact` instead of `alt`.

### 6. How do I add a table?

Caption above, real `tabular`, first row is the header:

```latex
Table~\ref{tab:conditions} lists the operating conditions.

\begin{table}
  \centering
  \caption{Operating conditions.}
  \label{tab:conditions}
  \begin{tabular}{lrr}
    \toprule
    Case & Pressure (kPa) & Temperature (K) \\
    \midrule
    Low  & 50 & 300 \\
    High & 200 & 600 \\
    \bottomrule
  \end{tabular}
\end{table}
```

For a table longer than a page use `longtable`. See the second table in the
sample chapter, which repeats its header row and labels the continuation.

### 7. How do I add and cite a reference?

Paste the BibTeX entry into `bibliography/references.bib`:

```bibtex
@article{doe2025,
  author       = {Doe, Jane Q.},
  title        = {Turbulent flame speed measurements},
  journal      = {Combustion and Flame},
  shortjournal = {Combust. Flame},
  volume       = {271},
  pages        = {113--127},
  year         = {2025},
}
```

Then cite it: `The method follows established practice~\cite{doe2025}.`

You seldom type an entry yourself: most journal sites and databases have a
"Cite" or "Export citation" button that hands you BibTeX, and Zotero, Mendeley
and EndNote will export a whole library as a `.bib` file you can drop in place
of this one.

Set `journal-abbreviations = {true}` in the config to print `Combust. Flame`
instead of the full title. DOIs, URLs, access dates, ISSN/ISBN and eprint IDs
are all suppressed by default; see the guide at the top of
`bibliography/references.bib` for what prints and how to turn a field back on.

Citations and the bibliography are IEEE numeric, set by the `bibstyle` and
`citestyle` options on line 724 of `ttuthesis2026.cls`. The manual does not
pick a citation style — it defers to your department's approved style guide
(p.5) — so if yours wants APA or Chicago, changing those two biblatex options
is the change to make. It is not automated here; searching for
`biblatex <style name>` will tell you which option value to use.

### 8. How do I add an equation and refer to it?

```latex
\begin{equation}
  S_T = S_L \left( 1 + \frac{u'}{S_L} \right)
  \label{eq:flamespeed}
\end{equation}

Equation~\eqref{eq:flamespeed} gives the turbulent flame speed.
```

No alt text is needed: every formula is exported as MathML automatically.

### 9. How do I compile?

Double-click `build-Windows.bat`, or from PowerShell:

```powershell
.\build-Windows.bat           # normal build
.\build-Windows.bat -Clean    # delete build\ and rebuild from scratch
```

On macOS or Linux:

```bash
./build-Mac-Linux.sh            # normal build
./build-Mac-Linux.sh --clean    # delete build/ and rebuild from scratch
```

It runs lualatex → biber → lualatex → lualatex and stops on the first error.

### 10. Where is the PDF?

**In the same folder as `build-Windows.bat`**, under the name you set with
`output-name` in `config/thesis-config.tex`: `TTU-Example-Dissertation.pdf`
until you change it, or `thesis.pdf` if you leave the value empty. That is the copy
to submit or send to your committee. It is refreshed at the end of every
successful build.

`build\` is the working directory: the same PDF plus the log, the
bibliography database, and the other intermediate files. Everything in it is
regenerated and can be deleted at any time — `-Clean` / `--clean` does exactly
that. The delivered PDF in the root is deliberately **not** deleted by a
clean, and a failed build leaves the last good copy untouched, so you always
have something to hand to someone.

`util\check-compliance-Windows.bat` and `util/check-compliance-Mac-Linux.sh`
check the copy inside `build\`. Run them straight after a build, so the two
files are the same document.

### 11. What must I never edit?

`ttuthesis2026.cls`, the two build scripts in the root, and everything in `util/`. See above.

### 12. How do I check accessibility before submitting?

```powershell
.\build-Windows.bat
.\util\check-compliance-Windows.bat
```

It prints one line per check (veraPDF conformance, text extraction, structure
tree, log triage) and ends with `COMPLIANCE CHECK: all checks passed.` or a
list of problems. Install veraPDF from <https://verapdf.org/software/> for the
first check; the other three run without it.

`docs/accessibility-guide.md` explains how to read the output and how to
inspect the tag tree yourself in Adobe Acrobat.

---

## The three accessibility rules you must follow

1. **Every figure needs `alt={...}`**: one or two sentences describing what
   the figure shows. Decorative images get `artifact` instead.
2. **Tables must be real tables**: a `tabular`, never a screenshot. The first
   row is tagged as the header row automatically.
3. **Link text must be meaningful**: write the address or a descriptive
   phrase, never "click here".

`docs/accessibility-guide.md` covers colour contrast, colour-alone figures,
heading hierarchy, and the rest.

## Notes on rules the template cannot enforce

The manual places these on you, not on the software. The full list, with page
citations and where each is handled, is in `docs/requirements-matrix.md`.

- **Thesis-dissertation fee.** A one-time $50 fee is payable to the Graduate
  School (p.9). Nothing in the template does this for you.
- **AI use.** AI may only *edit* your content, never create it. If you used AI
  at all you must submit a signed **AI Use Agreement** as an appendix, and add
  a disclosure under the heading of every chapter where it was used (pp.6, 31,
  34). Put the Agreement in an appendix file like the sample one.
- **Self-citation.** If you reuse your own previously published work you must
  cite it (p.6).
- **PII and signatures.** No original signatures in an appendix, and redact
  personal identifying information (p.25). The Acknowledgments should carry no
  personal identifying information either (p.18).
- **Mention floats before they appear.** Every table and figure must be
  referred to in the text before it shows up, and numbered in order of mention
  (p.23). Write the `\ref` sentence first; the template keeps the float with it.
- **Table font.** Keep table text at 8 pt or larger if you shrink a wide table
  (p.22). Tables inherit 12 pt by default, so this only matters if you override.
- **Oversized tables and figures.** Landscape pages are not available in this
  template. Split the table across pages with `longtable`, scale the figure
  with `width=`, or move it to an appendix (p.23).
- **A single appendix** is unlettered per the manual (p.25), and
  `\ThesisAppendices` handles that for you: it counts the appendices in the
  document, so one appendix prints a bare "APPENDIX" and numbers its tables and
  figures plainly (Table 1) rather than A.1, while two or more are lettered.
- **Preface.** Rare but permitted (p.20). Add one with
  `\ThesisFrontSection{Preface}` before `\ThesisTableOfContents` in `main.tex`.
- **Glossary.** Treated as an appendix (p.26). The `abbreviationlist`
  environment produces exactly the required layout. Use it inside an appendix
  chapter.
- **Multi-paper theses.** Co-authored chapters are allowed under conditions,
  with an authorship statement under the chapter title (pp.27–28). Write the
  statement as ordinary prose after `\chapter{...}`. Per-chapter reference
  lists are possible with `biblatex`'s `refsection` but are not configured out
  of the box.
- **Footnotes.** Use `\footnote{...}`; placement conventions follow your style
  guide (p.22).

## What is in `docs/`

| File | What it is |
| --- | --- |
| `requirements-matrix.md` | All 77 manual requirements, with where each is implemented and how each was checked. |
| `architecture-decisions.md` | Design notes: why the template is built this way; packages used and refused; known limitations. |
| `accessibility-guide.md` | Tagged PDF explained; alt text, tables, math, colour, links; how to run and read the compliance check. |
| (compliance report) | Not kept in `docs/` — the check scripts write it to `compliance-report.txt` in the template root every run, alongside `compliance-report.html`. Not in version control. |
| (tag-tree dump) | Not kept in `docs/` — the check scripts regenerate it at `build\structure-dump.txt` every run, so it can never go stale. |

## What is in `util/`

The build and compliance-check machinery: the PowerShell scripts the `.bat`
files call, the Python script that reads the PDF's tag tree, and the shared
helper that resolves the delivered PDF's name. You never need to open any of
it. See `util/README.md` if you are curious.
