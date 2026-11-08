#!/usr/bin/env python3
"""Convert prices into the traveller's currency at the latest published rate.

    python3 fx.py <from> <to> <amount> [<amount> ...]
    python3 fx.py USD GBP 437 603

Rates are the European Central Bank's reference rates, from frankfurter.dev
(free, no key). Each line gives the converted price, the original, the rate
and the rate's date, so the traveller can see where the number came from.
If no rate can be fetched, it says so and exits with an error: then show no
converted price. Standard library only.
"""
import json
import sys
import urllib.request

SYMBOLS = {"GBP": "£", "USD": "US$", "EUR": "€", "AUD": "A$", "CAD": "C$", "JPY": "¥", "IDR": "Rp", "MXN": "MX$"}


def money(code, value):
    sign = SYMBOLS.get(code, code + " ")
    return "%s%s" % (sign, "{:,.0f}".format(value) if value >= 100 else "{:,.2f}".format(value))


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    src, dst = sys.argv[1].upper(), sys.argv[2].upper()
    try:
        amounts = [float(a.replace(",", "")) for a in sys.argv[3:]]
    except ValueError:
        sys.exit("Amounts must be numbers, such as 437 or 1,256.")
    url = "https://api.frankfurter.dev/v1/latest?base=%s&symbols=%s" % (src, dst)
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Trip Agent fx"})
        with urllib.request.urlopen(req, timeout=20) as r:
            data = json.load(r)
        rate = float(data["rates"][dst])
        day = data["date"]
    except Exception as e:
        sys.exit("No exchange rate available for %s to %s (%s). Don't show a converted price." % (src, dst, e))
    for a in amounts:
        print("%s (converted from %s at %s, ECB rate of %s)" % (money(dst, a * rate), money(src, a), "{:.4f}".format(rate), day))


if __name__ == "__main__":
    main()
