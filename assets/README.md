# Última Frecuencia: Gualey — recursos visuales

Arte SVG original del proyecto, sin descargas ni dependencias. Todos los archivos
`temp_*` son temporales, reemplazables y no representan arte definitivo.
Desde la fase 4.1, las rutas del siguiente inventario son relativas a
**`assets/placeholders/`**, salvo `assets/ui/SurvivalTheme.tres`, que sigue activo
en su ubicación original. Las carpetas modulares fuera de placeholders están
reservadas para arte final. Desde fase 4.2, characters/player/idle contiene los
cuatro PNG reales suministrados para idle_down y player/walk los ocho PNG de
walk_down (8 FPS). Los demás módulos siguen provisionales.

Actualización de direcciones: idle tiene cuatro direcciones reales; walk tiene
down/up/right. walk_left sigue provisional por defectos de fondo en los archivos.
Los nombres originales de varios PNG no coinciden con su orientación: consultar
`docs/player_directions_integration.md` antes de ampliar o reorganizar la biblioteca.

- `characters/player/temp_survivor_sheet.svg`: superviviente con chaqueta verde,
  chaleco y gafas. Atlas horizontal de **12 celdas de 64 × 64**, transparente.
- `characters/zombies/temp_zombie_sheet.svg`: infectado con ropa marrón y piel oliva,
  mismo contrato de atlas. No cambia salud, radio físico ni estado del enemigo.
- `environment/tilesets/temp_asphalt.svg`: loseta de asfalto de 160 × 160, repetida
  mediante dibujo 2D; no se añadió TileMap porque no requiere colisión ni navegación.
- `environment/props/temp_supply_crate.svg`: caja militar de 128 × 96; coincide
  con la colisión preexistente. Las instancias conservan posición y escala originales.
- `environment/decals/temp_debris.svg`: papel y restos planos, sin volumen ni colisión.
- `weapons/temp_pistol.svg`: solo representación de la pistola existente.
- `effects/temp_muzzle_flash.svg`: destello opcional sin influencia física.
- `ui/temp_zone_mark.svg`: señal temporal. `assets/ui/SurvivalTheme.tres`: tema compartido del HUD.

## Sustituir personajes

`scripts/visuals/character_visual.gd` tiene un export `sheet` y genera SpriteFrames
para AnimatedSprite2D. Índices: **0–1 idle, 2–5 walk, 6–7 attack, 8–11 death**.
Las animaciones se llaman `<estado>_<dirección>` para down/up/left/right. El arte
es cenital orientado hacia abajo y la capa visual lo rota hacia la dirección
observada: mouse/Aim para jugador y movimiento/objetivo para zombi. Las cuatro
direcciones reutilizan los mismos frames rotados; no hay cuatro atlas distintos.
Death no se repite. La animación de ataque es ilustrativa y no dispara eventos
de daño ni determina la cadencia del zombi.

Para reemplazar el arte sin cambiar código, mantener tamaño, orden y orientación
del atlas y reasignar `sheet` en la escena. Si el arte requiere atlas diferentes
por dirección, ampliar únicamente esta capa visual y sus pruebas.
También se puede asignar **`Visual.animation_library`** desde el inspector:
es un SpriteFrames final con las animaciones `<estado>_<dirección>` y permite
fotogramas de cualquier tamaño sin usar el atlas fijo. Se requieren idle, walk,
death y attack (para zombis), para down/up/left/right. Death debe tener loop=false.
La biblioteca puede ser parcial: solo sustituye las animaciones que contiene y
conserva el sheet temporal para las restantes. Si está vacía, todo sigue provisional.
`library_scale` y `library_offset` se aplican solo a los fotogramas reales;
al cambiar de estado se restaura el transform provisional. El arte frontal de
idle_down usa escala (0.4,0.4), offset (0,-56) y rotate_library_with_actor=false.
Para bibliotecas cenitales rotables se puede activar esa última opción.

## Puntos de reemplazo desde el inspector

| Recurso final | Propiedad o nodo | Carpeta final |
|---|---|---|
| Personaje | Player/Visual: sheet o animation_library | assets/characters/player/ |
| Zombi | Zombie/Visual: sheet o animation_library | assets/characters/zombies/ |
| Suelo | World/Ground: asphalt_texture | assets/environment/tilesets/ |
| Restos planos | World/Ground: debris_texture | assets/environment/decals/ |
| Cajas | Obstacle/Visual: texture | assets/environment/props/ |
| Pistola | Player/Aim/Barrel: texture | assets/weapons/ |
| Destello | Player/Combat/Effects: muzzle_texture | assets/effects/ |
| HUD y Game Over | Tema del Panel e icono Mark existentes | assets/ui/ |

Reasignar recursos en los nodos visuales, conservando rutas, señales, pivotes,
colisiones y escalas físicas. Antes de aceptar arte final, comprobar silueta,
orientación, márgenes transparentes, huella visible, animaciones y las cuatro
pruebas de regresión. No borrar placeholders hasta terminar esa validación.

## Regeneración

`tools/generate_placeholder_art.py` genera los ocho SVG con Python estándar.
Su salida ahora es exclusivamente `assets/placeholders/`; no sobrescribe arte final.
Ejecutar `python tools/generate_placeholder_art.py` y reimportar en Godot.
No modifica el tema ni los scripts. Usar un intérprete Python real si el alias
de Windows no está disponible. Los SVG ya están incluidos: Python no es necesario
para abrir, ejecutar ni exportar el juego.

Los `.svg.import` son metadatos de importación de Godot y se conservan junto a los
recursos. Las texturas rasterizadas y cachés permanecen en `.godot/`, excluida de Git.

## Efectos opcionales

`Combat/Effects.effects_enabled` desactiva destello y partículas; `Visual.effects_enabled`
desactiva el flash del personaje y `HUD.effects_enabled` el overlay de daño.
Se pueden retirar los nodos Visual y Combat/Effects sin cambiar el gameplay.
Los efectos solo escuchan señales y nunca aplican daño, alteran salud o consumen
munición. Las partículas caducan a los 0.32 s; no crean nodos ni depósitos persistentes.
