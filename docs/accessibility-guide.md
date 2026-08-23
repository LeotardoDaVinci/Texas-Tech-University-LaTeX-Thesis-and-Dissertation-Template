# Accessibility Guide

Everything in this guide is about one thing: making the PDF readable by
someone who is not reading it with their eyes. Texas Tech requires WCAG 2.1
Level AA compliance and a passing accessibility check for every thesis and
dissertation submitted from Spring 2026 (manual pp.7, 15).

You do not need to understand any of this to use the template correctly. The
three rules in the README cover the day-to-day work. Read this when you want to
know *why*, or when you hit something the sample chapter does not show.

---

## 1. What a tagged PDF is, and why it matters

An ordinary PDF is a page of positioned glyphs. It knows where the ink is; it
does not know that one line is a chapter title and the next is a paragraph. A
screen reader given such a file can only guess, and it usually guesses by
reading top-to-bottom, left-to-right, which turns a two-column page or a table
into nonsense.

A tagged PDF carries a second, invisible document alongside the ink: a tree
of elements (`Document > Sect > H1 > P > Table > TR > TH`) that says what
each piece of content *is* and what order it should be read in. That tree is
what assistive technology actually consumes. It is also what a compliance
checker inspects.

This template produces that tree automatically. You get it by writing normal
LaTeX: `\chapter`, `\section`, `\begin{table}`, `\caption`. You lose it by
faking structure: bolding a line instead of using `\section`, or pasting a
screenshot instead of typing a table.

## 2. Heading hierarchy

Headings are the primary way a screen-reader user navigates. They can jump
heading to heading the way a sighted reader skims. That only works if the
levels are a real hierarchy with no gaps.

| You write | Tagged as | Numbered |
|---|---|---|
| `\chapter{...}` | `H1` | CHAPTER I |
| `\section{...}` | `H2` | 1.1 |
| `\subsection{...}` | `H3` | 1.1.1 |
| `\subsubsection{...}` | `H4` | unnumbered |
| `\paragraph{...}` | `H5` | unnumbered |
| `\subparagraph{...}` | `H6` | unnumbered, run-in |

With `structure = {sections}` in the config the whole table shifts up one row:
`\section` is the `H1`, `\subsection` the `H2`, and so on down to
`\subparagraph` as the `H5`. The mapping is derived from the heading level, so
it moves with the switch and there is still no gap anywhere in the hierarchy.

Two rules follow:

- **Never skip a level.** Do not put a `\subsection` directly inside a
  `\chapter` with no `\section` between them.
- **Never use a heading for emphasis.** If you want a bold phrase, write
  `\textbf{...}`. A heading that is not a heading breaks navigation.

## 3. Alt text, captions, actual text, artifacts

These four are different things and are not interchangeable.

**`alt={...}`: what the image shows.** Required on every informative figure.
The manual asks for one to two sentences (p.23). Describe the content and
what it demonstrates, not the file:

```latex
\includegraphics[width=3.5in,
  alt={Line plot of response against control variable, showing a steep
       initial rise that flattens into a plateau above a control value
       of about three.}]{figures/result.pdf}
```

Bad alt text: `alt={Figure 1}`, `alt={plot.pdf}`, `alt={A graph}`. None of
those tells the reader anything the caption did not already say.

**`\caption{...}`: the printed title.** Everyone sees it, sighted or not. It
is not a substitute for alt text: the caption says what the figure *is*, the
alt text says what it *shows*. Write both, and do not repeat one in the other.

**`actualtext={...}`: the characters the image stands for.** Only for an image
that *is* text or a symbol: a scanned equation, a logogram, a special
character rendered as a picture. It replaces the image with those characters
for copy-paste and for the screen reader. Use `alt` for pictures; use
`actualtext` only when the image literally is a string.

**`artifact`: this carries no information.** Decorative rules, ornaments,
watermarks, a departmental logo used as decoration. It removes the image from
the reading order entirely, which is the correct outcome for decoration and a
serious error for anything else:

```latex
\includegraphics[width=2in,artifact]{figures/divider.pdf}
```

If you are unsure, ask: *if this image vanished, would the reader lose
anything?* If yes, it needs `alt`. If no, it is an `artifact`.

**Do not simply omit `alt`.** If you leave it out, LaTeX writes the *file
name* into the PDF as the alt text, so a screen reader announces
"figures slash results dash 3 dot pdf". The figure then looks fine to a
conformance checker while being useless to the person it exists for.
The compliance check catches this and fails.

Running headers, page numbers, dot leaders, and table rules are artifacted for
you automatically.

## 4. Tables

- **A real table, never a picture of one** (manual p.22). A screenshot cannot
  be read aloud, navigated cell by cell, searched, or reflowed.
- **The first row is the header row** and is tagged `TH` automatically by
  `\tagpdfsetup{table/header-rows={1}}`. Header cells are what let a screen
  reader announce "Pressure, kilopascals: 100" instead of just "100".
- **The caption goes above the table** (required), and the table must be
  mentioned in the text before it appears.
- **A table that runs past the page** must use `longtable`, so the header row
  repeats and the continuation is labelled. See the second table in
  `chapters/chapter-style-example.tex`.
