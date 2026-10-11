# Fundamentación matemática de *Ladrillos Combinatorios*

Este documento reúne los modelos, teoremas y demostraciones en los que se basa
cada nivel del juego, y explica cómo los aplica el código. Las mismas
demostraciones aparecen dentro del juego, en la pestaña *Teoría*.

Notación: $[n] = \{1, \dots, n\}$, $|A|$ es el cardinal de $A$ y $\binom{n}{r}$ el
coeficiente binomial.

## 0. Principios de conteo

Sean $A$ y $B$ conjuntos finitos.

- **P1 (suma).** Si $A \cap B = \varnothing$, entonces $|A \cup B| = |A| + |B|$.
- **P2 (producto).** $|A \times B| = |A| \cdot |B|$.
- **P3 (biyección).** Si existe una biyección $f : A \to B$, entonces $|A| = |B|$.
- **P4 (división).** Si $f : A \to B$ es sobreyectiva y $|f^{-1}(b)| = m$ para todo $b \in B$,
  entonces $|A| = m\,|B|$.

*Demostración de P4.* $A = \bigsqcup_{b \in B} f^{-1}(b)$ es una unión disjunta de $|B|$
conjuntos de $m$ elementos; por P1, $|A| = m|B|$. ∎

## 1. Torres de colores: regla del producto

**Modelo.** Sea $C$ un conjunto de colores con $|C| = k$. Una torre de $n$ ladrillos es una
tupla $(c_1, \dots, c_n) \in C^n$, donde $c_1$ es el ladrillo de abajo.

**Teorema 1.** $|C^n| = k^n$.

*Demostración.* Por inducción sobre $n$. Para $n = 1$, $|C| = k$. Para $n > 1$, la función
$(c_1, \dots, c_n) \mapsto ((c_1, \dots, c_{n-1}), c_n)$ es una biyección $C^n \to C^{n-1} \times C$.
Por P3, P2 y la hipótesis de inducción, $|C^n| = k^{n-1} \cdot k = k^n$. ∎

*En el juego:* $k = 2$, $n = 3$, así que hay $2^3 = 8$ torres.

## 2. Vecinos distintos: producto con restricciones

**Modelo.** $A_n = \{ (c_1, \dots, c_n) \in C^n : c_i \neq c_{i+1},\ 1 \le i < n \}$.

**Teorema 2.** Si $k \ge 2$, entonces $|A_n| = k(k-1)^{n-1}$.

*Demostración.* $|A_1| = k$. Para $n \ge 2$ sea $\pi : A_n \to A_{n-1}$ la función que quita
el último ladrillo. Está bien definida y es sobreyectiva, porque como $k \ge 2$ toda torre
de $A_{n-1}$ admite encima un color distinto de $c_{n-1}$. La fibra de $(c_1, \dots, c_{n-1})$
es $\{(c_1, \dots, c_{n-1}, c) : c \in C \setminus \{c_{n-1}\}\}$, que tiene $k - 1$ elementos.
Por P4, $|A_n| = (k-1)|A_{n-1}|$, y por inducción $|A_n| = k(k-1)^{n-1}$. ∎

*En el juego:* $k = 3$, $n = 3$, así que hay $3 \cdot 2^2 = 12$ torres. Un error típico es
responder $(k-1)^n$.

## 3. Piezas únicas: permutaciones

**Modelo.** $B$ es un conjunto de $n$ piezas distintas. Una torre de $r$ piezas sin repetir
es una función inyectiva $[r] \to B$.

**Teorema 3.** El número de torres es $P(n, r) = n(n-1)\cdots(n-r+1) = \dfrac{n!}{(n-r)!}$.

*Demostración.* $P(n, 1) = n$. Para $r \ge 2$, quitar la pieza de arriba es una sobreyección
de las torres de $r$ piezas sobre las de $r - 1$, y cada fibra son las $n - (r - 1)$ piezas
no usadas. Por P4, $P(n, r) = (n - r + 1)\,P(n, r-1)$. ∎

*En el juego:* $n = 4$, $r = 2$, así que hay $4 \cdot 3 = 12$ torres.

## 4. Elige tu set: combinaciones

**Modelo.** Una selección es un subconjunto $S \subseteq B$ con $|S| = r$, y su número es $\binom{n}{r}$.

**Teorema 4.** $\binom{n}{r} = \dfrac{n!}{r!\,(n-r)!}$.

*Demostración (doble conteo).* Sea $f$ la función que lleva cada torre de $r$ piezas
distintas a su conjunto de piezas. Es sobreyectiva y la fibra de $S$ son los $r!$
ordenamientos de $S$ (teorema 3 con $n = r$). Por P4, $P(n, r) = r!\binom{n}{r}$. ∎

*En el juego:* $\binom{5}{3} = 10$, frente a $P(5, 3) = 60$ torres.

