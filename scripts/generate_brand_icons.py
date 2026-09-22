"""Regenera los iconos de Finanza con herramientas incluidas en macOS."""

import json
import os
import subprocess
import tempfile
from pathlib import Path
from typing import Dict, Optional


ROOT = Path(__file__).resolve().parents[1]
ICONSET = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"


def run(*args: str, env: Optional[Dict[str, str]] = None) -> None:
    subprocess.run(args, check=True, stdout=subprocess.DEVNULL, env=env)


with tempfile.TemporaryDirectory(prefix="finanza-icons-") as temporary:
    temp = Path(temporary)
    env = dict(os.environ)
    env["SWIFT_MODULE_CACHE_PATH"] = str(temp / "swift-cache")
    env["CLANG_MODULE_CACHE_PATH"] = str(temp / "clang-cache")
    master = temp / "master.png"
    opaque = temp / "opaque.jpg"
    run("swift", str(ROOT / "scripts/generate_brand_icons.swift"), str(master), env=env)
    # iOS App Store rechaza iconos con canal alfa.
    run("sips", "-s", "format", "jpeg", "-s", "formatOptions", "best", str(master), "--out", str(opaque))

    def icon(path: Path, pixels: int) -> None:
        run("sips", "-s", "format", "png", "-z", str(pixels), str(pixels), str(opaque), "--out", str(path))

    for image in json.loads((ICONSET / "Contents.json").read_text())["images"]:
        size = round(float(image["size"].split("x")[0]) * int(image["scale"][0]))
        icon(ICONSET / image["filename"], size)

    for density, size in {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }.items():
        icon(ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png", size)
    icon(ROOT / "web/favicon.png", 64)
    for size in (192, 512):
        icon(ROOT / f"web/icons/Icon-{size}.png", size)
        icon(ROOT / f"web/icons/Icon-maskable-{size}.png", size)
    launch_set = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for name, scale in (("LaunchImage.png", 1), ("LaunchImage@2x.png", 2), ("LaunchImage@3x.png", 3)):
        icon(launch_set / name, 168 * scale)
