# Fase 5 — inventario, suministros y supervivencia

Validación: **13 de noviembre de 2026**, Godot 4.7.2 Stable oficial en Windows,
Compatibility/OpenGL. Sin plugins, commits, push ni persistencia entre sesiones.

## Funcionalidades y controles

La mochila empieza vacía y tiene **12 espacios**. Un tipo puede ocupar varias
pilas. E recoge un objeto o abre un contenedor cercano (56 px entre centros),
sin atravesar sólidos World. Tab abre/cierra la ventana; Esc y Cerrar la cierran.
Seleccionar un espacio muestra nombre, cantidad, icono y descripción. UTILIZAR
aplica consumibles; PASAR A RESERVA transfiere toda una pila de munición al arma.

| Objeto | Identificador | Efecto por unidad | Máximo por pila |
| --- | --- | --- | ---: |
| Botiquín | medkit | Hasta +40 HP | 5 |
| Botella de agua | water | Hasta +30 sed | 10 |
| Comida enlatada | food | Hasta +30 hambre | 10 |
| Munición de pistola | pistol_ammo | +1 bala de reserva | 60 |

Los recursos `resources/items/*.tres` configuran id, nombre, descripción,
categoría, icono, máximo de pila, efecto y cantidad. Son configuración compartida;
nunca se modifica su contenido durante una partida. Los cinco SVG nuevos de
`assets/ui/items/` son iconos técnicos originales (cuatro objetos y mochila),
no arte definitivo. No se sustituyen gráficos ni animaciones existentes.

Las recogidas y transferencias son **completas**: si no cabe toda la cantidad,
se avisa y el origen permanece intacto. No hay transferencias parciales implícitas.
Un fallo no emite una actualización falsa. No se aceptan cantidades no positivas,
retiradas excesivas, índices inválidos ni definiciones diferentes con un mismo id.
Una consulta de espacio devuelve una copia de sus cantidades.

Salud y necesidades se limitan a sus máximos; no se consume si el efecto no
aportaría beneficio. Botiquines, agua y comida gastan una unidad por uso. La
munición gasta toda la pila seleccionada: sus unidades dejan de existir en la
mochila al pasar a `Weapon.reserve`. No hay copias de loaded/reserve dentro del
inventario ni se crean balas al recargar. Capacidad 12, cadencia 0.3 s y recarga
1.5 s permanecen en la configuración original de la pistola.

## Interfaz y política de entrada

InventoryUI es una ventana independiente que usa SurvivalTheme, no un segundo
HUD. El HUD original añade una sola línea compacta para hambre/sed, un indicador
de interacción y mensajes temporales. Los nombres de los espacios no se recortan.

Mientras está abierta se bloquean **WASD, apuntado, disparo, inicio de recarga y
E exterior**. La interfaz conserva sus botones de utilización y transferencia.
No se pausa el árbol: zombis, hambre/sed, tiempo sobrevivido y una recarga ya
iniciada continúan. La muerte cierra la ventana y muestra el Game Over existente.
Cerrar exige soltar el disparo antes de permitir un nuevo tiro, aunque el clic
estuviera mantenido desde antes de abrir. No se deshabilita/reinicia Weapon para
controlar la UI, por lo que se conserva su cooldown y una recarga en curso.

## Recursos del mundo

`scenes/world/Supplies.tscn` compone siete Areas en una nueva capa de interacción
(capa 4, valor 8), fuera de Obstacles. Son pequeños objetos transitables que no
añaden cuerpos sólidos ni cambios a navegación, límites o apariciones.

| Elemento | Posición | Contenido inicial |
| --- | --- | --- |
| Agua suelta | 560, 840 | Agua ×2 |
| Botiquín suelto | 650, 910 | Botiquín ×1 |
| Comida suelta | 680, 1000 | Comida ×2 |
| Munición suelta | 900, 940 | Balas ×24 |
| Caja de suministros | 1320, 690 | Balas ×24, comida ×2, agua ×2 |
| Contenedor médico | 770, 650 | Botiquín ×2, agua ×1 |
| Mochila abandonada | 600, 1060 | Comida ×3, agua ×2, balas ×12 |