## 5. Colores repetidos: permutaciones con repetición

**Modelo.** Hay $a_i$ ladrillos idénticos del color $i$ y $n = a_1 + \cdots + a_k$.

**Teorema 5.** El número de torres que usan todos los ladrillos es $\dfrac{n!}{a_1!\,a_2!\cdots a_k!}$.

*Demostración.* Si se etiquetan los ladrillos de cada color, hay $n!$ torres de piezas
distintas. La función "borrar etiquetas" es sobreyectiva y cada fibra tiene
$a_1! \cdots a_k!$ elementos, que son las permutaciones de etiquetas dentro de cada color
(P2 y teorema 3). Se aplica P4. ∎

*En el juego:* $\dfrac{4!}{2!\,1!\,1!} = 12$.

## 6. La bolsa de piezas: combinaciones con repetición

**Modelo.** Una bolsa de $r$ ladrillos con $k$ colores es una solución de
$x_1 + \cdots + x_k = r$ con $x_i \in \mathbb{Z}_{\ge 0}$.

**Teorema 6.** Hay $\dbinom{r + k - 1}{k - 1}$ bolsas.

*Demostración (estrellas y barras).* A $(x_1, \dots, x_k)$ se le asocia la palabra
$\star^{x_1} \mid \star^{x_2} \mid \cdots \mid \star^{x_k}$, de longitud $r + k - 1$ y con
$k - 1$ barras. Contar las estrellas entre barras es la función inversa, así que se trata
de una biyección (P3). La palabra queda determinada por las posiciones de las barras,
que se eligen de $\binom{r+k-1}{k-1}$ formas (teorema 4). ∎

**Corolario.** Con al menos un ladrillo de cada color hay $\binom{r-1}{k-1}$ bolsas
(cambio $y_i = x_i - 1$).

*En el juego:* $\binom{5}{2} = 10$. El juego muestra la palabra de estrellas y barras de cada bolsa.

## 7. Altura exacta: recurrencias

**Modelo.** Medida en placas, una placa mide 1 y un ladrillo 3. $h_n$ es el número de
sucesiones de placas y ladrillos de altura total $n$.

**Teorema 7.** $h_0 = h_1 = h_2 = 1$ y $h_n = h_{n-1} + h_{n-3}$ para $n \ge 3$. Además,
$$h_n = \sum_{j=0}^{\lfloor n/3 \rfloor} \binom{n - 2j}{j}.$$

*Demostración.*

- **Recurrencia.** Si $n < 3$ sólo caben placas. Si $n \ge 3$, se separan las pilas según la
  pieza de arriba (P1). Quitar esa pieza da una biyección con las pilas de altura $n - 1$
  si es una placa, o $n - 3$ si es un ladrillo (P3).
- **Forma cerrada.** Una pila con $j$ ladrillos tiene $n - 3j$ placas, es decir, $n - 2j$
  piezas. Queda determinada por las posiciones de los ladrillos, que son $\binom{n-2j}{j}$.
  Se suma sobre $j$ (P1). ∎

Valores: $1, 1, 1, 2, 3, 4, 6, 9, 13, 19, 28, 41, 60, \dots$ *En el juego:* $h_6 = 6$.

## 8. Todos los colores: inclusión–exclusión

**Teorema 8.** El número de torres de $n$ ladrillos que usan los $k$ colores, es decir, de
funciones sobreyectivas $[n] \to C$, es
$$\sum_{j=0}^{k} (-1)^j \binom{k}{j} (k-j)^n.$$

*Demostración.* Sea $A_i$ el conjunto de torres que no usan el color $i$. Buscamos
$k^n - |A_1 \cup \cdots \cup A_k|$. Toda intersección de $j$ de esos conjuntos tiene
$(k-j)^n$ elementos (teorema 1) y hay $\binom{k}{j}$ intersecciones así. Por el principio
de inclusión–exclusión,
$|A_1 \cup \cdots \cup A_k| = \sum_{j=1}^{k} (-1)^{j+1}\binom{k}{j}(k-j)^n$. ∎

*En el juego:* $3^4 - 3 \cdot 2^4 + 3 \cdot 1^4 - 0 = 36$.

## 9. Dos ladrillos 2×4: lema de Burnside

**Modelo.** La rejilla de studs es $\mathbb{Z}^2$. El ladrillo de abajo es
$B = [0,2] \times [0,4]$. Sea $X$ el conjunto de rectángulos $2 \times 4$ con vértices
enteros, paralelos o perpendiculares a $B$, cuya intersección con $B$ tiene área positiva.

**Lema 9.** $|X| = 46$. Para ladrillos $a \times b$ con $a \neq b$,
$|X| = (2a-1)(2b-1) + (a+b-1)^2$.

*Demostración.*

