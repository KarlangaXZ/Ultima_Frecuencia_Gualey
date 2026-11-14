# Fase 6 — arsenal, equipamiento y cambio de armas

Validación: **13 de noviembre de 2026**, Godot **4.7.2 Stable** oficial, Windows,
GDScript y Compatibility/OpenGL. Sin plugins, commits ni push.

## Armas y balance inicial

| Configuración | ID / tipo | Daño | Alcance | Intervalo | Cargador / recarga | Munición |
| --- | --- | --- | --- | --- | --- | --- |
| BasicPistol.tres | pistol / hitscan | 25 | 600 px | 0.3 s | 12 / 1.5 s | pistol |
| Machete.tres | machete / melee | 30 por enemigo | 55 px | 0.65 s | No aplica | Ninguna |
| Revolver.tres | revolver / hitscan | 45 | 650 px | 0.55 s | 6 / 2.1 s | revolver |
| Shotgun.tres | shotgun / spread | 8 por perdigón × 8 | 360 px | 0.9 s | 6 / 2.4 s | shotgun |

Valores de prueba configurables en resources/weapons/, no balance definitivo.
WeaponConfig añade id, tipo, munición, icono, visual, carga inicial, cantidad de
perdigones, dispersión y arco de melee. Los parámetros previos de pistola no
cambian. Su carga inicial sigue en 12 y reserva 48; las armas encontradas empiezan
con cargador/reserva **vacíos**, sin crear balas al incorporarlas.

Machete usa un cono de 90° y distancia **entre centros** máxima de 55 px.
Cada enemigo recibe hasta un impacto por ataque, aunque tenga varias formas.
Un rayo World a cada objetivo impide golpes a través de paredes/postes. El golpe
es instantáneo; el arco visible de 0.12 s es feedback y no vuelve a causar daño.

Escopeta reparte ocho rayos uniformemente en un abanico de **18° totales**. Es un
patrón determinista configurable, sin RNG ni caída de daño: todos terminan a
360 px como máximo. Cada rayo aplica hasta 8 HP al primer cuerpo World/Zombie.
Una descarga consume **un cartucho**, emite Shoot una vez y un único destello y
grupo de partículas existentes. Los ocho trazos se dibujan durante 0.1 s. No se
añaden cañones físicos, penetración, nuevas máscaras ni eventos de daño visuales.

## Obtención e inventario

Al iniciar se poseen machete y pistola; la pistola queda activa para conservar
el arranque anterior. InventoryComponent sigue teniendo 12 espacios y empieza
vacío. Los nuevos ItemDefinition son Machete, Revolver, Shotgun, RevolverAmmo y
ShotgunAmmo. Armas: pila máxima 1; balas de revólver: 60; cartuchos: 20.

Armas recogidas pasan primero por la mochila. **INCORPORAR AL ARSENAL** consume
una unidad y crea su Weapon por instancia; no cambia de arma dentro de la UI.
Un arma ya poseída no puede incorporarse otra vez y su objeto no se consume.
El machete también tiene definición de inventario aunque ya se posee al iniciar.

La munición de mochila representa unidades **aún no transferidas**. PASAR A
RESERVA retira la pila y llama add_reserve únicamente al arma poseída cuyo
ammo_type coincida, aunque esté inactiva. Si falta esa arma, no se gasta nada ni
se desvía a la pistola. Weapon es la única fuente de loaded/reserve utilizables;
Equipment solo guarda referencias. Cada una de las tres armas de fuego usa un
tipo distinto. No se modifican ItemDefinition/WeaponConfig compartidos en partida.

ArsenalSupplies.tscn instancia dos veces el **LootContainer existente**:

| Contenedor | Posición | Contenido finito |
| --- | --- | --- |
| Estuche abandonado / revólver | 1560, 1230 | Revólver ×1, balas de revólver ×12 |
| Suministro de seguridad / escopeta | 1960, 880 | Escopeta ×1, cartuchos ×8 |

Usan las mismas Areas 8, alcance de 56 px, comprobación World y transferencias
completas de fase 5. No añaden colisiones sólidas ni navegación. Las cuatro
recogidas y tres contenedores anteriores conservan sus posiciones y contenidos.
Cerrar/reabrir no repone recursos; Reintentar restaura sus contenidos iniciales.

## Equipamiento y entrada