Total finito por partida: tres botiquines, siete aguas, siete comidas y sesenta
balas recogibles, además de la munición inicial del arma. Contenedores muestran
su contenido y aviso de vacío. Cerrar/reabrir no los rellena. Reintentar recarga
Main y restaura existencias, mochila vacía, necesidades y todos los estados previos.

## Supervivencia

SurvivalComponent comienza en 100 hambre / 100 sed y decrece continuamente:
un punto cada 30 s / 20 s respectivamente. El HUD redondea hacia arriba a enteros.
Los intervalos son exportados y configurables. No cambian velocidad ni física.

Si alguna necesidad llega a cero se inicia **un solo acumulador** de penalización:
2 HP cada 5 s, configurables. Tener ambas a cero no suma dos daños. El primer
intervalo cuenta solo el tiempo realmente transcurrido desde llegar a cero,
sin daño retroactivo al atravesar ese límite. Recuperar ambas necesidades
reinicia el acumulador. HealthComponent recibe todo el daño; no se altera su
cadencia de ataques enemigos ni se añade invulnerabilidad global. Tras died no
hay nuevos cambios de necesidades, daño ni tiempo de supervivencia, ni curación
que reviva al jugador.

## Arquitectura y contratos

- `scripts/components/inventory_component.gd`: almacenamiento por instancia y
  señal changed. API: add_item, can_add, space_for, count_item, get_slot,
  remove_item, remove_from_slot y transfer_slot_to. El número de espacios se
  configura antes de entrar en el árbol; la UI del jugador representa los 12
  de esta fase. Las dos partes de una transferencia cambian antes de notificar.
- `scripts/inventory/item_definition.gd`: Resource, configuración inmutable.
- `scripts/inventory/item_use.gd`: can_use/use_slot y feedback. Aplica efectos
  mediante los componentes existentes y protege contra reentrada de utilización.
- `scripts/components/health_component.gd`: añade heal sin resurrección, acotado
  al máximo, con la señal health_changed existente. take_damage no cambia.
- `scripts/weapons/weapon.gd`: añade add_reserve, sin tocar disparo/recarga. El
  arma sigue siendo la única fuente de cargador, reserva utilizable y cooldown.
- `scripts/components/survival_component.gd`: necesidades, restauración y único
  reloj de privación. No depende de la interfaz ni replica salud.
- `scripts/world/world_pickup.gd`: reserva la recogida antes de emitir señales;
  si falla almacenamiento vuelve a estar disponible; si tiene éxito se elimina.
- `scripts/world/loot_container.gd`: contenido inicial y InventoryComponent
  independiente. No regenera recursos ni usa estado global.
- `scripts/player/player_interaction.gd`: intersect_shape con Areas, distancia
  exacta y rayo World para visibilidad. También valida alcance al transferir
  desde el contenedor, aunque la UI mantenga una referencia anterior.
- `scripts/ui/inventory_ui.gd`: representa estados y emite solicitudes; no aplica
  daño, curación ni balas. Las rejillas se crean una vez y se actualizan por señales.
- `scripts/player/player.gd`: conserva locomoción; añade el bloqueo temporal de
  controles y la exigencia de soltar shoot al cerrar. No guarda pilas ni necesidades.
- `scripts/main.gd`: conecta señales de componentes, HUD e inventario.

## Validación automática y gráfica

Importación final y arranque normal de Main: correctos. Las once pruebas
anteriores se conservan y aprueban **456 comprobaciones**; cubren locomoción,
cámara, colisiones, navegación, ataques, munición, recarga, animaciones,
eliminaciones, Game Over, Reintentar y escenario urbano.

```text
godot --headless --path . --editor --import
godot --headless --path . --fixed-fps 60 --script res://tests/inventory_component_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/phase_five_test.gd
godot --path . --fixed-fps 60 --script res://tests/phase_five_test.gd -- --capture
```

