# Zombi base — arte técnico provisional

base/ZombieBaseFrames.tres reúne 96 PNG para Idle, Walk, Attack y Death, en cuatro
direcciones. MANIFEST.json está en esta carpeta; previews/ contiene referencias.
No es arte definitivo: hay poses repetidas y movimientos simplificados.

Zombie/Visual usa zombie_visual.gd, biblioteca completa, escala 0.85 y offset
(0,-46). La animación de ataque solo observa el cooldown; no controla daño.
Conservar cuerpo físico, IA y flujo de desactivación.
[Informe y validación](../../../docs/zombie_base_integration.md).
