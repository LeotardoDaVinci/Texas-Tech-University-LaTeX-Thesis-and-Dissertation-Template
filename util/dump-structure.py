"""Dump a tagged PDF's structure tree as readable text.

Usage:  python dump-structure.py <file.pdf>

Prints an indented outline of /StructTreeRoot, a tag-name histogram, every
/Alt and /ActualText string decoded, and a machine-readable ALT SUMMARY line
that the compliance-check scripts assert on. Requires Python 3; no
third-party packages.
"""
import re
import sys
from collections import Counter

path = sys.argv[1]
data = open(path, 'rb').read()

# collect all objects "N 0 obj ... endobj"
objs = {}
for m in re.finditer(rb'(\d+)\s+0\s+obj\b(.*?)\bendobj', data, re.S):
    objs[int(m.group(1))] = m.group(2)


def find_root():
    for n, b in objs.items():
        m = re.search(rb'/StructTreeRoot\s+(\d+)\s+0\s+R', b)
        if m:
            return int(m.group(1))
    return None


root = find_root()
print("StructTreeRoot object:", root)


def kids_of(body):
    m = re.search(rb'/K\s*(.*)', body, re.S)
    if not m:
        return []
    rest = m.group(1).lstrip()
    if rest.startswith(b'['):
        depth = 0
        seg = rest
        for i, c in enumerate(rest):
            if c == ord('['):
                depth += 1
            elif c == ord(']'):
                depth -= 1
                if depth == 0:
                    seg = rest[:i + 1]
                    break
    else:
        seg = rest[:200]
    return [int(x) for x in re.findall(rb'(\d+)\s+0\s+R', seg)]


def decode_pdf_string(raw):
    """Decode a PDF string token -- literal (...) or hex <...>.

    LaTeX writes /Alt as a UTF-16BE hex string with a byte-order mark, e.g.
    /Alt <FEFF0041...>, which an earlier version of this script did not match
    at all; the /Alt section of every dump came out empty even though the alt
    text was present and correct.
    """
    if raw.startswith(b'<'):
        hexdigits = re.sub(rb'[^0-9A-Fa-f]', b'', raw[1:-1])
        if len(hexdigits) % 2:
            hexdigits += b'0'
        b = bytes.fromhex(hexdigits.decode('ascii'))
        if b[:2] in (b'\xfe\xff',):
            return b[2:].decode('utf-16-be', 'replace')
        if b[:2] in (b'\xff\xfe',):
            return b[2:].decode('utf-16-le', 'replace')
        return b.decode('utf-8', 'replace')
    # literal string: unescape the backslash pairs LaTeX actually emits
    s = raw[1:-1]
    s = re.sub(rb'\\([()\\])', rb'\1', s)
    return s.decode('utf-8', 'replace')


# a PDF string (either form) or a name
STRING_OR_NAME = (rb'(\((?:[^()\\]|\\.)*\)|<[0-9A-Fa-f\s]*>|/[A-Za-z0-9.\-_]+)')


def field(body, key):
    m = re.search(key.encode() + rb'\s*' + STRING_OR_NAME, body)
    if not m:
        return None
    raw = m.group(1)
    if raw.startswith(b'/'):
        return raw[1:].decode('latin-1')
    return decode_pdf_string(raw)


seen = set()
lines = []
figures = []          # (obj number, alt or None)


def walk(num, depth):
    if num in seen or depth > 25:
        return
    seen.add(num)
    body = objs.get(num, b'')
    if b'/StructElem' not in body and depth > 0 and b'/S' not in body:
        return
    s = field(body, '/S')
    if s is None and depth > 0:
        return
    alt = field(body, '/Alt')
    actual = field(body, '/ActualText')
    label = '  ' * depth + (s or 'ROOT') + f'  (obj {num})'
    if alt:
        label += f'  /Alt="{alt}"'
    if actual:
        label += f'  /ActualText="{actual}"'
    lines.append(label)
    if s == 'Figure':
        figures.append((num, alt))
    for k in kids_of(body):
        walk(k, depth + 1)


walk(root, 0)
print('\n'.join(lines))

print()
print("=== tag-name histogram ===")
c = Counter(re.findall(rb'/S\s*/([A-Za-z0-9.\-_]+)', data))
for k, v in sorted(c.items()):
    print(f"  {k.decode()}: {v}")

print()
print("=== /Alt and /ActualText entries in file ===")
n_alt = 0
for m in re.finditer(rb'/(Alt|ActualText)\s*' + STRING_OR_NAME, data):
    key = m.group(1).decode('ascii')
    raw = m.group(2)
    if raw.startswith(b'/'):
        continue
    n_alt += 1
    print(f"  /{key}: {decode_pdf_string(raw)}")
if n_alt == 0:
    print("  (none)")

def looks_like_filename(s):
    """True if the alt text is really just the graphic's file name.

    When \\includegraphics is given no alt= key, latex-lab falls back to the
    file name and writes THAT as /Alt. The figure therefore has an /Alt, and
    both veraPDF and a presence-only check are satisfied by it, even though a
    screen reader would read out "figures slash example dash Double dash T dot pdf".
    Only the tagpdf log warning catches this otherwise, so the dump flags it
    too.
    """
    t = s.strip()
    if re.search(r'\.(pdf|png|jpe?g|eps|svg|tiff?)$', t, re.I):
        return True
    # a bare path with no spaces is not a sentence
    return '/' in t and ' ' not in t


print()
print("=== Figure elements ===")
suspect = 0
for num, alt in figures:
    if not alt:
        state = 'NO /Alt'
    elif looks_like_filename(alt):
        state = f'SUSPECT /Alt is a file name: "{alt}"'
        suspect += 1
    else:
        state = 'ALT OK'
    print(f"  obj {num}: {state}")
if not figures:
    print("  (no /S /Figure elements in the tree)")

# Machine-readable line checked by the compliance scripts. Every /S /Figure must carry a
# non-empty /Alt that is not merely the file name; a decorative image should be
# an artifact and so should not appear as a Figure at all.
with_alt = sum(1 for _, a in figures if a and not looks_like_filename(a))
print()
print(f"ALT SUMMARY: figures={len(figures)} with_alt={with_alt} "
      f"suspect={suspect} alt_strings={n_alt}")
