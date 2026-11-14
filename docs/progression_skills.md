# Fase 7 — experiencia, niveles y habilidades

Validación: **14 de noviembre de 2026**, Godot 4.7.2 Stable oficial, Windows,
GDScript y Compatibility. Progresión solo de la partida actual; sin guardado,
misiones, nuevos enemigos, armas, fabricación ni cambios del escenario.

## XP y puntos

ProgressionComponent empieza en nivel 1, 0 XP y 0 puntos disponibles. Máximo 10.
El requisito para pasar del nivel L al siguiente es `100 + (L - 1) * 50`: 100,
150, 200, hasta 500 para pasar de 9 a 10. Total útil hasta máximo: **2700 XP**.
Se concede un punto por subida, hasta nueve en la configuración inicial.
Las recompensas multinivel conservan sobrantes y conceden los puntos exactos con
una sola notificación agregada. Al máximo se descarta el exceso y se muestra
MÁXIMO; no genera puntos adicionales. Nivel/XP inicial, máximo, requisitos y
puntos por subida son exportados y configurables.

La XP almacenada es la del nivel actual; total_xp deriva la acumulada útil.
ProgressionRewards centraliza las concesiones:

- **30 XP** por zombi eliminado, comprobando salud muerta.
- **20 XP** por primera apertura de cada contenedor con suministros.
- Cero por contenedores vacíos, reaperturas y notificaciones repetidas.
- Cero concesiones o compras después de Game Over.

Registra instance_id antes de notificar la recompensa, evitando reentrada. No se
modifica la IA ni el contador de bajas. El evento de apertura procede de la
interacción existente, con alcance y visibilidad World ya comprobados.

La tabla solicitada solo define bajas y contenedores: **no se inventa una tasa
de XP pasiva por tiempo** ni se implementan misiones. Sobrevivir permite seguir
acumulando recompensas; explorar encuentra los contenedores actuales.

**Contenido actual:** tres zombis y cinco contenedores ofrecen **190 XP**,
suficientes para nivel 2 y un punto. Los niveles superiores están implementados
y probados para contenido futuro. No se añade respawn ni loot infinito para
alcanzarlos. No hay redistribución de habilidades.

## Habilidades

Definiciones Resource inmutables en resources/skills/, rangos por instancia en
SkillsComponent. Empiezan en cero y se limitan a cinco, aunque sobren puntos.
Cada compra válida descuenta un punto y notifica después de confirmar el rango.
IDs desconocidos, saldo insuficiente y reentrada durante el gasto se rechazan.

| Habilidad | Cada rango | Cinco rangos |
| --- | --- | --- |
| Vitalidad | +5 HP máximos | +25 HP máximos |
| Agilidad | +3 % de velocidad base | +15 % de velocidad base |
| Manejo de armas | −4 % del tiempo base de recarga | −20 % del tiempo base |
| Supervivencia | −5 % del consumo base de hambre/sed | −25 % de consumo |

CharacterStats calcula desde rangos y bases; nunca suma sobre el valor efectivo.
Refrescar UI o cambiar de arma no vuelve a aplicar bonificaciones acumulativas.
Vitalidad conserva HealthComponent.base_max_health, ajusta el máximo y emite
health_changed. **No cura al comprar ni revive**; los botiquines respetan el
máximo efectivo. Agilidad mantiene Player.speed (240) y aplica un multiplicador
al vector normalizado. La cámara y física no cambian.

Manejo mantiene WeaponConfig intacto. Cada arma de fuego recibe reload_multiplier
y conserva reload_duration_current como duración real. Al aprender durante una
recarga se conserva la fracción pendiente, se ajusta el tiempo restante y no se
transfieren balas ni se reinician señales/sonidos. CharacterVisual usa esa duración
para sincronizar los frames existentes. Armas incorporadas después heredan el
factor; el machete no lo recibe. Con dos rangos: pistola 1.38 s, revólver 1.932 s,
escopeta 2.208 s; bases 1.5/2.1/2.4 sin modificar.

Supervivencia escala la pérdida sin sobrescribir intervalos 30/20 s. Con un rango,
60 s consumen 1.9 hambre y 2.85 sed; con cinco, un punto cuesta 40/26.67 s.
La penalización por privación y el uso de consumibles conservan sus reglas.

## UI, audio y controles

**K** abre/cierra PERSONAJE; **Esc** lo cierra. Tab pasa a MOCHILA y K vuelve a
PERSONAJE. InterfaceCoordinator deriva un único bloqueo de las ventanas visibles,
sin un instante desbloqueado al sustituir una por otra. El mundo sigue activo;
se bloquean movimiento, apuntado, combate, recarga nueva, selección de arma e
interacción exterior. Se exige soltar shoot al cerrar. Game Over cierra ambas
ventanas y no permite reabrirlas ni asignar rangos.

El panel reutiliza el tema y muestra nivel, XP actual/requerida, total útil, barra,
puntos, estadísticas efectivas, descripciones, rangos y botones. No repite branding.
El HUD añade NIV/XP a la línea pequeña del sector y conserva **256 × 172** en reposo.
La subida muestra un aviso breve con K y los puntos recibidos. GameAudio reutiliza
pickup_supply para una subida e item_use para una compra válida: sin WAV nuevos
ni cambios de volumen. Una recompensa multinivel produce un aviso/sonido, y los
refrescos de UI no producen sonidos de compra.

