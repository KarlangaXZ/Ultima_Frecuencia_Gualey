Free Zombie Office Worker  -  version 1.3.4

1 top-down character, 8 directions, free to try.

- Zombie Office Worker: attack, attack2, attack3, attack4, death, hurt, idle, run, walk (216x232 px frames)

This character is also part of the Civilian Zombies pack.

Effects:
- Zombie Office Worker Projectile: block, break, restore

FOLDERS
  characters/<name>/sheets/      one PNG per animation; 8 rows = directions, columns = frames
  characters/<name>/frames/      every frame as its own PNG: <animation>/<DIRECTION>/<index>.png
  characters/<name>/_sizes/128/  the same sheets and frames at 128 px cell height
  characters/<name>/godot/       Godot 4 SpriteFrames (.tres), animations named <animation>_<direction>
  characters/<name>/<name>.json  frame size, feet pivot, frames, fps and looping per animation
  effects/<name>/                projectile and impact sheets, frames, Godot SpriteFrames and JSON
  ColourVariations/              optional colour variations, recolour masks and a Godot shader
  previews/                       animated GIF previews

SMOOTH CLIPS
  Every idle, walk, run, attack and hurt animation (and every effect) also comes as <animation>_smooth: the same animation with twice the frames, played at twice the fps (same frame size, feet pivot and row order). Sheets, single frames, 128 px copies, colour variations and recolour masks included; Godot 4 SpriteFrames in godot/<name>_smooth_spriteframes.tres (animations <animation>_smooth_<direction>); the JSON lists them. Effects: <clip>_smooth sheets next to the originals, listed in each effect JSON.

COLOUR VARIATIONS (ColourVariations/, optional: delete the folder if you don't need it)
  ColourVariations/<variation>/<name>/  every animation of a character in another colour variation: the same
      sheets, frame size, feet pivot and Godot SpriteFrames as characters/<name>/ (sheets only; slice
      them like the main sheets). Previews: previews/<name>_colour_variations.png
  - Zombie Office Worker: Navy Jacket (navy/), Grey Jacket (grey/), Burgundy Jacket (burgundy/), Black Jacket (black/)
  ColourVariations/recolour_masks/<name>/<clip>.png  material masks in the same layout as the sheets
      (red = main material, green = second material) for your own colours at runtime.
  ColourVariations/godot/recolour_mask.gdshader + recolour_masks.gd  Godot 4: give the AnimatedSprite2D a
      ShaderMaterial with the shader, attach the script, set masks_dir, then pick colour_main / colour_second.

DIRECTIONS
  Sheet rows top to bottom: S, SE, E, NE, N, NW, W, SW

GODOT 4
  Copy a whole character folder into your project and assign godot/<name>_spriteframes.tres
  to an AnimatedSprite2D. Paths inside are relative, so the folder can live anywhere.

OTHER ENGINES (Unity, GameMaker, Construct, Defold, ...)
  Slice a sheet as a grid: columns = frames, 8 rows = directions. Frame size and pivot are in the JSON.

Suggested speeds: idle 8 fps, walk 10, run 12, attacks 12, hurt 12, death 10. Idle, walk and run loop.

License: see LICENSE.txt.

MORE IN THIS STYLE
  Civilian Zombies: https://sovdigital.itch.io/civilian-zombies
  Zombies Set: https://sovdigital.itch.io/zombies-set
  Complete Edition (every pack, boss and effect in one download): https://sovdigital.itch.io/complete-edition
  Everything by Sova Digital: https://sovdigital.itch.io/
