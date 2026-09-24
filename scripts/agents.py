#!/usr/bin/env python3
"""Write a Markdown copy of every published page beside its HTML, and /llms.txt.

Runs after `zola build`. Reads content/**/*.md, strips the TOML front matter
and HTML comments, and writes public/<path>/index.md. Draft pages are skipped.
Content must not use shortcodes: they would leak into the copies unexpanded.
"""

import re
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"
PUBLIC = ROOT / "public"

# Site-map order and grouping for llms.txt. Anything not listed goes under "Other".
GROUPS = [
    ("Docs", ["/", "/install/", "/learn/", "/learn/getting-started/", "/learn/reference/", "/learn/examples/"]),
    ("Project", ["/tools/", "/design/", "/design/roadmap/", "/community/", "/blog/"]),
    ("Policies", ["/security/", "/license/"]),
]

FRONT_MATTER = re.compile(r"\A\+\+\+\n(.*?)\n\+\+\+\n", re.S)
HTML_COMMENT = re.compile(r"<!--.*?-->[ \t]*\n?", re.S)
SHORTCODE = re.compile(r"\{[{%]\s*\w+\(")


def page_url(md: Path) -> str:
    rel = md.relative_to(CONTENT)
    parts = list(rel.parent.parts)
    if rel.name != "_index.md":
        parts.append(rel.stem)
    return "/" + "".join(p + "/" for p in parts)


def main() -> int:
    config = tomllib.loads((ROOT / "config.toml").read_text())
    base = config["base_url"].rstrip("/")
    pages = {}
    for md in sorted(CONTENT.rglob("*.md")):
        text = md.read_text()
        m = FRONT_MATTER.match(text)
        if not m:
            print(f"agents.py: {md} has no front matter", file=sys.stderr)
            return 1
        fm = tomllib.loads(m.group(1))
        body = text[m.end():]
        if fm.get("draft"):
            continue
        if SHORTCODE.search(body):
            print(f"agents.py: {md} uses a shortcode; the Markdown copy would leak it", file=sys.stderr)
            return 1
        url = page_url(md)
        out_dir = PUBLIC / url.strip("/")
        if not (out_dir / "index.html").exists():
            print(f"agents.py: {md} was not built at {url}", file=sys.stderr)
            return 1
        body = HTML_COMMENT.sub("", body).strip()
        (out_dir / "index.md").write_text(f"# {fm['title']}\n\n{body}\n")
        pages[url] = (fm["title"], fm.get("description", ""))

    lines = [
        "# Varyk",
        "",
        f"> {config['description']}",
        "",
        "Varyk is pre-0.1: syntax, diagnostic codes, and command-line flags may change until a 0.1 release. "
        "Every page below is also available as Markdown at the linked address.",
        "",
    ]
    listed = set()
    for group, urls in GROUPS:
        entries = [u for u in urls if u in pages]
        if not entries:
            continue
        lines += [f"## {group}", ""]
        for u in entries:
            title, desc = pages[u]
            lines.append(f"- [{title}]({base}{u}index.md): {desc}")
            listed.add(u)
        lines.append("")
    rest = [u for u in pages if u not in listed]
    if rest:
        lines += ["## Other", ""]
        for u in sorted(rest):
            title, desc = pages[u]
            lines.append(f"- [{title}]({base}{u}index.md): {desc}")
        lines.append("")
    (PUBLIC / "llms.txt").write_text("\n".join(lines))
    print(f"agents.py: wrote {len(pages)} Markdown copies and llms.txt")
    return 0


if __name__ == "__main__":
    sys.exit(main())
