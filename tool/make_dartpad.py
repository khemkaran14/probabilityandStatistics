"""Bundle lib/ into one file that runs in DartPad (dartpad.dev).

Usage:  python3 tool/make_dartpad.py   (run from the project folder)
Writes: dartpad_preview.dart
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
STUBS = ROOT / "tool" / "dartpad_stubs"
# main.dart first so DartPad finds main(); the rest in a stable order.
files = [LIB / "main.dart"] + sorted(p for p in LIB.rglob("*.dart") if p.name != "main.dart")
# DartPad has no plugins: swap files that use them for in-memory stubs.
files = [STUBS / p.relative_to(LIB).name if (STUBS / p.relative_to(LIB).name).exists() else p for p in files]

imports, bodies = [], []
for path in files:
    lines = path.read_text().splitlines()
    body = []
    for line in lines:
        if re.match(r"^import\s+'package:chance/", line):
            continue  # local import: merged into this file
        if line.startswith("import "):
            if line not in imports:
                imports.append(line)
            continue
        body.append(line)
    label = path.relative_to(ROOT)
    bodies.append(f"// ===== {label} =====\n" + "\n".join(body).strip() + "\n")

header = "// Chance – single-file preview for DartPad. Generated; edit lib/ instead.\n\n"
out = header + "\n".join(sorted(imports)) + "\n\n" + "\n".join(bodies)
(ROOT / "dartpad_preview.dart").write_text(out)
print(f"Wrote dartpad_preview.dart ({len(out.splitlines())} lines from {len(files)} files)")
