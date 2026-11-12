# Última Frecuencia: Gualey — diagnóstico de animaciones del protagonista

## Alcance y resultado

Revisión técnica y visual de los archivos disponibles, sin modificar imágenes,
escenas, scripts, recursos SpriteFrames ni gameplay. **4 fotogramas utilizables
de 112 objetivo; 108 pendientes de producir/exportar correctamente.** Las
referencias de drafts no cuentan como fotogramas finales ni se integraron.

Se leyeron AGENTS.md, README.md, assets/README.md y la guía del protagonista.
Se inspeccionaron Player.tscn, character_visual.gd y PlayerIdleDown.tres.

## Ubicación real de referencias

Las rutas solicitadas `assets/characters/player/drafts/player_animation_reference.png`
y `player_animation_preview.png` no existen en esta copia del repositorio.
Se localizaron y revisaron estos archivos alternativos, sin moverlos ni asumir
que son exportaciones finales:

| Archivo existente | Tamaño / modo | Dictamen |
|---|---|---|
| `draft/a_detailed_spritesheet_image_for_the_game_a_large.png` | 1536 × 1024, RGBA | Referencia conceptual únicamente |
| `draft/Spritesheet del protagonista de Última Frecuencia.png` | 1536 × 1024, RGBA | Duplicado exacto de píxeles de la referencia anterior |
| `draft/ufg_player_preview.png` | 850 × 720, RGB | Previsualización defectuosa para extracción de frames |

Las dos referencias grandes tienen el mismo SHA-256 de píxeles RGBA:
`2904445edf5095270cef1f8981133e1f7cfa66d9438cc785f029cd8babdc5eb9`.
Esto verifica duplicación de contenido visual, sin afirmar que sus archivos
comprimidos sean idénticos byte a byte.

## Recursos aprovechables

`assets/characters/player/idle/player_idle_down_00.png` a `_03.png`:

| Frame | Dimensiones | Modo / alfa | Límites de contenido no transparente (fin exclusivo) |
|---|---|---|---|
| 00 | 128 × 128 | RGBA, 0–255 | (31, 6)–(97, 122) |
| 01 | 128 × 128 | RGBA, 0–255 | (32, 7)–(96, 122) |
| 02 | 128 × 128 | RGBA, 0–255 | (32, 9)–(95, 122) |
| 03 | 128 × 128 | RGBA, 0–255 | (32, 6)–(96, 122) |

Los cuatro tienen píxeles totalmente transparentes, no son duplicados exactos,
mantienen la misma base y un centro horizontal próximo a x=64. Ninguna silueta
alcanza el borde del lienzo. La inspección visual muestra el cuerpo completo y
variaciones sutiles coherentes con reposo; no constituyen un ciclo de caminata.
El borde superior varía 3 px y el ancho del contenido 3 px: conviene revisar la
suavidad artística del bucle en tiempo real antes de dar el paquete por final.

`player_idle_down_sheet.png` mide 512 × 128, RGBA; sus cuatro celdas coinciden
exactamente con los PNG individuales. Es una representación alternativa del
mismo material, **no cuatro fotogramas adicionales**. Mantener los PNG individuales
como fuente activa del recurso ya integrado.

PlayerIdleDown.tres sigue referenciando 00→01→02→03, 4 FPS y loop=true.
Player/Visual combina esta biblioteca parcial con el atlas provisional, preservando
el resto de animaciones. Su escala 0.4, offset (0,-56) y orientación fija se
aplican solo al arte real; no se necesita tocar la física para conservarlo.

## Material que necesita nueva exportación o regeneración

**Lámina conceptual grande:** tiene fondo, títulos, numeración y separadores
integrados en la imagen. Aunque el modo es RGBA, solo 12 de sus 1 572 864 píxeles
son totalmente transparentes; alfa máximo 253 y contenido ocupa todo el lienzo.
No proporciona fondo transparente utilizable alrededor de cada personaje.
La distribución y numeración son irregulares, con distinto número de figuras
visibles por fila: los rótulos no demuestran que existan los 112 frames.
Incluso sin títulos, 1536 × 1024 solo admite 96 celdas completas de 128 × 128.
Por tanto, no puede ser un atlas regular de los 112 frames anunciados a ese tamaño.
No se certifican duplicados o continuidad temporal entre sus pequeñas figuras:
primero hacen falta exportaciones aisladas para medirlas correctamente.