- **1** machete, **2** pistola, **3** revólver, **4** escopeta. Las teclas son físicas.
- Rueda arriba/abajo recorre solo armas poseídas, en ese orden con vuelta al inicio.
- Clic mantenido ataca según el intervalo del arma; R recarga el arma activa.
- Cambiar cancela recarga, sin transferir munición. El cooldown pendiente continúa
  contando en su Weapon inactivo: cambiar de ida y vuelta no permite saltarlo.
  El daño del ataque instantáneo ya resuelto no se revierte ni se repite.
- Un Weapon inactivo no puede disparar ni iniciar recarga. Puede recibir su
  reserva desde el inventario. Su estado nunca se reinstancia al seleccionarlo.
- La mochila bloquea también teclas/rueda del arsenal. Cambiar o cerrar la mochila
  exige soltar shoot antes de permitir otro disparo mantenido. No se pausa mundo,
  necesidades ni una recarga ya iniciada, según fase 5.
- died deshabilita todas las armas, cancela recargas y bloquea selección. El Game
  Over y Reintentar siguen siendo los existentes; el reinicio vuelve a machete +
  pistola, pistola activa, 12/48, mochila vacía y armas nuevas aún por encontrar.

## Arquitectura

- **WeaponConfig / resources/weapons/**: configuración compartida inmutable.
- **weapon.gd**: mismo comportamiento común para las cuatro armas; conserva
  ammo_changed, reload_changed y shot_fired de pistola. Melee emite melee_attacked
  en vez de shot_fired. equipped controla disponibilidad sin resetear cooldown.
- **equipment_component.gd**: propiedad, instancia por id y selección; agrega
  señales de presentación del arma activa y attack_performed. No replica balas,
  aplica daño ni conoce la UI. Player comunica bloqueo y muerte.
- **weapon_combat.gd**: selecciona el comportamiento desde config, sin otra cadencia.
- **hitscan_combat.gd**: extrae cast_hit (rayo + daño al primer cuerpo) y
  present_result (trazo + efecto). fire mantiene el contrato anterior de pistola.
- **spread_combat.gd**: N llamadas a cast_hit, trazos y un present_result común.
- **melee_combat.gd**: consulta física, cono, visibilidad y deduplicación de enemigos.
  Todo daño pasa por HealthComponent; no se duplican muerte ni bajas.
- **item_use.gd / item_definition.gd**: adaptador compatible con los cuatro objetos
  previos; añade arma configurable y ammo_type (pistol por defecto).
- **weapon_visual.gd**: asigna WeaponConfig.visual al Barrel y reconecta el
  controlador existente con CharacterVisual.bind_weapon. Sin lógica de daño.
- **Player**: entrada, selección y referencia weapon activa. Player/Weapon se
  conserva como pistola original, con sus rutas anteriores disponibles.
- **Main/HUD**: observan señales Equipment; HUD muestra nombre, icono, munición,
  recarga e indicadores M/P/R/E (machete/pistola/revólver/escopeta). Corchetes
  indican activa; guion largo indica arma no obtenida.

No se cambian estadísticas de supervivencia, salud, IA, colisiones, navegación,
cámara, ataques de zombis ni recursos SpriteFrames. No hay globals adicionales.

## Presentación provisional

Se conserva el SVG de pistola. Tres SVG nuevos originales y manuales están en
assets/placeholders/weapons/temp_machete.svg, temp_revolver.svg y temp_shotgun.svg.
WeaponConfig.icon/visual son sus puntos de sustitución. Las municiones nuevas
reutilizan el icono técnico de munición existente y se distinguen por nombre.

Los frames Shoot y Reload del protagonista se reutilizan con el progreso del arma
real (0.55/0.9 s y 2.1/2.4 s para las nuevas armas). Idle/Walk/Death y bibliotecas
existentes no se modifican. Falta arte corporal específico: los sprites actuales
conservan poses/equipo de pistola incluso con otra arma; el machete mantiene
Idle/Walk y añade solo el dibujo y arco técnico. No se declara animación corporal
de machete ni arte definitivo. No se usan los paquetes externos locales de
footsoldier/zombi ni se añaden referencias a ellos.

## Pruebas y resultados

```text
godot --headless --path . --editor --import
godot --headless --path . --fixed-fps 60 --script res://tests/phase_six_test.gd
godot --path . --fixed-fps 60 --script res://tests/phase_six_test.gd -- --capture
```

Importación y arranque normal del proyecto correctos, sin nuevos errores ni
advertencias del motor en las ejecuciones finales.

Las trece suites anteriores aprueban **564 comprobaciones**, sin cambios en sus
criterios. Incluyen pistola, entradas, cámara, física, navegación, IA, salud,
inventario, supervivencia, animaciones, recarga, muerte, Game Over y Reintentar.
phase_six_test.gd añade **101 comprobaciones**, todas aprobadas: **665 en total**.

La suite nueva prueba configuración y propiedad inicial, rechazo de armas no
obtenidas, melee frontal y por distancia, varias formas sin doble impacto, poste
real que bloquea golpe, muerte por machete, adquisición real por Areas/contenedor,
clic de incorporación, rechazo de duplicados, reservas separadas, recargas antes
y después de sus duraciones, cancelación sin pérdida, cooldown al cambiar, ocho
impactos de 8 HP, ocho rayos bloqueados por CrateA, alcance, único destello por
descarga, muerte por escopeta sin duplicar bajas, teclas/rueda, UI bloqueada,
disparo durante movimiento, muerte y reinicio completo.

Renderizado real: **107 comprobaciones**, cero fallos y seis capturas en
test-results/phase-six/: inicio, machete, adquisición, revólver, escopeta contra
obstáculo y arsenal completo. Inspeccionadas visualmente; HUD y mochila legibles
a 1280 × 720. Regresión gráfica general: **39 comprobaciones**, cero fallos,
cinco capturas en test-results/phase-four/. No sumar como independientes las
aserciones repetidas en modo gráfico.

Las fixtures recolocan actores, congelan IA para medir daño y crean un objetivo
de 500 HP solo para medir exactamente 8 × 8, sin modificar ningún recurso.
Otra comprobación vuelve a 50 HP y valida una sola baja. Las capturas de galería
de escopeta/machete/adquisición usan recursos del juego y acciones preparadas.
La captura de revólver puede mostrar el aviso de duplicado provocado por la prueba.
Las coordenadas de cámara/mouse se preparan únicamente en las fixtures; la cámara
del juego no cambia.

Documentación: tres capturas principales renovadas y tres nuevas en docs/images/:
arsenal-shotgun.png, arsenal-inventory.png y arsenal-machete.png, optimizadas sin
pérdida. No hay imágenes conceptuales ni descargas para esta fase.

## Pendientes manuales

Sesión prolongada de exploración y combate con las cuatro armas, balance de daño,
dispersión/alcance, comodidad de rueda/teclas, lectura de HUD en otras resoluciones,
poses corporales específicas, panel gráfico del depurador y exportación Windows.
No se declaran aprobadas esas validaciones. No hay fallos funcionales pendientes
detectados en las pruebas ejecutadas. Sin XP, niveles, habilidades, comerciantes,
fabricación, guardado persistente ni multiplayer.

## Archivos de esta fase

Nuevos: scripts/components/equipment_component.gd; scripts/combat/weapon_combat.gd,
spread_combat.gd y melee_combat.gd; scripts/visuals/weapon_visual.gd; sus .uid;
resources/weapons/{Machete,Revolver,Shotgun}.tres;
resources/items/{Machete,Revolver,Shotgun,RevolverAmmo,ShotgunAmmo}.tres;
scenes/world/ArsenalSupplies.tscn; tres SVG provisionales con sus .import;
tests/phase_six_test.gd con .uid; este informe y tres capturas con sus .import.

Modificados: scripts/weapons/{weapon_config,weapon}.gd;
scripts/combat/hitscan_combat.gd; scripts/inventory/{item_definition,item_use}.gd;
scripts/player/player.gd; scripts/visuals/character_visual.gd;
scripts/ui/{hud,inventory_ui}.gd; scripts/main.gd; scenes/player/Player.tscn;
scenes/world/World.tscn; interfaces/HUD.tscn; resources/weapons/BasicPistol.tres;
project.godot (solo seis acciones nuevas); AGENTS.md, README.md,
assets/weapons/README.md, docs/images/README.md y sus tres capturas principales.
Sin cambios en IA, salud, supervivencia, navegación ni bibliotecas de animación.
Las cachés/resultados siguen ignorados. Godot puede generar .import para los
paquetes locales suministrados por el usuario; esos paquetes no forman parte de
la integración ni se publicaron cambios.
