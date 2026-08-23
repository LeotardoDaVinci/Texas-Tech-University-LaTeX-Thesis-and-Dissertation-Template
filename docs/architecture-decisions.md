# Design Notes

Why this template is built the way it is: each decision and the reasoning
behind it. Line references are to `ttuthesis2026.cls` unless stated otherwise.
Decisions are listed in the order they constrain everything else, and are
numbered so other documents can cite them.

---

## D1. Engine: LuaLaTeX, not pdfLaTeX or XeLaTeX

LuaLaTeX is the only engine for which `luamml` generates MathML from ordinary
`amsmath` source. Equations are the hardest part of an accessible thesis, and
MathML is the only mechanism that makes them genuinely readable by assistive
technology. pdfLaTeX's math tagging is markedly weaker.

Consequence: OpenType fonts via `fontspec`, and no `inputenc`/`fontenc`.

## D2. Standard: PDF/UA-2, declared in `\DocumentMetadata`

`main.tex` opens with
`\DocumentMetadata{lang=en, pdfstandard=ua-2, tagging=on, tagging-setup={math/setup=mathml-SE}}`.
This is the official LaTeX Project mechanism (kernel + `latex-lab` + `tagpdf`),
not a bolt-on package.

**UA-1 fallback.** veraPDF reports the shipped PDF compliant with PDF/UA-2,
1727 rules passed, 0 failed, for both layout variants. Should a future
toolchain regression make UA-2 unreachable, `pdfstandard=ua-1` is a one-word
change and remains a valid target.

## D3. Class: a fresh `ttuthesis2026.cls` on `report`

`article`/`report`/`book` are the tagging-tested baseline. KOMA is known
broken for tagging; `memoir` is unverified. `\LoadClass[12pt,oneside,letterpaper]{report}`
gives chapters, front matter, and a `\ps@` page-style hook, and nothing has to
be fought.

## D4. Packages deliberately NOT used

