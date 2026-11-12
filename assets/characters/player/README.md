# Arte final del jugador

`idle/PlayerIdleDown.tres` integra cuatro PNG reales, 128 × 128, a 4 FPS, en bucle.
Solo idle_down está reemplazado; las demás animaciones continúan provisionales.
Para ampliar el arte, reemplazar `Player/Visual.sheet` o
asignar `Player/Visual.animation_library` (SpriteFrames) desde el inspector.
Conservar `Player`, `HealthComponent`, `Aim` y el cuerpo físico.
Contrato de animaciones: [guía de recursos](../../README.md).

Diagnóstico del paquete y plan de producción: [auditoría de animaciones](../../../docs/player_animation_audit.md).
Disponibles: 4 frames idle_down de 112 objetivo; faltan 108. Las referencias
en `draft/` no son spritesheets finales y no deben integrarse automáticamente.
