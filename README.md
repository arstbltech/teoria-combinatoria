# Ladrillos Combinatorios

Juego educativo hecho en **Godot 4.7** para aprender la **Unidad III de
combinatoria** armando torres y construcciones con ladrillos tipo LEGO. Se instala
en el celular como **APK de Android** y también funciona en el navegador y en la
computadora.

## La historia

**Brickópolis** era una ciudad hecha por completo de ladrillos, hasta que llegó el
**Caos Aleatorio** y revolvió todas sus piezas. El jugador es el **Maestro
Constructor**: para reconstruir cada zona tiene que descubrir *todas las formas
distintas* de armar cada estructura, sin repetir ninguna. Ahí entra la combinatoria.
Recorre tres mundos y, al final, enfrenta al Caos Aleatorio en persona.

## Mundos (ambientes)

Cada mundo es un ambiente 3D distinto, con su cielo, su suelo, su luz y una
decoración armada con ladrillos. Se desbloquean al reunir estrellas.

| Mundo | Ambiente | Niveles | Se abre con |
|---|---|---|---|
| 1. Pradera Bloque | Día, pasto, árboles, casa, flores y nubes de ladrillos | 1 – 3 | — |
| 2. Dunas Doradas | Desierto, pirámide escalonada, cactus, rocas y sol | 4 – 6 | 2 ★ |
| 3. Base Lunar | Noche estrellada, cohete, antena, cráteres y la Tierra en el cielo | 7 – 9 | 5 ★ |
| Jefe final | El Caos Aleatorio: 10 preguntas de todos los temas | — | con la Base Lunar |

## Mecánicas

- **Menú:** mapa de Brickópolis con los mundos, sus niveles, el jefe final, la
  tienda de premios, la historia y la ayuda.
- **Construir:** en cada nivel se arman todas las configuraciones distintas posibles.
  El total sale de un teorema de combinatoria y se comprueba por fuerza bruta.
- **Vidas:** cada ronda de preguntas empieza con 3 corazones. Cada error cuesta uno y
  sin vidas se pierde la ronda.
- **Monedas:**

  | Acción | Monedas |
  |---|---|
  | Construcción nueva | 1 |
  | Completar un reto | 20 |
  | Respuesta correcta | 5 (10 con racha) |
  | Ronda perfecta | 15 |
  | Vencer al jefe | 30 |
  | Cofre de cada mundo | 50 |
  | Cada logro | 15 |

- **Bonus:**
  - Cada nivel esconde una configuración **dorada** que vale +10 monedas.
  - Una **racha** de 3 aciertos duplica las monedas de las respuestas.
  - Al completar los retos de un mundo se abre su **cofre**.
- **Estrellas:** 3 por nivel (completar el reto, acertar ⅔ de las preguntas,
  acertarlas todas) y 3 por el jefe final. Sirven para desbloquear mundos.
- **Premios:**
  - Una **tienda** donde se compran objetos con monedas: *vida extra*, *comodín 50/50*
    y *pista*.
  - **12 logros**, entre ellos «Primer ladrillo», «Imparable», «Buscador de oro»,
    «Orden restaurado» y «Sin un rasguño».
- **Preguntas de la materia:** se generan con números al azar sobre cada tema de la
  Unidad III. Las opciones incorrectas imitan errores típicos.

| Nivel | Concepto | Reto | Fórmula |
|---|---|---|---|
| 1. Torres de colores | Regla del producto | torres de 3 con 2 colores | kⁿ = 2³ = 8 |
| 2. Vecinos distintos | Producto con restricciones | 3 ladrillos, 3 colores, sin vecinos iguales | k(k−1)ⁿ⁻¹ = 12 |
| 3. Piezas únicas | Permutaciones | torres de 2 con 4 piezas únicas | 4!/2! = 12 |
| 4. Elige tu set | Combinaciones | 3 de 5 piezas, sin orden | C(5,3) = 10 |
| 5. Colores repetidos | Permutaciones con repetición | 2 rojos, 1 azul, 1 amarillo | 4!/(2!·1!·1!) = 12 |
| 6. La bolsa de piezas | Combinaciones con repetición | bolsas de 3 con 3 colores | C(5,2) = 10 |
| 7. Altura exacta | Recurrencias | pilas de altura 6 con placas (1) y ladrillos (3) | hₙ = hₙ₋₁ + hₙ₋₃ → 6 |
| 8. Todos los colores | Inclusión–exclusión | torres de 4 que usan los 3 colores | 81 − 48 + 3 = 36 |
| 9. Dos ladrillos 2×4 | Lema de Burnside | todas las formas de unir dos 2×4 | (46 + 2)/2 = 24 |

