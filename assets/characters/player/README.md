# Arte final del jugador

`idle/PlayerIdleDown.tres` integra cuatro PNG reales, 128 × 128, a 4 FPS, en bucle.
La misma biblioteca también integra walk_down: ocho PNG 128 × 128 a 8 FPS, en bucle.
Estado actualizado: idle real en cuatro direcciones y walk real en down/up/right.
walk_left sigue provisional por restos de fondo en sus PNG. Ver el
[mapa de asignaciones corregidas](../../../docs/player_directions_integration.md).
Para ampliar el arte, reemplazar `Player/Visual.sheet` o
asignar `Player/Visual.animation_library` (SpriteFrames) desde el inspector.
Conservar `Player`, `HealthComponent`, `Aim` y el cuerpo físico.
Contrato de animaciones: [guía de recursos](../../README.md).

Diagnóstico del paquete y plan de producción: [auditoría de animaciones](../../../docs/player_animation_audit.md).
Integrados actualmente: 4 frames idle_down y 8 walk_down (12 de 112). La auditoría
enlazada corresponde al inventario anterior a incorporar walk_down. Las referencias
en `draft/` no son spritesheets finales y no deben integrarse automáticamente.
