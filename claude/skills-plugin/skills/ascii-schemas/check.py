#!/usr/bin/env python3
"""Lint ASCII schemas: width, wide glyphs, tabs and box edges.

Reads a file (or stdin); checks every fenced block, or the whole text when
it has no fence. Exits 1 when it finds a problem.
"""

import argparse
import re
import sys
import unicodedata
from pathlib import Path

FENCE = re.compile(r"^```[^\n]*\n(.*?)^```", re.DOTALL | re.MULTILINE)
VERTICAL = set("│┃║├┤┼┝┥╞╡╪╟╢╫╠╣╬")
# A line may cross an edge instead of meeting it.
CROSSING = set("─━═►▶◄◀")
EDGE = VERTICAL | CROSSING
TOP = set("─━═┬╤╦")
FAMILIES = {"┌": ("┐", "└", "┘"), "╔": ("╗", "╚", "╝"), "╭": ("╮", "╰", "╯")}
RISKY = set("⚠✔✅❌✨🔔⭐")


def cells(line: str) -> list[str | None]:
    """One entry per terminal cell; a wide glyph's second cell is None."""
    out: list[str | None] = []
    for ch in line:
        if unicodedata.combining(ch) or ch == "️":
            continue
        out.append(ch)
        if unicodedata.east_asian_width(ch) in "WF":
            out.append(None)
    return out


def is_path(ch: str | None) -> bool:
    return ch is not None and ("\u2500" <= ch <= "\u257f" or ch in CROSSING)


def at(grid: list[list[str | None]], r: int, c: int) -> str | None:
    return grid[r][c] if r < len(grid) and c < len(grid[r]) else " "


def box_errors(grid: list[list[str | None]]) -> list[str]:
    errs = []
    for r, row in enumerate(grid):
        for c, ch in enumerate(row):
            if ch not in FAMILIES:
                continue
            tr, bl, br = FAMILIES[ch]
            # Fan-outs, branch connectors and plotted curves are not boxes.
            if (
                tr not in row[c + 1 :]
                or at(grid, r, c + 1) not in TOP
                or at(grid, r + 1, c) not in VERTICAL
            ):
                continue
            c2 = row.index(tr, c + 1)
            r2 = r + 1
            while r2 < len(grid) and at(grid, r2, c) in EDGE:
                r2 += 1
            if at(grid, r2, c) != bl:
                if is_path(at(grid, r2, c)):
                    continue  # the edge turns into a line elsewhere
                errs.append(
                    f"{r2 + 1}:{c + 1} left edge of the box at "
                    f"{r + 1}:{c + 1} breaks (found {at(grid, r2, c)!r})"
                )
                continue
            for rr in range(r + 1, r2):
                if at(grid, rr, c2) not in EDGE:
                    errs.append(
                        f"{rr + 1}:{c2 + 1} right edge of the box at "
                        f"{r + 1}:{c + 1} drifts "
                        f"(found {at(grid, rr, c2)!r})"
                    )
                    break
            else:
                if at(grid, r2, c2) != br:
                    errs.append(
                        f"{r2 + 1}:{c2 + 1} expected {br} closing the "
                        f"box at {r + 1}:{c + 1}"
                    )
    return errs


def check(block: str, width: int) -> list[str]:
    errs = []
    lines = block.splitlines()
    for n, line in enumerate(lines, 1):
        if "\t" in line:
            errs.append(f"{n}: tab; use spaces")
        wide = [ch for ch in line if unicodedata.east_asian_width(ch) in "WF"]
        risky = [ch for ch in line if ch in RISKY or ch == "️"]
        if wide or risky:
            glyphs = "".join(dict.fromkeys(wide + risky))
            errs.append(f"{n}: wide or emoji glyph {glyphs!r} shifts columns")
        if len(cells(line)) > width:
            errs.append(f"{n}: {len(cells(line))} cols > {width}")
    return errs + box_errors([cells(line) for line in lines])


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("file", nargs="?", default="-")
    ap.add_argument("--width", type=int, default=100)
    args = ap.parse_args()
    if args.file == "-":
        text = sys.stdin.read()
    else:
        text = Path(args.file).read_text()
    blocks = FENCE.findall(text) or [text]
    bad = 0
    for i, block in enumerate(blocks, 1):
        for err in check(block, args.width):
            bad += 1
            print(f"block {i}, line {err}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
