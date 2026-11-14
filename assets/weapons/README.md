# Arte final de armas

Carpeta reservada. Sustituir la textura de `Player/Aim/Barrel`, conservando
la orientación hacia la derecha y sin alterar el origen del hitscan.
Desde fase 6 la asignación se realiza en WeaponConfig.visual e icon; WeaponVisual
actualiza Barrel al seleccionar. El dibujo de pistola existente se conserva.
Machete, revólver y escopeta usan SVG manuales provisionales en
assets/placeholders/weapons/temp_{machete,revolver,shotgun}.svg. No son arte final
ni requieren paquetes externos. No hay nuevas animaciones corporales; no cambiar
colisiones, Aim ni origen físico para acomodar futuros sprites.
[Guía de recursos](../README.md).
