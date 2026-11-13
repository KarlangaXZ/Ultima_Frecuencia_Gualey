# Zombi base — animaciones técnicas provisionales

96 PNG transparentes de 128×128 píxeles: idle 16, walk 32, attack 24, death 24. Cuatro direcciones.

**Importante:** las poses originales son pequeñas y las animaciones se sintetizaron con desplazamientos y giros. Son una base técnica para probar SpriteFrames, no arte final. Revisar visualmente cada dirección, especialmente muerte y ataque, y conservar el atlas anterior si la integración empeora la apariencia.

Extraer `zombies/base/` bajo `assets/characters/` (sin sobrescribir escenas ni scripts). Antes de integrarlo, verificar hashes del MANIFEST, direcciones, fondo alfa, pivote, escala y ausencia de frames vacíos. Si la calidad no alcanza, no hacer la integración. No modificar gameplay.
