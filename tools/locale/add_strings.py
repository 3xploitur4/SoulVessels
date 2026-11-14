"""Append translation keys to assets/locale/strings.csv (story 016+).

Usage: python add_strings.py strings.tsv     (one "KEY<TAB>English text" per line; existing keys are
updated in place, new keys appended). Run Godot's import afterwards to rebuild the .translation.
"""
import csv
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CSV = os.path.join(ROOT, "assets", "locale", "strings.csv")


def main(path):
    rows = list(csv.reader(open(CSV, encoding="utf-8")))
    index = {r[0]: i for i, r in enumerate(rows) if r}
    added = updated = 0
    for line in open(path, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line.strip() or line.startswith("#"):
            continue
        key, text = line.split("\t", 1)
        text = text.replace("\n", "\n")
        if key in index:
            if rows[index[key]][1] != text:
                rows[index[key]][1] = text
                updated += 1
        else:
            index[key] = len(rows)
            rows.append([key, text])
            added += 1
    with open(CSV, "w", encoding="utf-8", newline="") as f:
        csv.writer(f, lineterminator="\n").writerows(rows)
    print("strings: %d added, %d updated" % (added, updated))


if __name__ == "__main__":
    main(sys.argv[1])