- Paralelo: $[x, x+2] \times [y, y+4]$ corta a $B$ con área positiva si y sólo si
  $-2 < x < 2$ y $-4 < y < 4$, lo que da $3 \cdot 7 = 21$ posiciones.
- Perpendicular: $[x, x+4] \times [y, y+2]$ corta a $B$ si y sólo si $-4 < x < 2$ y
  $-2 < y < 4$, lo que da $5 \cdot 5 = 25$.

Por P1, $|X| = 46$. ∎

**Simetría.** Dos construcciones son iguales si una se obtiene de la otra con un giro
alrededor de un eje vertical. Los reflejos no cuentan, porque un modelo y su imagen
especular son físicamente distintos. El giro debe fijar $B$, que no es cuadrado, así que
$G = \{e, \rho\}$ con $\rho(u, v) = (2 - u, 4 - v)$.

**Lema de Burnside.** Si $G$ es un grupo finito que actúa sobre $X$, entonces
$$|X/G| = \frac{1}{|G|} \sum_{g \in G} |\mathrm{Fix}(g)|.$$

*Demostración.* Se cuentan de dos formas los pares $(g, x)$ con $g \cdot x = x$:
$$\sum_{g} |\mathrm{Fix}(g)| = \sum_{x} |\mathrm{Stab}(x)| = \sum_{x} \frac{|G|}{|\mathrm{Orb}(x)|} = |G| \cdot |X/G|,$$
por el teorema órbita–estabilizador, y porque cada órbita $O$ aporta $|O| \cdot \frac{1}{|O|} = 1$. ∎

**Teorema 10.** Hay exactamente **24** formas de unir dos ladrillos 2×4.

*Demostración.* $|\mathrm{Fix}(e)| = 46$. $\rho$ lleva un rectángulo de centro $c$ a otro de la
misma orientación con centro $\rho(c)$, así que $\rho(T) = T$ si y sólo si $c = (1, 2)$. Hay
dos rectángulos así: $[0,2]\times[0,4]$ y $[-1,3]\times[1,3]$. Por tanto
$|X/G| = \frac{46 + 2}{2} = 24$. ∎

*Generalización.* Para $a \neq b$, $\rho$ fija 2 posiciones si $a \equiv b \pmod 2$ y 1 si no,
porque la perpendicular centrada exige que $(a - b)/2$ sea entero. Para ladrillos cuadrados
$a \times a$, el grupo tiene 4 giros, cada giro no trivial fija sólo la posición centrada, y
hay $\frac{(2a-1)^2 + 3}{4}$ construcciones.

**Teorema 11.** Hay $\dfrac{46^{n-1} + 2^{n-1}}{2}$ torres de $n$ ladrillos 2×4 con uno por nivel.

*Demostración.* Cada ladrillo se apoya en el anterior de 46 formas y ladrillos de niveles
distintos no chocan, así que por P2 hay $46^{n-1}$ torres. $\rho$ fija una torre si y sólo si
todos sus ladrillos están centrados en $(1, 2)$. Eso deja 2 orientaciones por nivel, todas
válidas porque se solapan en $[0,2]\times[1,3]$, y en total $2^{n-1}$ torres fijas. Se aplica
Burnside. ∎

Para $n = 3$ hay $1060$ torres y para $n = 6$ hay $102\,981\,504$. En 1974 LEGO publicó
$102\,981\,500$ formas para seis ladrillos, contando sólo torres. Contando todas las
construcciones, S. Eilers obtuvo por computadora $915\,103\,765$ (*The LEGO counting
problem*, Amer. Math. Monthly, 2016). Para ese caso general no se conoce una fórmula cerrada.

## 10. Cómo lo usa el juego

| Idea matemática | Implementación |
|---|---|
| Fórmula del teorema | `Combinatoria.*` calcula el total que muestra el contador. |
| Definición del conjunto | `Enumerador.reglas`, `puede_agregar` y `completa` deciden qué construcciones son válidas. |
| Clase de equivalencia | `Enumerador.canonica` ordena la lista si el orden no importa; `canonica_eilers` toma la menor de $p$ y $\rho(p)$. Dos construcciones con la misma forma canónica cuentan una vez. |
| Verificación | `Enumerador.enumerar_*` genera todas las configuraciones por fuerza bruta. `contar_dos_ladrillos_independiente` gira el modelo completo sin suponer el grupo $G$. |
| Preguntas | `Preguntas.generar` usa parámetros al azar; las opciones incorrectas son errores típicos ($P$ en vez de $C$, $k^n$ en vez de $k(k-1)^{n-1}$, olvidar dividir por la simetría, …). |

`tests/pruebas.gd` compara cada fórmula con la enumeración para muchos valores de los
parámetros (3487 comprobaciones), entre ellos los ladrillos $a \times b$ con
$1 \le a \le 4$ y $1 \le b \le 6$, las torres 2×4 de 2 y 3 niveles y los mosaicos $2\times2$.