Las demostraciones formales están en [`docs/FUNDAMENTACION.md`](docs/FUNDAMENTACION.md)
y dentro del juego, en la pestaña *Teoría* de cada nivel.

## Instalar en el celular (Android)

El APK está en `build/android/LadrillosCombinatorios.apk`. Funciona en Android 7.0
o superior; pesa 77 MB porque incluye versiones para celulares ARM de 32 y 64 bits
y para emuladores x86_64.

1. Copia el archivo `.apk` al celular (cable USB, Google Drive, WhatsApp, etc.).
2. Ábrelo desde el administrador de archivos del celular.
3. Android preguntará si permites instalar apps de esa fuente: actívalo
   (*Ajustes → Instalar apps desconocidas*) y pulsa **Instalar**.
4. Aparece como **Ladrillos Combinatorios** en el cajón de aplicaciones.

Con el celular conectado por USB y la depuración USB activada también sirve:
`adb install build/android/LadrillosCombinatorios.apk`.

### Volver a generar el APK

Hace falta:
- Godot 4.7 con sus plantillas de exportación.
- El Android SDK en `~/Android/Sdk` (command-line tools, `build-tools` y
  `platform-tools`).
- Java.
- La llave de firma en `~/.local/share/ladrillos-combinatorios/`
  (`release.keystore` y `release.keystore.txt`, con el alias y la contraseña).

Con eso:

```bash
./exportar_apk.sh /ruta/a/godot      # deja el APK en build/android/
```

La llave de firma no está en el repositorio a propósito. Guárdala: para *actualizar*
el juego en un celular donde ya está instalado, el nuevo APK debe firmarse con la
misma llave. Si la pierdes, basta con desinstalar el juego y volver a instalarlo.

Si la creas de nuevo:

```bash
keytool -genkeypair -keystore ~/.local/share/ladrillos-combinatorios/release.keystore \
  -alias ladrillos -keyalg RSA -keysize 2048 -validity 10000
# y guarda en release.keystore.txt las líneas «alias=ladrillos» y «password=…»
```

Nota para el emulador de Android: usa la GPU de la computadora
(`emulator -avd … -gpu host`). Con la GPU por software (SwiftShader) los shaders de
Godot superan un límite de ese emulador y la pantalla queda gris; en celulares
reales eso no pasa.

## Abrir y jugar en el escritorio

1. Descarga **Godot 4.7** (versión estándar, no la .NET) desde <https://godotengine.org/download>.
   En CachyOS/Arch: `sudo pacman -S godot`.
2. Abre Godot, pulsa **Importar** y elige el archivo `project.godot` de esta carpeta.
3. Pulsa **F5** (o el botón ▶) para jugar.

El proyecto usa el renderer **Compatibility**, que funciona en la web y en celulares.
Todo el código está en **GDScript**, porque los proyectos en C# no se pueden exportar a la web.

La interfaz se adapta a la pantalla: en computadora usa dos columnas y en un
celular en vertical pasa a una sola columna desplazable, con botones del tamaño
de un dedo y zoom con dos dedos en la vista 3D.

## Versión web

```bash
godot --headless --path . --export-release "Web" build/web/index.html
python3 servir.py            # http://localhost:8000 en esta computadora
python3 servir.py --https    # para entrar desde el celular u otra PC de la misma red
```

Godot sólo arranca en el navegador desde un **contexto seguro**: HTTPS o
`http://localhost`. Abrirlo con `http://0.0.0.0:8000` o con la IP de la red da el error
*«Secure Context - Check web server configuration (use HTTPS)»*. Con `--https` el
script crea un certificado propio; la primera vez el navegador pide aceptarlo
(*Avanzado → Aceptar el riesgo y continuar*).

