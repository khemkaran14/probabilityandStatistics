"""Build web/privacy.html from docs/store/privacy-policy.md (one source).

Usage:  python3 tool/make_privacy.py
Supports the small Markdown subset the policy uses: #/## headings (with
optional {#anchor}), paragraphs, "- " lists, **bold**, `code` and <links>.
"""
import html
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "docs/store/privacy-policy.md"
OUT = ROOT / "web/privacy.html"


def inline(text):
    text = html.escape(text, quote=False)
    text = re.sub(r"&lt;(https?://[^&]+)&gt;", r'<a href="\1">\1</a>', text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"`(.+?)`", r"<code>\1</code>", text)
    return text


def heading(level, text):
    m = re.match(r"(.*?)\s*\{#([\w-]+)\}$", text)
    title, anchor = (m.group(1), m.group(2)) if m else (text, None)
    attr = f' id="{anchor}"' if anchor else ""
    return f"<h{level}{attr}>{inline(title)}</h{level}>"


def convert(md):
    out = []
    for block in re.split(r"\n\s*\n", md.strip()):
        lines = block.split("\n")
        if lines[0].startswith("## "):
            out.append(heading(2, lines[0][3:]))
            lines = lines[1:]
        elif lines[0].startswith("# "):
            out.append(heading(1, lines[0][2:]))
            lines = lines[1:]
        if not lines:
            continue
        # A block can start with a paragraph line followed by a list.
        para, items = [], []
        for line in lines:
            if line.startswith("- "):
                items.append(line[2:])
            elif items and line.startswith("  "):
                items[-1] += " " + line.strip()
            else:
                para.append(line.strip())
        if para:
            # Several short lines (like the header block) keep their breaks.
            if len(para) > 1 and all(len(p) < 70 for p in para):
                out.append("<p>" + "<br>\n".join(inline(p) for p in para) + "</p>")
            else:
                out.append("<p>" + inline(" ".join(para)) + "</p>")
        if items:
            out.append("<ul>\n" + "\n".join(f"<li>{inline(i)}</li>" for i in items) + "\n</ul>")
    return "\n".join(out)


PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Chance – Privacy Policy</title>
  <style>
    body {{ margin: 0; background: #FFF9F2; color: #1E1B3A; font: 16px/1.6 system-ui, sans-serif; }}
    main {{ max-width: 720px; margin: 0 auto; padding: 32px 16px 64px; }}
    h1 {{ color: #FF3D8B; line-height: 1.2; }}
    h2 {{ margin-top: 2em; color: #9B5CFF; }}
    a {{ color: #4C7DFF; }}
  </style>
</head>
<body>
<main>
{body}
</main>
</body>
</html>
"""

if __name__ == "__main__":
    OUT.write_text(PAGE.format(body=convert(SRC.read_text())))
    print(f"Wrote {OUT.relative_to(ROOT)}")