| Package | Why not |
|---|---|
| `titlesec` | Upstream status **currently-incompatible** (tagging issue #24). Replaced by `latex-lab` `\DeclareInstance{heading}` templates (lines 245–333). |
| `caption`, `subcaption` | Upstream status **currently-incompatible**: it overwrites the tagging configuration and breaks with hyperref + LoF. Replaced by the `caption/label` socket plug and a re-implemented `\@makecaption` (lines 386–425). |
| `tocloft` | Compatible, but it supplies its own `\l@chapter`, `\l@figure`, … which never fire the kernel hooks that carry the links and the tags. In the previous thesis this silently killed 99 links. Replaced by a restyled kernel `\@dottedtocline` (lines 540–600). |
| `fancyhdr` | Compatible, but a hand-rolled `\ps@ttumain` is ~15 lines (lines 208–226) and the kernel head/foot material is artifacted automatically. |
| `adjustbox` | Hijacks the `graphicx` key parser and **rejects the `alt=` key**, which is the template's whole alt-text interface. |
| `float`, `ragged2e`, `footmisc`, `pdflscape`, `xcolor`, `calc`, `siunitx` | Carried by the previous thesis; nothing in this template needs them. Not loading a package is the cheapest way to avoid a tagging regression. |
| `indentfirst` | Tagging status unverified, and the whole package is two lines. Those two lines are inlined instead (lines 375–376). |
| `array` | The tables use plain `l r r` column specs and nothing calls an `array` feature. |

## D5. Packages that ARE loaded, one line each

Every package must serve a manual requirement that core LaTeX cannot.

| Package | Requirement served | Why core LaTeX is not enough |
|---|---|---|
| `fontspec` | Font, manual p.21 (≥12 pt serif) | Core LaTeX cannot load an OpenType font; also required for the Unicode text encoding that makes text extraction correct. |
| `unicode-math` | Equations, p.24 | Supplies the OpenType math font matching the body text, and the Unicode math encoding that `luamml` needs to emit MathML. |
| `geometry` | Margins, p.14 | Core LaTeX exposes only `\oddsidemargin`/`\topmargin` offsets relative to a 1 in origin; stating the four margins directly is what makes the values auditable against the manual. |
| `setspace` | Line spacing, p.21, and the single-space exceptions | `\baselinestretch` cannot be changed mid-document safely; `\singlespacing`/`\setstretch` can, and the manual requires local single spacing inside headings, captions, and reference entries. |
| `graphicx` | Figures + alt text, p.23 | Core LaTeX has no image inclusion, and `alt=`/`artifact` are `graphicx` keys instrumented by `latex-lab`. |
| `amsmath` | Numbered equations at the right margin, p.24 | Core LaTeX has `equation` but no `\eqref`, and `luamml`'s MathML support targets `amsmath` structures. |
| `booktabs` | Table appearance, pp.22–23 | `\hline` gives one rule weight, no rule spacing control, and abutting rules; `booktabs` is also the table package whose tagging is explicitly tested (needs `latex-lab` firstaid). |
| `longtable` | Multi-page tables with repeated headings, pp.22–23 | A core `tabular` cannot break across a page at all, so this requirement is otherwise unmeetable. |
| `etoolbox` | ToC level-gap rule | `\pretocmd` patches the kernel `\l@chapter`/`\l@section` bodies; there is no kernel equivalent for prepending to an existing macro. |
| `hyperref` | Links, ToC navigation, PDF metadata, p.25 | No kernel link or PDF-metadata mechanism exists; `biblatex` also requires it. |
| `biblatex` | Bibliography, p.25 | Needs per-entry spacing (`\bibitemsep`), single spacing inside an entry (`\bibfont`), no entry split across pages (`\interlinepenalty`), and a switchable journal-abbreviation source map, none of which plain BibTeX provides. |

## D6. Caption mechanism

`latex-lab-testphase-float.sty` re-defines `\@makecaption` from inside
`\AddToHook{begindocument}`, so a class-level `\def` is dead on arrival. The
replacement therefore lives in `begindocument/end` and re-emits the
`caption/begin`, `caption/label/*`, `para/begin` and `caption/end` tagging
sockets by hand; drop those and `/Caption`, `/Lbl` and `/P` disappear from the
tree. The `Figure 1.1.` period separator comes from a `caption/label` socket
plug, because `latex-lab`'s kernel plug is hard-coded to `#1:~`.

`longtable` draws its caption through `\LT@makecaption` instead, which is
separately re-implemented (lines 430–447) so that a long-table caption lines up
with an ordinary one to the point, including backing out the `\tabcolsep`
that the caption inherits from sitting inside the table's first column.

## D7. Floats tagged where declared

`\tagpdfsetup{float/here}`. By default `latex-lab` defers float tagging to
shipout and pools every float in the document into one `/figures` division at
the very end, structurally divorced from the chapter that references it, and
read last by a screen reader. `float/here` files each float under the section
that declares it. It is a tagging-time switch only; `[htbp]` and the float
placement algorithm are untouched.

## D8. Equation accessibility: MathML only

No hand-written equation alt text and no alt-text registry. `luamml` exports
every display and inline formula as MathML inside the structure tree
(`Formula > math > mrow/mfrac/mi/mo`). This was chosen over the manual's
"1–2 sentence" equation description (p.24) because MathML is strictly more
useful to assistive technology and is what the accessibility standard the
manual points at actually wants. A student who wants prose as well can simply
write a sentence describing the equation in the body text.

## D9. `\tagpdfsetup{activate/spaces=false}` is not optional

Turning tagging on also turns on automatic interword-space insertion, which
writes real space glyphs into the content stream at word boundaries. Inside
mathematics this displaces glyphs so they overprint their neighbours. What is
given up is small: LuaTeX already emits real spaces for ordinary interword
gaps, so extraction and copy-paste are unaffected.

## D10. Font: TeX Gyre Termes

A Times clone with a matching OpenType math font, so body and math agree, and
`newtx` (pdfLaTeX-only) is not needed. Fonts are loaded **by file name**, not family name, because family lookup
depends on a current `luaotfload` database that a fresh MiKTeX does not have.

## D11. Build: PowerShell/batch, not latexmk

`latexmk` is a Perl script and Perl is not on this machine's PATH.
`util/build.ps1` runs lualatex → biber → lualatex → lualatex directly, which is
also easier for a student to read than a latexmk rc file. `build-Windows.bat` wraps it
so the template is double-clickable.

## D12. Font packages are a prerequisite, not a bundled asset

The body and math fonts come from the `tex-gyre` and `tex-gyre-math` CTAN
packages (`texgyretermes-*.otf`, `texgyretermes-math.otf`). Both must be
installed in the TeX distribution; `tex-gyre-math` (1.6 MB) is not always
present by default. Nothing else outside a stock MiKTeX or TeX Live is
required.

## D13. Justification kept (manual p.21)

The manual forbids full justification "unless your word processing software is
sufficiently sophisticated enough to keep your text from appearing with large
gaps and spaces." TeX's total-fit paragraph breaker is that software, and the
claim is testable rather than asserted: an over-stretched line raises an
`Underfull \hbox` warning, and `check-compliance-Windows.bat` fails on any such warning in the
log. `\ThesisRaggedRight` is provided as a one-line escape hatch if a reviewer
objects anyway.

## D14. Appendices letter themselves, open as banners, and why floats stay "A.1"

The manual letters two or more appendices A, B, C but leaves a lone appendix
unlettered (p.25). That used to be the author's choice between two commands,
which is exactly the kind of decision a template should not ask for: getting it
wrong is silent, and the shipped example got it wrong itself, printing
"APPENDIX A" over a single appendix. `\ThesisAppendices` is now the only
command and works the distinction out for itself.

The count comes for free. `\appendix` zeroes the counter that appendix
top-level headings step — `chapter` in chapters mode, `section` in sections
mode — so at `\end{document}` that counter *is* the number of appendices. An
`\AtEndDocument` hook writes it into the `.aux` as `\ttu@setappcount{n}`, and
the next run reads it back before the appendices begin: the same round trip the
table of contents and cross-references already depend on. A first pass over a
fresh document has no count yet and letters the appendices, which is the safe
default — un-lettering several appendices would print the same bare "APPENDIX"
over each of them — and the pass after that settles. Because the count does
not depend on the form chosen, the round trip cannot oscillate, and the class
warns when the count changes so a hand-run single pass is not silently stale.

Un-lettering changes the table of contents entry, which shifts every structure
number after it, and the shifted numbers need one more pass to be read back
consistently or `tagpdf` reports destinations with no related structure. The
build scripts therefore run four passes rather than three, which also absorbs
the same shift when an author adds or removes an appendix.

`\ThesisSingleAppendix` survives as an alias for `\ThesisAppendices` so that
documents written against the old two-command interface keep compiling.

**Appendix titles are division banners in both modes.** The manual asks that
appendix titles be styled like chapter titles (p.25), which is a statement about
rank: an appendix is a major division, the peer of the Bibliography and the
Abstract, not a heading inside the body. Those divisions look the same whichever
structure the document uses — centred, uppercase, at the top of a fresh page —
so appendices do too. In chapters mode `\chapter` already delivers that. In
sections mode the top-level heading is `\section`, which normally prints flush
left and runs on from the text above it, so for the appendix run the section
heading instance is re-declared to the chapter banner and `\section` is wrapped
in a `\clearpage`. The instance stays at level 0, so the tagged structure does
not move: the appendix title is still H1 and its `\subsection` subheadings H2.
This supersedes the earlier choice to let sections-mode appendices keep the body
section look, which left several appendices running together on one page with no
banner between them. The table of contents follows: a flag written into the
`.toc` at the start of the appendices tells `\l@section` to stop overriding the
uppercase level-0 format, so appendix entries read like BIBLIOGRAPHY rather than
like body sections — and that restores the `\ifblank` guard that keeps a lone,
unlettered appendix from printing as ". SUPPLEMENTARY MATERIAL".

**The section-style files now refuse to run in a chapters document.** This is
the mirror of the existing block on `\chapter` in a sections document, and it
closes a trap that cost a real build: `\section` is perfectly legal in a
chapters document, it just means *subheading*, so a `section-style-appendix.tex`
inputted there was not an error at all. It was quietly absorbed into the
appendix before it — no banner, no page break, and, because the appendix count
is taken from the top-level counter, the count stayed at one and the whole run
reverted to the unlettered form. Silent and expensive to diagnose. The guard
turns it into a message naming the file to use instead.

The unlettered form works by emptying `\thechapter` (or `\thesection` in
sections mode), which also removes the chapter component from `\thesection`
(otherwise a lone appendix would number its first section "1.1", the string
Chapter I already used) and numbers its floats plainly ("Table 1").

Appendix floats in the lettered form are numbered **A.1, not A1**. The manual
is silent on the format and defers to the style guide (p.5); Turabian uses the
decimal form, and p.22 requires that whatever numbering scheme is used be
applied consistently, which the document's existing 1.1 scheme settles.

A lone appendix numbers its floats **1, not A.1**. The manual mandates the
unlettered title and requires appendix tables and figures to be numbered and
listed (p.25) but says nothing about the form of the numbers, so p.5 hands the
question to Turabian. Turabian heads a lone appendix simply "Appendix", with no
letter (9th ed., p.410), and reserves double numeration for material inside a
numbered division; matter outside one is numbered straight through. An
unlettered appendix has no division number for a decimal to hang off, so
"Table A.1" would print a letter the manual has just struck from the title. No
Turabian passage addressing the lone-appendix float case directly was found, so
this is a consistency-and-clarity reading rather than a quoted rule. It does
not offend p.22: the lone appendix drops decimal numbering from headings,
floats and equations together rather than mixing two schemes, and nothing
collides, since body floats are "Table 1.1" and never "Table 1". The cost is
that the List of Tables reads 1.1, 1.2, 1 — the appendix entry looks out of
sequence until you notice it is the last one — which is the price of not
inventing a letter the manual removed.

## D15. Tables are flush left

The manual does not specify table alignment. Captions are flush left, and a
`longtable` cannot be centred here because `\LTleft` is pinned to 0 pt so its
caption can align with an ordinary one. A centred `tabular` under a flush-left
caption therefore reads as an error, and two tables on the same page would not
match each other. All tables are set flush left; an author who wants a
particular one centred can still write `\centering` inside it.

## D16. The tag-tree build is kept away from the deliverable

`check-compliance-Windows.bat` needs a second, uncompressed build of the
document to read the structure tree: `main.tex` itself, compiled with
`\pdfvariable compresslevel=0` from the command line rather than from a second
copy of the document, so the tree that is checked cannot belong to a stale
duplicate. It builds into
`build	agtree\` and that folder is deleted when the check finishes, so
exactly one PDF is ever left in `build\` and there is never a question of
which one to submit. The `thesis-luamml-mathml.html` that remains is a
byproduct of the main build, not a second version of the document.

## D17. What "1.5" and "double" spacing mean numerically

`setspace` renders them as roughly 1.24x and 1.66x the single-spaced baseline,
not literally 1.5x and 2.0x: measured line pitches are 14.4 pt single, 17.9 pt
at `onehalf`, 23.9 pt at `double`. This is `setspace`'s standard
interpretation and matches what Word calls 1.5-line and double spacing, which
is the comparison the Graduate School actually makes; the previous accepted
TTU thesis used the same package and the same values. A reviewer measuring
with a ruler could read p.21 more literally, so the numbers are recorded here.

## D18. Caption is tagged before its Figure

Inside a `float` element the order is `Caption`, then the `Figure`, even
though the caption prints below the image. This is latex-lab's ordering, it is
legal under PDF/UA-2 (veraPDF passes), and it means a screen reader announces
the caption first — arguably an advantage, since the caption says what is
coming. Left as-is rather than fought, because reordering would mean
re-implementing latex-lab's float tagging.

## D19. Omitting `alt=` does not produce a missing `/Alt`

If `\includegraphics` is given no `alt=` key, latex-lab falls back to writing
the **file name** into `/Alt`. The figure therefore *has* alt text as far as
veraPDF is concerned, and a presence-only check passes, while a screen reader
reads out "figures slash example dash double dash t dot png". Two things catch
it: the tagpdf log warning (`Alternative text for graphic is missing`), which
`check-compliance-Windows.bat` treats as a failure, and
`util/dump-structure.py`, which flags any `/Alt` that looks like a file path
and reports it in the `ALT SUMMARY` line the compliance check asserts on.

---

## Known limitations

1. **`biblatex` footnote warning.** Every build prints
   `Package biblatex Warning: Patching footnotes failed. Footnote detection
   will not work.` This is a known `biblatex` + `latex-lab` interaction. It
   affects only `biblatex`'s ability to notice that a citation is inside a
   footnote (which changes nothing in a numeric IEEE style). Nothing in the
   template depends on it. It is the one warning `check-compliance-Windows.bat` does not treat
   as a failure.
2. **`\ThesisSetup` cannot contain a blank line.** A blank line becomes a
   `\par` token inside the key/value list and produces a confusing keyval
   error. The config file says so, and every gap in it is a `%` comment line.
3. **Title page tagging is flat.** The title page's lines land as one
   `text-unit` of `text` nodes directly under `/Document`, not inside a
   `/Sect`. veraPDF accepts it, and no information is lost, but it is less
   structured than the rest of the document.
4. **`float/here` versus float placement.** Floats are *tagged* where declared
   but still *placed* by LaTeX. If a float drifts far from its declaration the
   tag order and the visual order diverge. Default placement is `htbp` with
   generous float fractions to keep the two together; mention every float in
   the text before it appears, as the manual requires.
5. **`csquotes`** (pulled in by `biblatex`) has a known minor LuaTeX
   quote-spacing issue upstream (#1041). Nothing in the template calls
   `csquotes` directly and no artefact of it has appeared in any build.
6. **No landscape pages.** `pdflscape` was dropped. An oversized table or
   figure must be split, scaled, or moved to an appendix.
7. **Stray `Floatstructure:NNN` console lines.** Every build prints two or
   three of these. They come from upstream latex-lab's float tagging, not from
   this template (no such string exists anywhere in the source), they go to
   the console rather than the log, and they indicate nothing wrong. Ignore
   them.
8. **`check-compliance-Windows.bat` needs Python 3 and veraPDF**;
   `util/build.ps1` needs neither. The script fails loudly rather than
   silently skipping a check when Python is absent, and says so plainly when
   veraPDF is.
