"""Generate Linux PNG tray variants. Requires resvg-py==0.5.0."""

from pathlib import Path
import resvg_py

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets_source/images/icon/windows'
OUTPUT = ROOT / 'assets/images/tray/unix'


def main():
    for state in range(1, 5):
        source = SOURCE / f'status_{state}.svg'
        for scale in range(1, 5):
            folder = OUTPUT if scale == 1 else OUTPUT / f'{scale}.0x'
            folder.mkdir(parents=True, exist_ok=True)
            (folder / f'status_{state}.png').write_bytes(
                resvg_py.svg_to_bytes(svg_path=str(source), width=18*scale, height=18*scale)
            )


if __name__ == '__main__':
    main()
