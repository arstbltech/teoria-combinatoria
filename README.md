# Ladrillos Combinatorios

Juego educativo hecho en **Godot 4.7** en el que se aprende teoría combinatoria
armando torres y construcciones con ladrillos tipo LEGO. Funciona en escritorio
y en el navegador.

Cada nivel corresponde a un teorema. El jugador construye configuraciones en 3D y
el juego cuenta cuántas distintas encontró. El total sale de una fórmula demostrada
en la pestaña *Teoría* y comprobada por fuerza bruta en la pestaña *Comprobar*.
Después vienen preguntas de combinatoria generadas al azar.

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
y también dentro del juego, en la pestaña *Teoría* de cada nivel.

## Abrir y jugar en el escritorio

1. Descarga **Godot 4.7** (versión estándar, no la .NET) desde <https://godotengine.org/download>.
   En CachyOS/Arch: `sudo pacman -S godot`.
2. Abre Godot, pulsa **Importar** y elige el archivo `project.godot` de esta carpeta.
3. Pulsa **F5** (o el botón ▶) para jugar.

El proyecto usa el renderer **Compatibility**, que es el único que funciona en la web.
Todo el código está en **GDScript**, porque los proyectos en C# no se pueden exportar a la web.

## Versión web

### Exportar

1. En Godot: **Editor → Administrar plantillas de exportación → Descargar e instalar**
   (sólo la primera vez).
2. **Proyecto → Exportar…** El preajuste **Web** ya está configurado, con
   *Thread Support* desactivado para que no haga falta configurar cabeceras
   especiales en el servidor.
3. Pulsa **Exportar proyecto** y guarda en `build/web/index.html`.

Desde la terminal se hace lo mismo con:

```bash
godot --headless --path . --export-release "Web" build/web/index.html
```

La carpeta `build/web/` ya incluye una exportación lista: unos 40 MB, que quedan
en unos 9 MB cuando el servidor los envía comprimidos.

### Probar en tu computadora

Godot sólo arranca en el navegador desde un **contexto seguro**: HTTPS, o bien
`http://localhost`. Si abres el juego con `http://0.0.0.0:8000` (el enlace que imprime
`python3 -m http.server`) o con la IP de la red (`http://192.168.…`), aparece este error:

> The following features required to run Godot projects on the Web are missing:
> Secure Context - Check web server configuration (use HTTPS)

Además, el juego no abre con doble clic sobre `index.html`. Usa el script incluido:

```bash
python3 servir.py            # abre http://localhost:8000 en esta computadora
python3 servir.py --https    # para entrar desde el celular u otra PC de la misma red
```

Con `--https` el script crea un certificado autofirmado e imprime las direcciones
`https://<tu IP>:8443`. La primera vez el navegador mostrará una advertencia; elige
**Avanzado → Aceptar el riesgo y continuar** (o **Continuar al sitio**). Si el otro
dispositivo no logra conectarse, revisa que el firewall permita el puerto 8443.

Otra opción es el botón **Ejecutar en el navegador** del editor (ícono de HTML5, arriba
a la derecha), que también sirve el juego en `localhost`.

### Publicar

itch.io y GitHub Pages ya usan HTTPS, así que ahí no aparece el error del contexto seguro.

- **itch.io:** comprime el *contenido* de `build/web/` en un `.zip` (con `index.html`
  en la raíz), créalo como proyecto *HTML* y marca *This file will be played in the browser*.
- **GitHub Pages:** sube el contenido de `build/web/` a una rama o carpeta publicada.

## Controles

- Botones de color o teclas **1–5**: poner una pieza. **Retroceso**: quitar la última.
- Nivel 9: **flechas/WASD** mueven el ladrillo, **R** lo gira, **G** muestra su gemela
  girada 180°, **Enter** registra.
- Arrastrar sobre la vista 3D gira la cámara; la rueda acerca.
- Preguntas: clic o teclas **1–4**; **Enter** pasa a la siguiente.

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
project.godot            configuración (renderer Compatibility, autoload Juego)
export_presets.cfg       preajuste de exportación Web
servir.py                sirve build/web por HTTP (localhost) o HTTPS (red local)
scenes/                  menú, nivel (constructor 3D) y preguntas
scripts/combinatoria.gd  fórmulas cerradas de los teoremas
scripts/enumerador.gd    enumeración por fuerza bruta, reglas y formas canónicas
scripts/niveles.gd       datos de los niveles, teoría y laboratorio
scripts/preguntas.gd     generador de preguntas
scripts/vista_ladrillos.gd  escena 3D (ladrillos, studs, cámara)
scripts/miniatura.gd     dibujos 2D de la galería
scripts/estilo.gd        colores y tema visual
scripts/juego.gd         progreso guardado y navegación
tests/                   pruebas automáticas
docs/FUNDAMENTACION.md   demostraciones formales
fonts/                   DejaVu Sans (incluye los símbolos matemáticos para la web)
```

## Pruebas

```bash
# Cada teorema contra la fuerza bruta, los niveles y el generador de preguntas (3487 pruebas)
godot --headless --path . -s res://tests/pruebas.gd

# Recorre todas las pantallas del juego simulando a un jugador
godot --headless --path . -- --prueba-humo
```

La prueba de humo usa un archivo de progreso aparte y no toca el del jugador.

## Créditos

- Fuente: [DejaVu Sans](https://dejavu-fonts.github.io/), con licencia libre (ver `fonts/LICENSE-DejaVu.txt`).
- Dato histórico del nivel 9: S. Eilers, *The LEGO counting problem*, American Mathematical Monthly (2016).
- LEGO® es una marca de LEGO Group, que no patrocina ni respalda este proyecto educativo.
