"""Arte vectorial provisional propio. Ejecutar con Python, sin dependencias."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "assets" / "placeholders"


def save(path, width, height, body):
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">{body}</svg>\n',
        encoding="utf-8",
    )


def character(zombie=False):
    frames = []
    for frame in range(12):
        phase = [0, 0.4, -1, 0, 1, 0, -0.3, 1, 0, 0, 0, 0][frame]
        death = max(0, frame - 7) / 4
        coat = "#78544b" if zombie else "#53756a"
        skin = "#9aa578" if zombie else "#cba98a"
        reach = 5 if zombie and frame in (6, 7) else 0
        body = f'<ellipse cx="32" cy="36" rx="20" ry="16" fill="#080f12" opacity=".45"/>'
        body += f'<g transform="translate(32 32) rotate({death * 82}) scale(1 {1 - death * .35}) translate(-32 -32)">'
        for x, leg in [(24, phase), (35, -phase)]:
            body += f'<rect x="{x}" y="{34 + leg * 4}" width="7" height="17" rx="3" fill="#202a2b" stroke="#111a1c" stroke-width="2"/>'
        body += f'<rect x="18" y="20" width="28" height="23" rx="9" fill="{coat}" stroke="#172426" stroke-width="2"/>'
        body += '<path d="M22 24L42 24M22 38L42 38" stroke="#a5b2a0" opacity=".35" stroke-width="2"/>'
        body += '<rect x="25" y="21" width="14" height="15" rx="3" fill="#293d3b"/>' if not zombie else '<path d="M23 24L38 39M40 23L28 38" stroke="#453836" stroke-width="3"/>'
        for x, swing in [(14, phase), (44, -phase)]:
            body += f'<rect x="{x}" y="{25 + swing * 2 + reach}" width="7" height="16" rx="3" fill="{coat}" stroke="#172426"/>'
            body += f'<circle cx="{x + 3.5}" cy="{40 + swing * 2 + reach}" r="4" fill="{skin}"/>'
        body += f'<ellipse cx="32" cy="23" rx="10" ry="10" fill="{skin}" stroke="#27332f" stroke-width="2"/>'
        if zombie:
            body += '<path d="M25 20L30 17L36 19" stroke="#454c35" stroke-width="4"/><path d="M26 26L30 27M35 27L39 26" stroke="#c36b54" stroke-width="2"/><path d="M30 31L35 30" stroke="#65483c" stroke-width="2"/>'
        else:
            body += '<path d="M22 22Q22 9 33 11Q43 12 42 23L38 22L37 17L25 17L26 23Z" fill="#283c3b"/><path d="M25 27H39" stroke="#1e3235" stroke-width="3"/><path d="M27 25H37" stroke="#9dd0ba" stroke-width="2"/>'
        body += '</g>'
        if frame >= 10:
            body += '<ellipse cx="32" cy="42" rx="18" ry="7" fill="#713e37" opacity=".45"/>'
        frames.append(f'<g transform="translate({frame * 64} 0)">{body}</g>')
    return ''.join(frames)


save("characters/player/temp_survivor_sheet.svg", 768, 64, character())
save("characters/zombies/temp_zombie_sheet.svg", 768, 64, character(True))
save("environment/tilesets/temp_asphalt.svg", 160, 160,
     '<rect width="160" height="160" fill="#293237"/><path d="M0 80H160M80 0V160" stroke="#313b3f" stroke-width="1"/>'
     '<path d="M8 21L29 25L35 38L51 43M110 126L122 109L145 105M5 149L21 133L18 119" fill="none" stroke="#1b252a" stroke-width="2"/>'
     + ''.join(f'<circle cx="{(i*47)%160}" cy="{(i*31+12)%160}" r="{1 if i%3 else 2}" fill="{["#475052", "#202a2e"][i%2]}" opacity=".45"/>' for i in range(65)))
save("environment/props/temp_supply_crate.svg", 128, 96,
     '<rect width="128" height="96" rx="3" fill="#182325"/><rect x="3" y="3" width="122" height="90" rx="2" fill="#596255" stroke="#87917b" stroke-width="2"/>'
     '<path d="M8 18H120M8 38H120M8 58H120M8 78H120" stroke="#333f38" stroke-width="3"/>'
     '<path d="M17 4V92M110 4V92" stroke="#242f2e" stroke-width="10"/><path d="M17 5V91M110 5V91" stroke="#919582" stroke-width="3"/>'
     '<rect x="44" y="30" width="40" height="34" fill="#d2bd83"/><path d="M61 36H67V43H74V49H67V56H61V49H54V43H61Z" fill="#4b5650"/>'
     '<path d="M28 15L40 23M87 68L99 79M30 85L38 78" stroke="#a9a187" stroke-width="2" opacity=".6"/>')
save("environment/decals/temp_debris.svg", 96, 64,
     '<path d="M8 35L21 28L36 35L24 47Z" fill="#716d58" opacity=".55"/><path d="M58 19L75 24L73 39L54 35Z" fill="#a2a18a" opacity=".4"/>'
     '<path d="M40 48L48 44M4 57L15 60M80 48L91 42M36 10L42 14" stroke="#111e21" stroke-width="3"/>')
save("weapons/temp_pistol.svg", 32, 16,
     '<path d="M2 4H29V10H12L10 15H4L6 9H2Z" fill="#182529" stroke="#0b1418"/><path d="M8 3H30V8H8Z" fill="#b3bbb0"/><path d="M15 4H26" stroke="#e5e5cc"/>')
save("effects/temp_muzzle_flash.svg", 40, 40,
     '<path d="M20 0L24 12L36 5L29 17L40 20L28 24L35 36L23 29L20 40L16 28L4 35L11 23L0 20L12 16L5 4L17 11Z" fill="#f4b950"/><path d="M20 9L23 17L31 20L23 23L20 31L17 23L9 20L17 17Z" fill="#fff1bd"/>')
save("ui/temp_zone_mark.svg", 48, 48,
     '<path d="M24 3L45 41H3Z" fill="none" stroke="#d6b979" stroke-width="3"/><path d="M24 15V28" stroke="#d6b979" stroke-width="4"/><circle cx="24" cy="35" r="2" fill="#d6b979"/>')
print("8 recursos SVG provisionales generados en assets/placeholders/.")
