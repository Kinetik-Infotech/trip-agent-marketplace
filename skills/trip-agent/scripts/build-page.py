#!/usr/bin/env python3
"""Build a Trip Agent page from a template and a JSON data file.

    python3 build-page.py <template.html> <data.json> <out.html>

The data file's photos ("photos": [{"src": ..., "caption": ...}]) are embedded in
the page as data URIs, because a published artifact cannot load images from
other sites. "src" is a local file (relative to the data file) or an https URL
that a tool returned. The data is written into the template's
<script type="application/json" id="data"> block. Standard library only.
"""
import base64
import json
import os
import re
import sys
import urllib.parse
import urllib.request

MAX_PAGE_BYTES = 15 * 1024 * 1024


IMAGE_MAGIC = {b"\xff\xd8\xff": "image/jpeg", b"\x89PNG": "image/png", b"GIF8": "image/gif", b"RIFF": "image/webp"}


def sniff(data):
    for magic, mime in IMAGE_MAGIC.items():
        if data.startswith(magic):
            if mime == "image/webp" and data[8:12] != b"WEBP":
                continue
            return mime
    raise ValueError("not an image")


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        if not newurl.startswith("https://"):
            raise ValueError("redirect away from https")
        if not public_host(urllib.parse.urlparse(newurl).hostname or ""):
            raise ValueError("redirect to a non-public host")
        return urllib.request.HTTPRedirectHandler.redirect_request(self, req, fp, code, msg, headers, newurl)


def public_host(host):
    import ipaddress
    import socket
    for info in socket.getaddrinfo(host, 443):
        ip = ipaddress.ip_address(info[4][0])
        if ip.is_private or ip.is_loopback or ip.is_link_local or ip.is_reserved or ip.is_multicast:
            return False
    return True


def fetch(src, base):
    """Photos come from an https URL a tool returned, or a file inside the data file's folder."""
    if src.startswith("https://"):
        host = urllib.parse.urlparse(src).hostname or ""
        if not public_host(host):
            raise ValueError("not a public host")
        opener = urllib.request.build_opener(NoRedirect)
        req = urllib.request.Request(src, headers={"User-Agent": "Mozilla/5.0 (Trip Agent page builder)"})
        with opener.open(req, timeout=30) as r:
            data = r.read(8 * 1024 * 1024)
    elif re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", src) or os.path.isabs(src):
        raise ValueError("only https URLs or files in the trip folder")
    else:
        root = os.path.realpath(base)
        path = os.path.realpath(os.path.join(root, src))
        if os.path.commonpath([root, path]) != root:
            raise ValueError("outside the trip folder")
        with open(path, "rb") as f:
            data = f.read()
    return "data:%s;base64,%s" % (sniff(data), base64.b64encode(data).decode("ascii"))


def safe_links(node):
    """Drop any link that isn't http or https, so a page can't carry a script link."""
    if isinstance(node, dict):
        for key in ("href",):
            if key in node and not re.match(r"^https?://", str(node[key])):
                node.pop(key)
        for value in node.values():
            safe_links(value)
    elif isinstance(node, list):
        for item in node:
            safe_links(item)


def embed(node, base, failures):
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "photos" and isinstance(value, list):
                kept = []
                for photo in value:
                    src = photo.get("src", "")
                    if src.startswith("data:"):
                        kept.append(photo)
                        continue
                    try:
                        photo["src"] = fetch(src, base)
                        kept.append(photo)
                    except Exception as e:  # a photo that fails is left out and reported
                        failures.append("%s (%s)" % (src, e))
                node[key] = kept
            else:
                embed(value, base, failures)
    elif isinstance(node, list):
        for item in node:
            embed(item, base, failures)


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    template_path, data_path, out_path = sys.argv[1:]
    with open(template_path, encoding="utf-8") as f:
        template = f.read()
    with open(data_path, encoding="utf-8") as f:
        data = json.load(f)
    failures = []
    safe_links(data)
    embed(data, os.path.dirname(os.path.abspath(data_path)), failures)
    payload = json.dumps(data, ensure_ascii=False).replace("</", "<\\/")
    pattern = r'(<script type="application/json" id="data">).*?(</script>)'
    if not re.search(pattern, template, flags=re.S):
        sys.exit("The template has no <script type=\"application/json\" id=\"data\"> block.")
    page = re.sub(pattern, lambda m: m.group(1) + payload + m.group(2), template, count=1, flags=re.S)
    size = len(page.encode("utf-8"))
    if size > MAX_PAGE_BYTES:
        sys.exit("The page is %.1f MB, over the 15 MB limit. Use fewer or smaller photos." % (size / 1048576))
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(page)
    print("Wrote %s (%.1f MB)" % (out_path, size / 1048576))
    for failure in failures:
        print("Photo left out: " + failure)


if __name__ == "__main__":
    main()
