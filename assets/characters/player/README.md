# Arte final del jugador

Shoot corregido ya integrado en cuatro direcciones, provisional. Se dispara por
shot_fired y dura la cadencia real, sin duplicar efectos. [Validación](../../../docs/shoot_final_integration.md).
El rechazo histórico del paquete anterior ya no aplica a estos PNG corregidos.

Acciones de fase 4.3: PlayerActionAnimations.tres integra Reload/Death técnicos
provisionales en cuatro direcciones. Shoot descartado por calidad y destello
incrustado. [Informe](../../../docs/phase_4_3_actions.md). No es arte definitivo.

`idle/PlayerIdleDown.tres` integra cuatro PNG reales, 128 × 128, a 4 FPS, en bucle.
La misma biblioteca también integra walk_down: ocho PNG 128 × 128 a 8 FPS, en bucle.
Estado actualizado V2: idle y walk reales en las cuatro direcciones.
walk_left usa player_walk_left_00–07.png a 8 FPS; walk_right conserva sus PNG
anteriores en walk/legacy_right/. Ver [validación V2](../../../docs/walk_left_v2_validation.md) y el
[mapa de asignaciones corregidas](../../../docs/player_directions_integration.md).
Para ampliar el arte, reemplazar `Player/Visual.sheet` o
asignar `Player/Visual.animation_library` (SpriteFrames) desde el inspector.
Conservar `Player`, `HealthComponent`, `Aim` y el cuerpo físico.
Contrato de animaciones: [guía de recursos](../../README.md).

Diagnóstico del paquete y plan de producción: [auditoría de animaciones](../../../docs/player_animation_audit.md).
Integrados actualmente: 4 frames idle_down y 8 walk_down (12 de 112). La auditoría
enlazada corresponde al inventario anterior a incorporar walk_down. Las referencias
en `draft/` no son spritesheets finales y no deben integrarse automáticamente.
