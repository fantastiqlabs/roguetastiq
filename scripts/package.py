#!/usr/bin/env python3
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "Roguetastiq.toc"
ADDON = "Roguetastiq"

version = next(
    line.partition(":")[2].strip()
    for line in TOC.read_text().splitlines()
    if line.startswith("## Version:")
)
files = [
    TOC,
    ROOT / "RoguetastiqCatalog.lua",
    ROOT / "RoguetastiqShopping.lua",
    ROOT / "Roguetastiq.lua",
    ROOT / "RoguetastiqOptions.lua",
]
output = ROOT / "dist" / f"Roguetastiq_{version}.zip"
output.parent.mkdir(exist_ok=True)

with ZipFile(output, "w", ZIP_DEFLATED) as archive:
    for path in files:
        archive.write(path, f"{ADDON}/{path.name}")

print(output)
