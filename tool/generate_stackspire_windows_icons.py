"""Windows branding assets. Run with Python and `pip install resvg-py==0.5.0`.

The SVG is the source of truth. ICO entries are PNG-encoded at native shell sizes.
The general Dart generator also consumes these Windows-specific SVGs.
"""

from pathlib import Path
import struct

import resvg_py

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets_source/images/icon/windows'
APP_SIZES = (16, 20, 24, 32, 40, 48, 64, 96, 128, 256)
TRAY_SIZES = (16, 20, 24, 32, 40, 48, 64)


def write_ico(svg, output, sizes):
    images = [resvg_py.svg_to_bytes(svg_string=svg, width=s, height=s) for s in sizes]
    offset = 6 + 16 * len(sizes)
    directory = bytearray(struct.pack('<HHH', 0, 1, len(sizes)))
    for size, png in zip(sizes, images):
        dimension = size if size < 256 else 0
        directory.extend(struct.pack('<BBBBHHII', dimension, dimension, 0, 0,
                                     1, 32, len(png), offset))
        offset += len(png)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(directory + b''.join(images))


def main():
    app = (SOURCE / 'app.svg').read_text(encoding='utf-8')
    write_ico(app, ROOT / 'windows/runner/resources/app_icon.ico', APP_SIZES)
    # Tray: larger glyph than the launcher, and an explicit state color.
    tray = app.replace('viewBox="16 16 76 76"', 'viewBox="27 25 54 57"')
    tray = '\n'.join(line for line in tray.splitlines() if '<rect ' not in line)
    for state, first, second in (
        (1, '#9CA3AF', '#9CA3AF'),  # stopped
        (2, '#A9D4F5', '#A9D4F5'),  # system proxy
        (3, '#A9D4F5', '#A6E7C6'),  # TUN
        (4, '#F6C177', '#F6C177'),  # safe mode
    ):
        svg = tray.replace('#A9D4F5', first).replace('#A6E7C6', second)
        (SOURCE / f'status_{state}.svg').write_text(svg, encoding='utf-8')
        write_ico(svg, ROOT / f'assets/images/tray/windows/status_{state}.ico', TRAY_SIZES)
    preview = resvg_py.svg_to_bytes(svg_string=app, width=256, height=256)
    (ROOT / 'windows/runner/resources/stackspire-preview.png').write_bytes(preview)


if __name__ == '__main__':
    main()