- Keep the structure simple. Merged cells and nested headers are hard for
  assistive technology and are worth avoiding even where they are legal.

## 5. Mathematics

Write ordinary `amsmath`. Nothing else is required:

```latex
\begin{equation}
  y = \frac{a x}{b + x}
  \label{eq:saturation}
\end{equation}
```

Every formula is exported as **MathML** into the structure tree
(`Formula > math > mfrac > mrow > mi`), which assistive technology can read as
mathematics, navigating into a fraction and reading a subscript as a subscript.
You do **not** write alt text for equations in this template; the MathML
supersedes it, and that decision is recorded in the decision log.

What you should still do: refer to equations as `\eqref{eq:saturation}` rather
than "the equation above", and if a formula carries an argument that matters,
say in prose what it means.

## 6. Colour

Two independent requirements (manual pp.7–8, 16):

**Contrast.** Text needs a contrast ratio of at least **4.5:1** against its
background; meaningful parts of a figure need at least **3:1**. Body text is
black on white here (21:1), so the risk is entirely in your figures: pale
greys, yellow on white, light blue gridlines. Check figure colours with any
WCAG contrast checker before you export.

**Never colour alone.** If two curves differ only by being red and blue, a
reader with colour blindness, or anyone with a monochrome printout, cannot
tell them apart. Give every series a second cue: a different dash pattern, a
different marker, or a direct label on the line. The same goes for tables that
highlight cells by fill colour, and for "the red bars show…" in a caption.

If a figure cannot meet the contrast requirement (a photograph, a
micrograph, a false-colour map), the manual allows a long description in the
text before or after the figure, or in an appendix (pp.8, 16). Write it as
normal prose and reference it from the caption.

## 7. Links

Link text must say where it goes (manual pp.7, 16). Write the address, or a
descriptive phrase:

```latex
\url{https://www.depts.ttu.edu/gradschool/}
Details are in the \href{https://example.org/report}{2025 annual report}.
```

Never `\href{...}{click here}` or `\href{...}{this link}`. A screen-reader user
often pulls up a list of every link on the page; a list of eleven entries all
reading "click here" is useless. Internal cross-references (`\ref`, `\eqref`,
`\cite`) are already meaningful and are linked for you.

## 8. Running the check

From the template folder:

```powershell
.\build-Windows.bat            # build first: the check inspects the built PDF
.\check-compliance-Windows.bat
```

It runs four checks and prints one line each:

| Check | What it means |
|---|---|
| `veraPDF (ua2)` | Formal PDF/UA-2 conformance. `PASS` is what you submit on. On `FAIL` it lists the failing rules and writes the full report to `build\verapdf-report.xml`. |
| `pdftotext` | The text layer extracts. If this produced almost nothing, the PDF is images, not text. |
| `structure tree` | Writes `build\structure-dump.txt`, a readable outline of the tag tree. |
| `log` | Fails on tagpdf warnings, unresolved references, and over/underfull lines. |

The last line is `COMPLIANCE CHECK: all checks passed.` or a list of
problems. The
script exits non-zero on failure, so it can be wired into anything.

**veraPDF is a separate free download** (<https://verapdf.org/software/>). If
it is not installed the script says so and keeps running the other three
checks; it looks in `%USERPROFILE%\Tools\veraPDF`, `%LOCALAPPDATA%\veraPDF`,
`%ProgramFiles%\veraPDF`, and on your PATH.

What the check proves is *syntactic* conformance: every figure has some
alt text, every table has header cells, the reading order is well-formed. It
cannot tell you whether your alt text is any good. Nothing can, except reading
it.

## 9. Looking at the tags yourself

Two ways, in increasing order of effort:

**`build\structure-dump.txt`.** Produced by `check-compliance-Windows.bat`. A plain indented
outline of the tag tree, with each figure's `/Alt` text decoded, plus counts of
`TH`/`TD` cells and ToC entries. Fastest way to confirm a figure got its alt
text or a table got its header row.

**Adobe Acrobat.** Open the PDF, then:

- *View → Show/Hide → Navigation Panes → Tags* shows the live tag tree; expand
  it and click an element to highlight the content it covers.
- *View → Read Out Loud* reads the document in tag order. This is the quickest
  way to hear whether the reading order makes sense.
- *All tools → Prepare for accessibility → Check for accessibility* runs
  Acrobat's own checker. Note that Acrobat validates against PDF/UA-1; this
  document targets UA-2, so treat veraPDF as authoritative and Acrobat as a
  second opinion and a good manual-review tool.

## 10. Limitations you should know about

- **The checker cannot judge meaning.** Alt text that says "a graph" passes
  every automated test and helps nobody. Reading order can be formally valid
  and still make no sense. Read your own alt text back, and listen to a page or
  two with Read Out Loud.
- **Complex tables** with merged cells or two-level headers are legal but are
  handled poorly by much assistive technology. Prefer several simple tables.
- **No landscape pages.** An oversized table or figure must be split, scaled,
  or moved to an appendix.
- **Scanned material** (a signed form, a page from a published paper) is an
  image and can never be made fully accessible. Retype it, or supply the
  content as real text nearby.
- **The title page** is tagged as flat text rather than as a structured block.
  It passes the conformance check and loses no content, but it is the one
  part of the
  document with less structure than the rest.
