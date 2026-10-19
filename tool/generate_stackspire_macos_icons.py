"""Generate macOS app and template menu bar icons. Requires resvg-py==0.5.0."""

from pathlib import Path
import resvg_py

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets_source/images/icon/macos'
APP = ROOT / 'macos/Runner/Assets.xcassets/AppIcon.appiconset'
TRAY = ROOT / 'assets/images/tray/macos'


def main():
    app = SOURCE / 'app.svg'
    for size in (16, 32, 64, 128, 256, 512, 1024):
        (APP / f'app_icon_{size}.png').write_bytes(
            resvg_py.svg_to_bytes(svg_path=str(app), width=size, height=size)
        )
    for state in (1, 4):
        for scale in (1, 2, 3, 4):
            folder = TRAY if scale == 1 else TRAY / f'{scale}.0x'
            folder.mkdir(parents=True, exist_ok=True)
            (folder / f'status_{state}.png').write_bytes(
                resvg_py.svg_to_bytes(svg_path=str(SOURCE / f'status_{state}.svg'), width=18*scale, height=18*scale)
            )


if __name__ == '__main__':
    main()
