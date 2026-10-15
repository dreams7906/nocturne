"""
Exports design assets straight from the Luau source, so they never drift:

  assets/icons/<name>.svg   every glyph in src/Nocturne/Icons/Icons.luau
  preview/dock.svg          the floating dock with the page icons
  preview/themes.svg        token swatches for every theme preset

Usage:  python tools/export_assets.py
"""

from __future__ import annotations

import pathlib
import re
import math

ROOT = pathlib.Path(__file__).resolve().parent.parent
ICONS = ROOT / "src" / "Nocturne" / "Icons" / "Icons.luau"
PRESETS = ROOT / "src" / "Nocturne" / "Themes" / "Presets.luau"
DOCK = ["combat", "visuals", "world", "player", "utilities", "misc", "configs", "settings"]


def parse_glyphs() -> dict[str, list]:
    source = ICONS.read_text(encoding="utf-8").replace("\r\n", "\n")
    body = source.split("Icons.Glyphs = {", 1)[1].split("\n}\n", 1)[0]
    glyphs: dict[str, list] = {}
    current = None
    stack: list[list] = []
    for line in body.splitlines():
        line = line.strip()
        name = re.match(r"^(\w+) = \{$", line)
        if name:
            current = []
            glyphs[name.group(1)] = current
            stack = [current]
            continue
        shape = re.match(r'^\{"(\w+)",\s*([-\d., ]+?)(,\s*\{)?\}?,?$', line)
        if shape and stack:
            kind = shape.group(1)
            numbers = [float(n) for n in shape.group(2).split(",") if n.strip()]
            if kind == "clip":
                children: list = []
                stack[-1].append(("clip", numbers, children))
                stack.append(children)
            else:
                stack[-1].append((kind, numbers))
            continue
        if line.startswith("}}") and len(stack) > 1:
            stack.pop()
    return glyphs


def shape_svg(shape, color: str, width: float, clip_id: list[int]) -> str:
    kind = shape[0]
    n = shape[1]
    stroke = f'fill="none" stroke="{color}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"'
    if kind == "line":
        return f'<line x1="{n[0]}" y1="{n[1]}" x2="{n[2]}" y2="{n[3]}" {stroke}/>'
    if kind == "arc":
        cx, cy, radius, start, end = n
        x1, y1 = cx + math.cos(math.radians(start)) * radius, cy + math.sin(math.radians(start)) * radius
        x2, y2 = cx + math.cos(math.radians(end)) * radius, cy + math.sin(math.radians(end)) * radius
        large = 1 if abs(end - start) > 180 else 0
        return f'<path d="M {x1} {y1} A {radius} {radius} 0 {large} 1 {x2} {y2}" {stroke}/>'
    if kind == "ring":
        return f'<circle cx="{n[0]}" cy="{n[1]}" r="{n[2]}" {stroke}/>'
    if kind == "dot":
        return f'<circle cx="{n[0]}" cy="{n[1]}" r="{n[2]}" fill="{color}"/>'
    if kind == "rect":
        radius = n[4] if len(n) > 4 else 0
        return f'<rect x="{n[0]}" y="{n[1]}" width="{n[2]}" height="{n[3]}" rx="{radius}" {stroke}/>'
    if kind == "clip":
        clip_id[0] += 1
        cid = f"c{clip_id[0]}"
        inner = "".join(shape_svg(child, color, width, clip_id) for child in shape[2])
        return (
            f'<clipPath id="{cid}"><rect x="{n[0]}" y="{n[1]}" width="{n[2]}" height="{n[3]}"/></clipPath>'
            f'<g clip-path="url(#{cid})">{inner}</g>'
        )
    return ""


def glyph_svg(shapes, color="#ECEDF1", width=1.5, size=18, standalone=True, offset=(0, 0), prefix="") -> str:
    clip_id = [0]
    inner = "".join(shape_svg(s, color, width, clip_id) for s in shapes)
    if prefix:
        inner = inner.replace('id="c', f'id="{prefix}c').replace("url(#c", f"url(#{prefix}c")
    if standalone:
        return f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 18 18">{inner}</svg>\n'
    return f'<g transform="translate({offset[0]} {offset[1]})">{inner}</g>'


def parse_presets() -> dict[str, dict[str, str]]:
    source = PRESETS.read_text(encoding="utf-8").replace("\r\n", "\n")
    themes: dict[str, dict[str, str]] = {}
    for match in re.finditer(r'\n\t(?:\["([^"]+)"\]|(\w+)) = \{\n(.*?)\n\t\},', source, re.S):
        name = match.group(1) or match.group(2)
        tokens = dict(re.findall(r'(\w+) = hex\("([0-9A-Fa-f]{6})"\)', match.group(3)))
        if tokens:
            themes[name] = {k: "#" + v for k, v in tokens.items()}
    return themes