## Arquitectura y reinicio

- progression_component.gd: nivel, XP, puntos, bloqueo y snapshot.
- skills_component.gd: rangos, validación de gasto y señal skill_acquired.
- skill_definition.gd y cuatro .tres: configuración de cada habilidad.
- progression_rewards.gd: deduplicación y concesión desde eventos existentes.
- character_stats.gd: adaptación idempotente a salud, movimiento, armas y consumo.
- character_ui.gd / CharacterUI.tscn: presentación, sin duplicar estadísticas.
- interface_coordinator.gd: exclusión mutua y bloqueo de ventanas.
- Main conecta eliminated, aperturas, HUD y UI; el contador de bajas no cambia.

Reintentar instancia todo de nuevo: nivel 1, XP/puntos/rangos cero, registro vacío,
máximo 100 HP, velocidad 240, consumo 1 y recarga base. También restaura inventario,
armas, munición, zombis y contenedores como antes. Los snapshots devuelven
diccionarios independientes de datos simples para un adaptador futuro; no se
lee/escribe ninguna partida. instance_id solo identifica esta sesión: una futura
persistencia requerirá identificadores estables del contenido.

## Validación

```text
godot --headless --path . --editor --import
godot --headless --path . --fixed-fps 60 --script res://tests/progression_component_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/phase_seven_test.gd
godot --path . --fixed-fps 60 --script res://tests/phase_seven_test.gd -- --capture
```

Las quince suites anteriores conservan **759 comprobaciones aprobadas**. El
componente añade **58**, la integración **88**: **905 comprobaciones headless**,
cero fallos. Cubren requisitos, sobrantes, multinivel, máximo, puntos exactos,
configuración alternativa, cinco rangos de las cuatro habilidades, modificadores
máximos, premios únicos/reentrantes, compra por botón, HP sin curación gratis,
movimiento diagonal, recarga en curso y armas futuras, animación/munición,
consumo, bloqueo de UI, muerte y reinicio.

La prueba gráfica aprueba **90 comprobaciones** y guarda dos PNG reales en
test-results/phase-seven/. El panel inicial procede de tres bajas y dos aperturas
(130 XP). Para probar nivel 10 se concede una recompensa grande solo en la
fixture; no se añade un modo de trampa al juego. La prueba aislada configura tres
puntos por nivel solo para verificar todos los rangos con saldo sobrante.
Las entradas K/Tab/Esc y clics son eventos de Godot; los enemigos se congelan en
fixtures para aislar resultados. Las regresiones anteriores mantienen pruebas de
IA, navegación y combate. Se reutiliza la limpieza de audio de los tests.

Regresión gráfica general: **39 comprobaciones**, cero fallos, cinco capturas.
La regresión gráfica de HUD/audio también aprueba **99 comprobaciones**, con
capturas y mezcla de audio generadas por su prueba existente.
PERSONAJE y HUD inspeccionados a 1280 × 720. Una captura quedó esperando un frame
al inspeccionar una imagen mientras seguía activa; se cerró únicamente ese
proceso y se repitió sin intercalar visualizaciones. La repetición terminó con
90 aprobaciones. No se modificó gameplay para resolver esa espera.
Importación y arranque normales correctos; sin nuevos errores/advertencias del
motor en la pasada final. Capturas con la ventana renderizando; headless omite
imágenes y valida eventos conforme a la infraestructura existente.

## Entrega y pendientes

docs/images/character.png es nuevo. Gameplay/combat/game-over se renuevan con
NIV/XP; la galería e historial anteriores se conservan. Son recursos reales del
proyecto, con acciones preparadas en el motor, sin imágenes conceptuales.

Pendiente manual: sesión prolongada con enemigos activos y menús, balance para
mapas futuros, lectura a otras resoluciones, panel gráfico del depurador, escucha
en altavoces y exportación Windows. No se declaran aprobadas esas comprobaciones.
El mapa actual solo ofrece un punto por partida; nueve requieren más contenido.

Nuevos: scripts/components/{progression_component,skills_component}.gd;
scripts/progression/{skill_definition,progression_rewards,character_stats}.gd;
scripts/ui/{character_ui,interface_coordinator}.gd y sus .uid; cuatro recursos
resources/skills/; interfaces/CharacterUI.tscn; dos pruebas nuevas y sus .uid;
este informe y docs/images/character.png con .import.

Modificados: Player.tscn, Main.tscn, interfaces/HUD.tscn; main.gd, player.gd,
health_component.gd, survival_component.gd, equipment_component.gd, weapon.gd,
character_visual.gd, hud.gd, game_audio.gd; project.godot (solo K); README.md,
AGENTS.md, docs/images/README.md y tres capturas de juego existentes.
World, IA, recursos de armas, frames, inventario y sus recursos se conservan.
Sin commits, push, plugins, misiones ni almacenamiento persistente.
