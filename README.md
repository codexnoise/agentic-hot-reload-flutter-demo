# Agentic Hot Reload — Demo (Flutter 3.44)

Demo del **loop cerrado del Dart & Flutter MCP server**: un agente de IA
descubre la app Flutter corriendo, lee sus errores de runtime, inspecciona el
árbol de widgets, aplica un fix y dispara el **hot reload** — todo sin que el
desarrollador toque la terminal.

El escenario canónico es una pantalla de dashboard con un **`RenderFlex
overflow`** (las rayas amarillas y negras). El desarrollador escribe un prompt en
lenguaje natural y el agente diagnostica y resuelve el bug solo.

> Especificación completa de la demo en [`claude/SPEC.md`](claude/SPEC.md).

---

## Requisitos

| Requisito | Versión | Cómo verificar |
|---|---|---|
| Flutter | **3.44.1** (vía FVM) | `fvm flutter --version` |
| Dart | **3.12.1** (incluido) | — |
| Simulador iOS | iPhone 15/16/17, iOS 17+ | `xcrun simctl list devices` |
| Xcode | instalado y licenciado | `fvm flutter doctor` |
| Agente MCP | Claude Code (o Cursor / Gemini CLI) | — |

> **Importante — este repo usa [FVM](https://fvm.app/).** El Flutter pineado en
> [`.fvmrc`](.fvmrc) es **3.44.1**, que es el que cumple el requisito de la demo
> (el auto-discovery del DTD es la novedad de Flutter 3.44 / Dart 3.12). El
> `flutter` global de la máquina puede ser otra versión, así que **usá siempre
> `fvm flutter …` / `fvm dart …`**, nunca los binarios globales.

Instalación de FVM (una sola vez):

```bash
brew install fvm      # o: dart pub global activate fvm
fvm install           # instala el SDK del .fvmrc si falta
```

---

## Estructura del proyecto

```
agentic-hot-reload-flutter-demo/
├── lib/
│   ├── main.dart                 # entrypoint, MaterialApp
│   ├── screens/
│   │   └── dashboard_screen.dart # la pantalla con el bug (stateful)
│   ├── widgets/
│   │   ├── metric_card.dart      # tarjeta de ancho fijo (causa el overflow)
│   │   └── counter_panel.dart    # panel con estado (prueba el state preservation)
│   └── data/
│       └── demo_metrics.dart     # datos estáticos de las tarjetas
├── scripts/
│   └── reset_bug.sh              # restaura el bug para regrabar
├── .mcp.json                     # config del Dart & Flutter MCP server
├── .fvmrc                        # pin de Flutter (3.44.1)
├── claude/SPEC.md                # especificación completa de la demo
└── README.md
```

> El estado versionado de `lib/` es el **estado con el bug**: cuatro
> `MetricCard` de 180pt dentro de un `Row` sin `Expanded`. El tag `demo-bug`
> apunta a ese estado y es lo que restaura `scripts/reset_bug.sh`.

---

## Cómo funciona el agentic hot reload

### Los tres actores

```
                         ┌───────────────────────────────┐
                         │        SIMULADOR iOS          │
                         │   App Flutter + Dart VM       │
                         │   (el estado vive acá)        │
                         └───────────────▲───────────────┘
                                         │ ⑤ parche compilado
                                         │    (el estado sobrevive)
┌─────────────┐  ④ relee   ┌─────────────┴────────────────┐
│  lib/*.dart │◄───────────│  TERMINAL:  fvm flutter run  │
│  (en disco) │            │  flutter_tools = compilador  │
└──────▲──────┘            │  + DTD  ws://127.0.0.1:xxxxx │
       │                   └─────────────▲────────────────┘
       │ ② Edit                          │  DTD (WebSocket local)
       │    escribe el fix               │  ① get_runtime_errors
       │                                 │  ③ hot_reload
┌──────┴─────────────────────────────────┴────────────────┐
│                      CLAUDE CODE                         │
│    dart mcp-server  ·  stdio  ·  local  ·  sin API keys  │
└──────────────────────────────────────────────────────────┘
```

### El loop, paso a paso

| # | Quién | Qué pasa |
|---|---|---|
| 0 | Vos | `fvm flutter run` levanta la app, el DTD y el compilador. Esa terminal queda viva toda la demo |
| ① | Claude | `dtd` descubre la app y se conecta; `get_runtime_errors` devuelve el `RenderFlex overflow` **con archivo y línea** |
| ② | Claude | `widget_inspector` confirma el culpable en el árbol vivo; `Edit` escribe el fix en `lib/` **en disco** |
| ③ | Claude | `hot_reload` por DTD — una orden, sin compilar nada él mismo |
| ④ | Terminal | `flutter_tools` **relee `lib/` del disco** y compila solo el diff |
| ⑤ | Simulador | El parche entra en la Dart VM. El widget se reconstruye, **el estado no se pierde** |
| ✓ | Claude | `get_runtime_errors` otra vez: la lista vuelve vacía. El agente verifica su propio fix |

### Las tres cosas que hacen que esto funcione

**El DTD hace de puente.** Es un proceso que `flutter run` levanta al lado de la
app y publica un WebSocket local. Por ahí salen los errores de runtime, el árbol
de widgets y la orden de recargar. Sin él, el agente solo podría hacer análisis
estático y adivinar.

**El descubrimiento es automático.** Es la novedad de Flutter 3.44 / Dart 3.12:
`listDtdUris` escanea las instancias del DTD vivas en la máquina. En SDKs
anteriores había que copiar la URI a mano.

**El compilador vive en tu terminal, no en el agente.** `hot_reload` por DTD no
compila nada: le delega al proceso de `flutter run`, que es quien tiene el
compilador incremental. Por eso el agente edita el **archivo en disco** — es de
ahí de donde `flutter_tools` relee. Y por eso **si cerrás esa terminal, el hot
reload por MCP muere con ella**.

### Por qué no vas a ver nada en la terminal

`flutter_tools` acepta órdenes por **dos canales en paralelo**: el teclado
(`r`, `R`, `q`) y el DTD. Cuando el reload entra por DTD, **tu terminal no
imprime nada** — ni un `Reloaded 1 of 512 libraries`. El cambio aparece en el
simulador de golpe, sin rastro en la consola.

Consecuencia para grabar: la única evidencia visual de que hubo un agente está
en el panel de Claude Code. **La grabación tiene que ser split-screen** —
simulador + Claude Code — o el video parece un corte de edición.

### Hot reload vs hot restart

El contador de la pantalla existe para esto:

| | Estado (`_count`) | Cómo se dispara |
|---|---|---|
| **Hot reload** | **se preserva** — si estaba en 27, sigue en 27 | tecla `r` · `hot_reload` por MCP |
| **Hot restart** | se pierde — vuelve a 0 | tecla `R` · `hot_restart` por MCP |

Poné el contador en un valor visible antes de la toma. Si después del fix sigue
ahí, la prueba en cámara es inapelable: fue reload, no un relanzamiento.

---

## Conexión MCP (Dart & Flutter MCP server)

### Qué es cada pieza

- **DTD (Dart Tooling Daemon):** proceso puente entre la app corriendo y las
  herramientas externas. Expone el árbol de widgets, los errores de runtime y la
  capacidad de hot reload.
- **Dart & Flutter MCP server:** traduce las capacidades del DTD a herramientas
  MCP que un agente de IA puede invocar. **Viene con el SDK de Dart** — no se
  instala por separado y **no requiere credenciales ni API keys**: es un proceso
  local que se comunica por stdio.
- **El agente (Claude Code):** consume esas herramientas.

### Paso 0 — verificar que el SDK trae el server

El `mcp-server` es un subcomando del SDK de Dart. Si el comando responde con la
ayuda en vez de "Could not find a command named", está:

```bash
fvm dart mcp-server --help
fvm dart --version        # tiene que ser 3.12.1+
```

> Si usás el `dart` global en vez del de FVM y ese SDK es < 3.12, el server
> arranca igual pero **sin auto-discovery**, y el agente te va a pedir la URI del
> DTD a mano. Esa es la causa nº1 de que la demo no salga.

### Paso 1 — registrar el server

En este repo **ya está hecho**: [`.mcp.json`](.mcp.json) lo registra a nivel
proyecto, así que se versiona y le funciona a todo el equipo. Apunta al `dart` de
FVM vía el wrapper, sin rutas absolutas:

```json
{
  "mcpServers": {
    "dart": {
      "type": "stdio",
      "command": "fvm",
      "args": ["dart", "mcp-server"]
    }
  }
}
```

Desde cero en otra máquina, elegí el alcance según lo que quieras:

```bash
# project → escribe .mcp.json, se versiona y lo comparte el equipo (lo de este repo)
claude mcp add dart --scope project -- fvm dart mcp-server

# user → disponible en todos tus proyectos, solo para vos
claude mcp add dart --scope user -- dart mcp-server
```

`type: "stdio"` significa que Claude Code **lanza el proceso él mismo** y le
habla por entrada/salida estándar. No hay puertos, ni tokens, ni nada que exponer
a la red.

### Paso 2 — aprobar el server

Un `.mcp.json` de proyecto es código ejecutable que viene con el repo, así que
Claude Code **exige aprobarlo a mano** la primera vez:

1. Abrí Claude Code (`claude`) **desde la raíz del proyecto**.
2. Aceptá el prompt de confianza del server `dart`.
3. Si te lo salteaste sin querer, `/mcp` te deja habilitarlo después.

La aprobación queda guardada en `.claude/settings.local.json` (ignorado por git,
es tuyo):

```json
{
  "enableAllProjectMcpServers": true,
  "enabledMcpjsonServers": ["dart"]
}
```

### Paso 3 — verificar que el server está conectado

```bash
claude mcp list        # 'dart' tiene que aparecer conectado
```

O dentro de la sesión, `/mcp`. Si aparece **failed**, corré `fvm dart mcp-server`
a mano en una terminal: el error de arranque se ve ahí y casi siempre es que
`fvm` no está en el `PATH` que hereda Claude Code.

### Paso 4 — verificar el auto-discovery (con la app corriendo)

Esto es lo único que prueba de verdad que el loop está cerrado. Con
`fvm flutter run` vivo, pedile al agente:

```
Lista las apps Dart corriendo en este workspace.
```

| Respuesta | Qué significa |
|---|---|
| Te devuelve tu app y una URI `ws://127.0.0.1:…` | ✅ auto-discovery OK, podés grabar |
| Te pide la URI del DTD a mano | SDK < 3.44/3.12 — revisá que el MCP use el `dart` de FVM |
| "no hay apps corriendo" | la terminal de `flutter run` se murió, o Claude Code se abrió desde otro directorio |

> La primera llamada del agente suele ser `dtd` con `connect` antes de poder leer
> nada; que aparezcan esas dos tool calls es normal, no es un error de setup.

### Paso 5 — pre-aprobar permisos antes de grabar

Cada herramienta MCP nueva dispara un prompt de permiso. En medio de una toma eso
es un frenazo. Las del loop ya están pre-aprobadas en
`.claude/settings.local.json`:

```json
"mcp__dart__dtd", "mcp__dart__get_runtime_errors",
"mcp__dart__widget_inspector", "mcp__dart__analyze_files",
"mcp__dart__hot_reload", "mcp__dart__hot_restart"
```

Falta **`Edit`**, que no está pre-aprobado a propósito. Antes de grabar, activá
el modo accept-edits con `shift+tab` para que el agente escriba el fix sin
frenarse.

---

## Ejecutar la demo

1. **Lanzá la app** (dejá esta terminal abierta toda la demo — mantiene vivos el
   proceso y el DTD):

   ```bash
   fvm flutter run
   ```

   Elegí el simulador de iPhone. La pantalla muestra el `RenderFlex overflow`.

2. **Preparate para grabar:** simulador y Claude Code lado a lado en pantalla
   (ver [por qué](#por-qué-no-vas-a-ver-nada-en-la-terminal)), y `shift+tab` en
   Claude Code para el modo accept-edits.

3. **Poné el contador en un valor visible** (ej. 7) antes de lanzar el prompt.
   Sirve para demostrar que el hot reload **preserva el estado**.

4. **Escribile al agente** (sin mencionar el archivo ni la solución):

   ```
   La app corriendo tiene un RenderFlex overflow en el dashboard.
   Conéctate a ella, identifica qué widget lo causa, aplica el fix
   y haz hot reload.
   ```

5. El agente cierra el loop: descubre la app → lee los errores de runtime →
   inspecciona el árbol de widgets → edita el código → hace hot reload →
   **vuelve a verificar** que ya no hay overflow. El contador sigue intacto.

### Variante: varios cambios en un solo reload

Más vistoso para el video, porque obliga al agente a razonar sobre archivos que
el prompt nunca nombra:

```
La app corriendo tiene un RenderFlex overflow en el dashboard.
Conéctate a ella, identifica qué widget lo causa y arréglalo.
Además cambia el fondo a un tema oscuro y agrega un label
'test agentic hot reload' debajo de las cards. Aplica todo
con hot reload.
```

El tema oscuro es la parte interesante: `metric_card.dart` y `counter_panel.dart`
tienen `Colors.black54` hardcodeado, que en fondo oscuro queda ilegible. El
agente tiene que darse cuenta solo. Se resuelve en **un único hot reload** que
toca cuatro archivos, con el contador intacto.

> Contrapartida: es menos determinista que el prompt simple. Si estás con poco
> margen de tomas, andá con el de arriba.

---

## Regrabar (reset del bug)

```bash
./scripts/reset_bug.sh
```

Restaura el estado con el bug desde el tag `demo-bug`. Después, en la terminal de
`fvm flutter run` presioná `R` (hot restart) para volver al estado inicial limpio,
contador incluido.

---

## Herramientas MCP relevantes

Las que el agente encadena para cerrar el loop — **verificadas funcionando en
este setup**:

| Herramienta | Para qué |
|---|---|
| `dtd` | `listDtdUris` descubre las apps corriendo; `connect` engancha el agente al DTD |
| `get_runtime_errors` | lee el `RenderFlex overflow` con archivo y línea |
| `widget_inspector` | inspecciona el árbol de widgets de la app viva |
| `hot_reload` | aplica el cambio preservando el estado |
| `hot_restart` | reinicia la app desde cero (resetea el contador) |
| `analyze_files` | análisis estático, para confirmar que el fix compila |

El catálogo completo de features del server sale de:

```bash
fvm dart mcp-server --help      # ver la lista de --enable / --disable
```

**Ojo: no todo lo que aparece ahí queda registrado como herramienta invocable.**
En este setup, las de ciclo de vida (`launch_app`, `list_running_apps`,
`stop_app`, `get_app_logs`) y `get_active_location` **no se expusieron** al
agente. No importa para la demo: acá la app la lanzás vos a mano y el
descubrimiento lo resuelve `dtd`.

> **`flutter_driver_command` sí está registrado, pero no funciona acá.** Requiere
> `enableFlutterDriverExtension()` en el entrypoint; sin eso devuelve *"The
> flutter driver extension is not enabled"*. O sea que el agente **no** puede
> tocar la pantalla ni sacar screenshots — y no hace falta: la demo se graba
> manualmente y las capturas las hace quien graba.

---

## Problemas conocidos

- **El agente pide la URI del DTD** → Claude Code está usando un SDK < 3.44/3.12.
  Verificá que el MCP corra con `fvm dart`, no el `dart` global.
- **La terminal no imprime nada cuando el agente recarga** → es lo esperado, no
  un fallo. El reload entra por DTD, no por teclado
  ([por qué](#por-qué-no-vas-a-ver-nada-en-la-terminal)). No uses la consola para
  saber si el reload ocurrió: mirá el simulador.
- **El overflow no se ve en la consola de `flutter run`** → tampoco es señal de
  que el bug no esté. El error queda registrado en el canal DTD igual; confirmalo
  con `get_runtime_errors`.
- **El hot reload no refleja cambios** → la terminal de `fvm flutter run` murió, o
  el cambio es fuera de la capa Dart (necesita hot restart `R`).
- **El overflow no aparece** → el viewport del simulador es más ancho de lo
  esperado; sumá una `MetricCard` o subí el ancho fijo (ver `claude/SPEC.md` §5.3).
- **El agente arregla el archivo equivocado** → señal de que hizo análisis
  estático en vez de leer el DTD. Revisá la conexión MCP y repetí la toma.