def dock_svg(glyphs, theme) -> str:
    button, gap, pad = 34, 7, 10
    width = pad * 2 + len(DOCK) * button + (len(DOCK) - 1) * gap
    height = button + pad * 2
    margin = 24
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width + margin * 2}" height="{height + margin * 2 + 26}" '
        f'viewBox="0 0 {width + margin * 2} {height + margin * 2 + 26}">',
        "<defs>",
        '<linearGradient id="gloss" x1="0" y1="0" x2="0" y2="1">'
        '<stop offset="0" stop-color="#fff" stop-opacity="0.07"/><stop offset="1" stop-color="#000" stop-opacity="0.12"/></linearGradient>',
        '<linearGradient id="edge" x1="0" y1="0" x2="0" y2="1">'
        f'<stop offset="0" stop-color="{theme["BorderStrong"]}"/><stop offset="1" stop-color="{theme["Border"]}"/></linearGradient>',
        '<filter id="shadow" x="-20%" y="-50%" width="140%" height="220%"><feDropShadow dx="0" dy="4" stdDeviation="4" flood-opacity="0.15"/></filter>',
        "</defs>",
        f'<rect width="100%" height="100%" fill="#3a3d45"/>',
        f'<g transform="translate({margin} {margin})">',
        f'<rect width="{width}" height="{height}" rx="15" fill="{theme["Backdrop"]}" fill-opacity="0.9" filter="url(#shadow)"/>',
        f'<rect width="{width}" height="{height}" rx="15" fill="url(#gloss)"/>',
        f'<rect x="0.5" y="0.5" width="{width - 1}" height="{height - 1}" rx="14.5" fill="none" stroke="url(#edge)"/>',
    ]
    active = 0
    ax = pad + active * (button + gap)
    parts.append(f'<rect x="{ax}" y="{pad}" width="{button}" height="{button}" rx="10" fill="{theme["Hover"]}" fill-opacity="0.3" stroke="{theme["BorderStrong"]}" stroke-opacity="0.15"/>')
    parts.append(f'<circle cx="{ax + button / 2}" cy="{pad + button - 2}" r="1.5" fill="{theme["Text"]}"/>')
    for index, name in enumerate(DOCK):
        x = pad + index * (button + gap) + (button - 18) / 2
        y = pad + (button - 18) / 2 - (1.5 if index == active else 0)
        color = theme["Text"] if index == active else theme["TextMuted"]
        parts.append(glyph_svg(glyphs[name], color=color, standalone=False, offset=(x, y), prefix=f"d{index}"))
    hint_x = ax + button / 2
    parts.append(f'<rect x="{hint_x - 26}" y="{height + 10}" width="52" height="20" rx="6" fill="{theme["Elevated"]}" stroke="{theme["BorderStrong"]}"/>')
    parts.append(
        f'<text x="{hint_x}" y="{height + 24}" text-anchor="middle" font-family="Segoe UI, Arial" font-size="11" '
        f'font-weight="600" fill="{theme["TextDim"]}">Combat</text>'
    )
    parts.append("</g></svg>\n")
    return "".join(parts)


def themes_svg(themes) -> str:
    keys = ["Backdrop", "Surface", "Surface2", "Hover", "BorderStrong", "TextMuted", "TextDim", "Text", "Accent"]
    cell, label = 34, 120
    width = label + len(keys) * (cell + 6) + 20
    height = 40 + len(themes) * (cell + 10) + 10
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        f'<rect width="100%" height="100%" fill="#101114"/>',
    ]
    for col, key in enumerate(keys):
        parts.append(
            f'<text x="{label + col * (cell + 6) + cell / 2}" y="26" text-anchor="middle" font-family="Segoe UI, Arial" '
            f'font-size="8.5" fill="#8a8d96">{key}</text>'
        )
    for row, (name, tokens) in enumerate(themes.items()):
        y = 40 + row * (cell + 10)
        parts.append(
            f'<text x="14" y="{y + cell / 2 + 4}" font-family="Segoe UI, Arial" font-size="13" font-weight="600" fill="#e6e7ea">{name}</text>'
        )
        for col, key in enumerate(keys):
            x = label + col * (cell + 6)
            parts.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" rx="7" fill="{tokens[key]}" stroke="#ffffff" stroke-opacity="0.08"/>')
    parts.append("</svg>\n")
    return "".join(parts)


def main() -> None:
    glyphs = parse_glyphs()
    themes = parse_presets()
    icon_dir = ROOT / "assets" / "icons"
    icon_dir.mkdir(parents=True, exist_ok=True)
    for name, shapes in glyphs.items():
        (icon_dir / f"{name}.svg").write_text(glyph_svg(shapes), encoding="utf-8")
    preview = ROOT / "preview"
    preview.mkdir(exist_ok=True)
    (preview / "dock.svg").write_text(dock_svg(glyphs, themes["Midnight"]), encoding="utf-8")
    (preview / "themes.svg").write_text(themes_svg(themes), encoding="utf-8")
    print(f"{len(glyphs)} icons, {len(themes)} themes exported")


if __name__ == "__main__":
    main()