- Componente de inventario: **32 comprobaciones**, cero fallos. Pilas, doce
  espacios, capacidad parcial, fallos atómicos, cantidades inválidas, copias,
  retirada, ids incompatibles y transferencia reentrante sin duplicados.
- Integración fase 5: **76 comprobaciones**, cero fallos. Recogida física y a
  distancia, pared interpuesta, inventario lleno, recogida reentrante, consumo
  acotado, efectos inútiles rechazados, munición, teclado E/Tab/Esc, clics en slots,
  Cerrar/UTILIZAR/RECOGER, controles bloqueados, cooldown/recarga, tres contenedores
  finitos, privación sin doble daño, muerte y reinicio completo. También comprueba
  que zombis y necesidades siguen activos con la mochila abierta.
- Total headless: **564 comprobaciones**, cero fallos.
- Integración con renderizado: **80 comprobaciones**, cero fallos, cuatro PNG:
  `01-hud`, `02-inventory`, `03-container`, `04-game-over`, en test-results/phase-five/.
- Regresión gráfica general: **39 comprobaciones**, cero fallos, cinco PNG
  renovados en test-results/phase-four/. No se duplican como pruebas independientes
  las comprobaciones que repiten las mismas suites con renderizado.

Los clics automatizados convierten coordenadas del viewport a pantalla, evitando
resultados falsos en headless. Las teclas son InputEventKey físicos. La prueba de
supervivencia adelanta su reloj explícitamente y congela enemigos solo en las
fixtures de consumo/transferencia; al final prueba enemigos activos contra la UI.
No modifica los valores de configuración del juego. El botón Reintentar se activa
por su señal en esa comprobación, como en las suites anteriores.

Capturas reales inspeccionadas, sin recortes de nombres ni desbordamiento de la
ventana a 1280 × 720. README renueva sus tres capturas de juego y añade inventario;
la captura del contenedor se conserva enlazada para documentación. Los PNG se
optimizan sin pérdida y se comprueba identidad de píxeles con la captura fuente.

## Problemas corregidos y pendientes

Durante desarrollo se corrigieron una inferencia de tipo en el controlador de
interacción y una propiedad de icono de Button que debía ser una constante de
tema. También se corrigieron el recorte de nombres en la rejilla y la conversión
de coordenadas del test de clics headless. Las ejecuciones finales no presentan
errores ni advertencias nuevas del motor.

Pendiente manual: sesión prolongada con ritmo real de hambre/sed, balance de
cantidades y penalización, navegación de la UI con distintos tamaños de ventana,
exploración/combate mientras se abre y cierra la mochila, panel gráfico del
depurador y exportación Windows. No se declaran aprobadas esas comprobaciones.
Los iconos y contenedores son técnicos y sustituibles. No hay fabricación,
guardado, progresión, misiones, nuevas armas ni reposición infinita.

## Archivos de esta fase

Nuevos: los ocho scripts de inventario/supervivencia/interacción/UI enumerados
arriba y sus `.uid`; cuatro recursos en resources/items/; WorldPickup.tscn,
LootContainer.tscn, Supplies.tscn e InventoryUI.tscn; cinco SVG en assets/ui/items/
con sus `.import`; inventory_component_test.gd y phase_five_test.gd con sus `.uid`;
este informe; docs/images/inventory.png y loot-container.png con sus `.import`.

Modificados: Player.tscn, Main.tscn, World.tscn, HUD.tscn; player.gd, main.gd,
hud.gd, health_component.gd, weapon.gd; project.godot (E y Tab, con normalización
de serialización del editor para shoot/reload sin cambiar sus asignaciones); README.md,
AGENTS.md, docs/images/README.md y las tres capturas de juego de esa carpeta.
Los cambios anteriores de la fase 4.5 se conservan. Los resultados, herramientas
y cachés permanecen ignorados por Git.

Durante la validación apareció una carpeta adicional de recursos de zombi
`assets/characters/zombies/free-zombie-office-worker-zombieofficeworkerfree-v1-3-0/`.
No forma parte de la fase 5 ni se añadieron referencias a ese paquete.
