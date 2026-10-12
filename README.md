# Ladrillos Combinatorios

Proyecto de la Unidad III (combinatoria). Es un juego hecho en Godot 4.7 donde se
arman torres y otras construcciones con ladrillos tipo LEGO. En cada nivel hay que
encontrar todas las formas distintas de armar algo sin repetir ninguna, y cada nivel
corresponde a un tema de la unidad.

## De qué va

La ciudad de Brickópolis se desarmó por culpa del "Caos Aleatorio" y hay que
reconstruirla. Son tres mundos (Pradera, Dunas y Base Lunar) con 3 niveles cada uno,
más un jefe final con preguntas de todos los temas.

En cada nivel primero se arman las construcciones en una vista 3D hasta llegar al
total, y después viene una ronda de preguntas con 3 vidas. Con lo que se gana se
consiguen estrellas, que abren los siguientes mundos, y monedas, que sirven para
comprar ayudas en la tienda (vida extra, 50/50 y pista). También hay logros y algunos
bonus, como una construcción dorada escondida en cada nivel.

## Niveles

| # | Tema | Qué se arma | Total |
|---|---|---|---|
| 1 | Regla del producto | torres de 3 con 2 colores | 2³ = 8 |
| 2 | Producto con restricciones | 3 ladrillos, 3 colores, sin dos iguales seguidos | 3·2·2 = 12 |
| 3 | Permutaciones | torres de 2 con 4 piezas distintas | 4!/2! = 12 |
| 4 | Combinaciones | elegir 3 de 5 piezas | C(5,3) = 10 |
| 5 | Permutaciones con repetición | 2 rojos, 1 azul y 1 amarillo | 4!/2! = 12 |
| 6 | Combinaciones con repetición | bolsas de 3 piezas con 3 colores | C(5,2) = 10 |
| 7 | Recurrencias | pilas de altura 6 con placas (1) y ladrillos (3) | hₙ = hₙ₋₁ + hₙ₋₃ → 6 |
| 8 | Inclusión–exclusión | torres de 4 que usen los 3 colores | 81 − 48 + 3 = 36 |
| 9 | Lema de Burnside | formas de unir dos ladrillos 2×4 | (46 + 2)/2 = 24 |

Cada nivel tiene una pestaña de *Teoría* con la explicación, y las demostraciones
más completas están en [`docs/FUNDAMENTACION.md`](docs/FUNDAMENTACION.md).

Para comprobar que las fórmulas dan bien, el juego también genera todas las
configuraciones a lo bruto y quita las repetidas, y eso se compara con el resultado
de la fórmula (`scripts/enumerador.gd` y `scripts/combinatoria.gd`). Las preguntas se
generan con números al azar en `scripts/preguntas.gd`.

## Cómo jugarlo

**Android:** pasar `LadrillosCombinatorios.apk` al celular y abrirlo. Android pide
permiso para instalar apps de fuentes desconocidas. Funciona en Android 7 o superior
con procesador de 64 bits (casi cualquier celular de los últimos años).

**Computadora:** abrir Godot 4.7, darle a *Importar*, elegir `project.godot` y
presionar F5.

**Navegador:** se puede exportar a web, pero Godot solo arranca con HTTPS o desde
localhost. Para probarlo está `servir.py`.

### Controles

- Botones de colores o teclas 1–5 para poner piezas, Retroceso para quitar la última.
- En el nivel 9: flechas/WASD para mover, R para girar y Enter para registrar.
- Arrastrar en la vista 3D gira la cámara; la rueda o pellizcar hace zoom.
- En las preguntas: clic o teclas 1–4.

## Archivos

- `scenes/`: menú, nivel, preguntas y tienda.
- `scripts/`: la lógica (fórmulas, enumeración, niveles, preguntas, progreso,
  la escena 3D, etc.).
- `tests/`: pruebas automáticas.
- `exportar_apk.sh`: genera el APK firmado. Necesita el SDK de Android, Java y la
  llave de firma, que no está en el repo.

Para correr las pruebas:

```bash
godot --headless --path . -s res://tests/pruebas.gd
```

## Créditos

- Fuentes Inter, Nunito y DejaVu Sans (licencias en `fonts/`).
- El dato del nivel 9 sale de S. Eilers, *The LEGO counting problem* (2016).
- LEGO® es una marca de LEGO Group; esto es solo un proyecto de clase.
