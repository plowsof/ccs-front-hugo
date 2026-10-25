#!/usr/bin/env python3
# hidden-classes.py [--check]: the classes the site's stylesheets hide something with, one a line,
# into static/assets/hidden-classes.txt (in every release zip, so the web server's gate can read
# a page as a visitor sees it: ccs-bash, contrib/ccs-receive). A class counts when a rule hides
# the element it ends its selector on (display: none, visibility: hidden, opacity: 0, a 1px or
# 0 box, clip, font-size: 0, transparent text, a negative text-indent, scale(0)), whatever the
# rule's context, media query or state: the gate counts each element of such a class as maybe
# hidden, maybe not. Run it after changing a stylesheet and commit what it writes; --check fails
# if the committed file is out of date (CI). Python's standard library only.
import pathlib
import re
import sys

repo = pathlib.Path(__file__).resolve().parent.parent
sheets = sorted((repo / "assets" / "assets").glob("*.css"))
out = repo / "static" / "assets" / "hidden-classes.txt"

hides = re.compile(
    r"(?:^|;)\s*(?:"
    r"display\s*:\s*none"
    r"|visibility\s*:\s*(?:hidden|collapse)"
    r"|opacity\s*:\s*0*\.?0+\s*(?:!important\s*)?(?:;|$)"
    r"|(?:width|height|max-width|max-height)\s*:\s*(?:0|1px)\s*(?:!important\s*)?(?:;|$)"
    r"|clip(?:-path)?\s*:"
    r"|font-size\s*:\s*0\s*(?:!important\s*)?(?:;|$)"
    r"|color\s*:\s*transparent"
    r"|text-indent\s*:\s*-"
    r"|transform\s*:[^;]*scale\(\s*0\s*\)"
    r")",
    re.I,
)


def subject_classes(selector):
    """The classes of the selector's last compound (the element it styles), not those in :not()."""
    selector = re.sub(r":not\((?:[^()]|\([^()]*\))*\)", "", selector)
    selector = re.sub(r"::?[A-Za-z-]+(?:\([^()]*\))?", "", selector)
    last = re.split(r"\s*[>+~]\s*|\s+", selector.strip())[-1]
    return re.findall(r"\.(-?[_A-Za-z][_A-Za-z0-9-]*)", last)


def hidden(css):
    css = re.sub(r"/\*.*?\*/", "", css, flags=re.S)
    css = re.sub(r"\{\{.*?\}\}", "", css, flags=re.S)   # style.css is a Hugo template: its {{ }} aren't rules
    found = set()
    # innermost rules: a selector list and its declarations (media queries' bodies hold these)
    for m in re.finditer(r"([^{}]+)\{([^{}]*)\}", css):
        selectors, body = m.group(1), m.group(2)
        if selectors.strip().startswith("@") or not hides.search(body):
            continue
        for selector in selectors.split(","):
            found.update(subject_classes(selector))
    return found


classes = set()
for sheet in sheets:
    classes |= hidden(sheet.read_text())
text = "".join(c + "\n" for c in sorted(classes))

if sys.argv[1:] == ["--check"]:
    if not out.exists() or out.read_text() != text:
        sys.exit(f"{out.relative_to(repo)} is out of date: run tools/hidden-classes.py and commit it")
    print(f"{out.relative_to(repo)}: up to date ({len(classes)} classes)")
else:
    out.write_text(text)
    print(f"wrote {out.relative_to(repo)} ({len(classes)} classes)")