Para publicarlo, sube el *contenido* de `build/web/` a itch.io (proyecto HTML),
GitHub Pages o Netlify. Los tres usan HTTPS.

## Controles

- Botones de color o teclas **1–5**: poner una pieza. **Retroceso**: quitar la última.
- Nivel 9: cruceta o **flechas/WASD** para mover el ladrillo, **R** para girarlo,
  **G** para ver su gemela girada 180°, **Enter** para registrar.
- Arrastrar sobre la vista 3D gira la cámara; la rueda del ratón o pellizcar acercan.
- Preguntas: toque, clic o teclas **1–4**; **Enter** pasa a la siguiente.

## Cómo aplica el juego la combinatoria

1. **Contador.** El total de cada reto es el valor de la fórmula del teorema
   (`scripts/combinatoria.gd`).
2. **Forma canónica.** Cada construcción se reduce a un representante: la lista
   ordenada si el orden no importa, o la menor entre una posición y su giro de 180°
   en el nivel 9. Dos construcciones son la misma si tienen la misma forma canónica,
   así que el juego cuenta clases de equivalencia (órbitas).
3. **Enumeración por fuerza bruta.** `scripts/enumerador.gd` genera todas las
   configuraciones aplicando la *definición*, no la fórmula. Así se arma la galería
   y la pestaña *Comprobar* verifica la fórmula con otros parámetros.
4. **Preguntas.** `scripts/preguntas.gd` genera preguntas con números al azar. Las
   opciones incorrectas imitan errores típicos: usar P en vez de C, olvidar una
   restricción u olvidar la simetría.

## Estructura

```
project.godot              configuración (renderer Compatibility, autoload Juego)
export_presets.cfg         preajustes de exportación Web y Android
exportar_apk.sh            genera el APK firmado
servir.py                  sirve build/web por HTTP (localhost) o HTTPS (red local)
scenes/                    menú (mapa), nivel (constructor 3D), preguntas y premios
scripts/juego.gd           progreso, monedas, objetos, logros, avisos y navegación
scripts/mundos.gd          la historia y los tres mundos
scripts/premios.gd         economía, tienda, logros y pistas
scripts/vista_ladrillos.gd escena 3D: ambientes, ladrillos, studs y cámara
scripts/combinatoria.gd    fórmulas cerradas de los teoremas
scripts/enumerador.gd      enumeración por fuerza bruta, reglas y formas canónicas
scripts/niveles.gd         datos de los niveles, teoría y laboratorio
scripts/preguntas.gd       generador de preguntas
scripts/estilo.gd          colores, tipografía y tema visual
scripts/icono.gd           íconos vectoriales (moneda, corazón, trofeo…)
scripts/miniatura.gd       dibujos 2D de la galería
iconos_android/            íconos del lanzador de Android
tests/                     pruebas automáticas
docs/FUNDAMENTACION.md     demostraciones formales
fonts/                     Inter (texto), Nunito (títulos) y DejaVu Sans (símbolos matemáticos)
```

## Pruebas

```bash
# Teoremas contra fuerza bruta, niveles, preguntas, mundos y premios (3545 pruebas)
godot --headless --path . -s res://tests/pruebas.gd

# Recorre el juego como un jugador: historia, los 9 niveles, monedas y logros,
# compra en la tienda, comodines, una ronda perdida por falta de vidas y el jefe final
godot --headless --path . -- --prueba-humo
```

La prueba de humo usa un archivo de progreso aparte y no toca el del jugador.

## Créditos

- Fuentes: [Inter](https://rsms.me/inter/) y [Nunito](https://github.com/googlefonts/nunito) (SIL Open Font License) y
  [DejaVu Sans](https://dejavu-fonts.github.io/) (licencia libre). Ver los archivos `fonts/LICENSE-*.txt`.
- Dato histórico del nivel 9: S. Eilers, *The LEGO counting problem*, American Mathematical Monthly (2016).
- LEGO® es una marca de LEGO Group, que no patrocina ni respalda este proyecto educativo.