**Previsualización:** carece de canal alfa y contiene fondo gris, etiquetas y
varias siluetas incompletas. Idle/down y las vistas laterales/superior aparecen
recortadas; walk/down está vacío; otras celdas de walk y death contienen brazos,
mochilas o fragmentos separados. Reload/right tampoco conserva el cuerpo completo.
Algunas vistas de shoot y reload parecen más completas, pero son muestras dentro
de una composición, sin secuencia temporal suficiente ni pivote certificado.
**Ninguna celda se acepta como frame final.** No reconstruir cuerpos combinando
fragmentos ni tratar una sola pose como ciclo completo.

Si existen originales por capas y resolución completa, volver a exportar desde
ellos. Si no existen, regenerar las secuencias faltantes usando la referencia
solo para identidad, vestuario y paleta. No reemplazar idle_down válido.

## Inventario objetivo

| Animación | Por dirección | Down disponible | Left | Right | Up | Faltantes |
|---|---:|---:|---:|---:|---:|---:|
| Idle | 4 | 4 | 0 | 0 | 0 | 12 |
| Walk | 8 | 0 | 0 | 0 | 0 | 32 |
| Shoot | 4 | 0 | 0 | 0 | 0 | 16 |
| Reload | 6 | 0 | 0 | 0 | 0 | 24 |
| Death | 6 | 0 | 0 | 0 | 0 | 24 |
| **Total** | | **4** | **0** | **0** | **0** | **108** |

Los estados provisionales del atlas SVG continúan funcionando, pero no cuentan
como arte final disponible de este inventario.

## Estructura recomendada para futuras entregas

Conservar las rutas activas actuales de idle_down para evitar migraciones:

```text
assets/characters/player/
  idle/player_idle_down_00.png ... _03.png   # existentes, conservar
  idle/player_idle_left_00.png ... _03.png
  idle/player_idle_right_00.png ... _03.png
  idle/player_idle_up_00.png ... _03.png
  walk/player_walk_<direction>_00.png ... _07.png
  shoot/player_shoot_<direction>_00.png ... _03.png
  reload/player_reload_<direction>_00.png ... _05.png
  death/player_death_<direction>_00.png ... _05.png
  drafts/                                  # referencias, sin vínculo a SpriteFrames
```

Es una propuesta documental: no se crearon carpetas vacías ni fotogramas nuevos.
Las referencias existentes permanecen en draft/ hasta una reorganización autorizada.

Entregar PNG RGBA separados, mismo lienzo y pivote por secuencia, personaje completo,
sin fondos, texto, rejillas ni recortes automáticos por frame. Base sugerida para
poses de pie: x=64 y línea inferior del contenido en y=122 sobre 128 × 128.
Si una muerte horizontal o arma no cabe, ampliar el lienzo de toda la secuencia
con pivote documentado; nunca recortar extremidades ni encoger frames individuales.
Mantener identidad, perspectiva, escala corporal, iluminación y mano del arma.
No reflejar direcciones automáticamente si cambia equipamiento o lateralidad.

## Antes de integrar todo el paquete

1. Exportar/regenerar los 108 frames pendientes, una secuencia y dirección por entrega.
2. Validar alfa real, dimensiones, límites, duplicados, cuerpo completo, pivote
   estable y continuidad; revisar cada ciclo animado, incluido último→primero.
3. Resolver coherencia entre arte frontal actual y perspectiva cenital del escenario.
   Acordar si la pistola está dibujada dentro del personaje o se mantiene separada
   para evitar duplicar su representación; conservar siempre el hitscan actual.
4. Crear bibliotecas parciales y sustituir solo las secuencias aceptadas, manteniendo
   el atlas provisional en las demás. Idle/walk con bucle; death sin bucle.
5. Preparar posteriormente la selección **visual** de shoot/reload: el controlador
   actual selecciona idle/walk/attack/death, no shoot/reload. Escuchar señales
   existentes del arma y definir prioridades sin cambiar cadencia, recarga ni daño.
   No se implementó esa ampliación durante esta auditoría.
6. Configurar velocidad de reproducción según la secuencia aprobada; no alterar
   tiempos de gameplay para hacerlos coincidir con arte. Repetir regresión y
   revisión visual de transiciones antes de retirar recursos provisionales.

## Validación ejecutada y límites

Lectura de metadatos, hash de píxeles, comparación exacta atlas/PNG y revisión visual
de las tres referencias. Pruebas existentes ejecutadas: fase 1 (21), fase 2 (42),
fase 3 (49), fase 4 (34), idle_down (13): **159 comprobaciones aprobadas, 0 fallos**.
No se observaron errores ni advertencias en la salida filtrada de esas pruebas.
No se ejecutó una nueva sesión manual de juego ni se inspeccionó el panel gráfico
del depurador. No se modificó ni integró ninguna referencia defectuosa.
Solo se añadieron/actualizaron documentos; sin commits automáticos.
