#!/usr/bin/env python3
"""Build a photo pair or contact sheet as one self-contained HTML page. Standard library only.

    python3 contact-sheet.py <out.html> [--title "Which do you prefer?"] [--columns 2] <photo> [<photo> ...]

Each <photo> is "label|caption|src": label is a short tag such as A or B (or empty), caption is the hotel's name
and place, and src is a file inside the current folder or an https URL a tool returned. The photos are embedded,
so the page opens anywhere: send it to the traveller as a file to view, or publish it as an artifact.
A photo that can't be fetched is left out and reported.
"""
import html
import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("build_page", os.path.join(HERE, "build-page.py"))
build_page = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build_page)

PAGE = """<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title}</title>
<style>
  :root {{ --ground: #f7f5f2; --ink: #1e2533; --muted: #5c6576; --accent: #14213d; --sand: #ddd4ca; }}
  @media (prefers-color-scheme: dark) {{ :root {{ --ground: #0d1320; --ink: #ece4dc; --muted: #a5aec0; --accent: #c3d1ea; --sand: #2a3447; color-scheme: dark; }} }}
  body {{ margin: 0; background: var(--ground); color: var(--ink); font-family: Georgia, "Times New Roman", serif; padding: 20px max(16px, env(safe-area-inset-left, 0px)); }}
  h1 {{ font-weight: 400; font-size: 1.3rem; letter-spacing: 0.08em; text-transform: uppercase; color: var(--accent); margin: 0 0 16px; }}
  .grid {{ display: grid; grid-template-columns: repeat({columns}, minmax(0, 1fr)); gap: 14px; max-width: 1200px; }}
  @media (max-width: 560px) {{ .grid {{ grid-template-columns: minmax(0, 1fr); }} }}
  figure {{ margin: 0; display: grid; gap: 6px; }}
  .ph {{ position: relative; aspect-ratio: 3 / 2; overflow: hidden; background: var(--sand); }}
  .ph img {{ position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; }}
  .tag {{ position: absolute; left: 10px; top: 10px; min-width: 34px; height: 34px; display: grid; place-items: center; padding: 0 8px; background: rgba(13,19,32,0.65); color: #f3ede6; font-size: 1.1rem; }}
  figcaption {{ font-size: 1rem; color: var(--muted); }}
</style></head><body>
{heading}<div class="grid">
{figures}
</div></body></html>
"""


def main():
    args = sys.argv[1:]
    if not args or args[0].startswith("-"):
        sys.exit(__doc__)
    out, args = args[0], args[1:]
    title, columns, items = "", 0, []
    while args:
        a = args.pop(0)
        if a == "--title":
            title = args.pop(0)
        elif a == "--columns":
            columns = int(args.pop(0))
        else:
            items.append(a)
    if not items:
        sys.exit("Give at least one photo as label|caption|src.")
    figures, failures = [], []
    for item in items:
        label, caption, src = (item.split("|", 2) + ["", ""])[:3] if item.count("|") >= 2 else ("", "", item)
        try:
            data = build_page.fetch(src, os.getcwd())
        except Exception as e:
            failures.append("%s (%s)" % (src, e))
            continue
        tag = '<span class="tag">%s</span>' % html.escape(label) if label else ""
        figures.append('<figure><div class="ph"><img src="%s" alt="%s">%s</div><figcaption>%s</figcaption></figure>'
                       % (data, html.escape(caption, quote=True), tag, html.escape(caption)))
    if not figures:
        sys.exit("No photo could be fetched: " + "; ".join(failures))
    columns = columns or (2 if len(figures) <= 2 else 3 if len(figures) in (3, 6, 9) else 4)
    heading = "<h1>%s</h1>\n" % html.escape(title) if title else ""
    page = PAGE.format(title=html.escape(title or "Photos"), columns=columns, heading=heading, figures="\n".join(figures))
    with open(out, "w", encoding="utf-8") as f:
        f.write(page)
    print("Wrote %s (%d photos, %.1f MB)" % (out, len(figures), len(page.encode()) / 1048576))
    for failure in failures:
        print("Photo left out: " + failure)


if __name__ == "__main__":
    main()
