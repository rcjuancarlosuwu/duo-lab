#!/usr/bin/env python3
"""Render findings/iphone-duo-flutter.md to a self-contained HTML with base64 images.

    uvx --from markdown python render.py
"""
import base64
import pathlib
import re

import markdown

ROOT = pathlib.Path(__file__).parent / "findings"
SRC = ROOT / "iphone-duo-flutter.md"
OUT = ROOT / "iphone-duo-flutter.html"

CSS = """body{max-width:720px;margin:0 auto;padding:56px 24px;font:17.5px/1.7 -apple-system,BlinkMacSystemFont,Georgia,serif;color:#1c1c1c}
h1{font-size:2.2em;line-height:1.15;margin:0 0 .5em;letter-spacing:-.02em}
h2{font-size:1.45em;margin:2.2em 0 .6em;letter-spacing:-.01em}
h3{font-size:1.1em;margin:1.8em 0 .4em}
table{border-collapse:collapse;width:100%;margin:1.4em 0;font-size:.88em;font-family:-apple-system,sans-serif}
th,td{border-bottom:1px solid #e3e3e3;padding:9px 10px;text-align:left}th{background:#fafafa;border-bottom:2px solid #ddd}
code{background:#f2f2f2;padding:1px 5px;border-radius:3px;font-size:.85em;font-family:ui-monospace,Menlo,monospace}
pre{background:#f7f8fa;padding:16px;border-radius:6px;overflow-x:auto;border:1px solid #eee}pre code{background:none;padding:0;font-size:.82em}
figure{margin:2em 0 .6em}img{max-width:100%;border:1px solid #e0e0e0;border-radius:8px;display:block}
p.cap{font-size:.88em;color:#666;margin:-.2em 0 2em;font-family:-apple-system,sans-serif}
blockquote{border-left:3px solid #ccc;margin:1.4em 0;padding:.2em 1.2em;color:#444;font-style:italic}
hr{border:0;border-top:1px solid #e8e8e8;margin:2.8em 0}a{color:#0b66c3}
ul,ol{padding-left:1.4em}li{margin:.4em 0}"""


def embed(match):
    attrs = match.group(1)
    src = re.search(r'src="([^"]+)"', attrs).group(1)
    alt = re.search(r'alt="([^"]*)"', attrs)
    data = base64.b64encode((ROOT / src).read_bytes()).decode()
    return (
        f'<figure><img alt="{alt.group(1) if alt else ""}" '
        f'src="data:image/png;base64,{data}"></figure>'
    )


html = markdown.markdown(
    SRC.read_text(encoding="utf-8"),
    extensions=["tables", "fenced_code", "sane_lists"],
)
html = re.sub(r"<p>(<img\b[^>]*?)\s*/?>\s*</p>", lambda m: embed(m), html)
html = re.sub(r"<p><em>(.*?)</em></p>", r'<p class="cap">\1</p>', html, flags=re.S)

OUT.write_text(
    f'<!doctype html><meta charset="utf-8">'
    f"<title>iPhone Duo and Flutter</title><style>{CSS}</style>\n{html}\n",
    encoding="utf-8",
)
print(f"{OUT}  {OUT.stat().st_size/1_048_576:.2f} MB")
