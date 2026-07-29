# Agentic Hot Reload — Demo (Flutter 3.44)

Demo grabable del **loop cerrado del Dart & Flutter MCP server**: un agente de IA
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

Flujo de conexión:

```
fvm flutter run ──levanta──> app + DTD (procesos locales)
                                        │
                       dart mcp-server ─┘  (descubre el DTD automáticamente)
                                │
                          Claude Code ──stdio──┘  (invoca las herramientas MCP)
```

### Configuración en este repo

El server ya está registrado en [`.mcp.json`](.mcp.json) a nivel proyecto
(compartido con el equipo). Apunta al `dart` de **FVM** vía el wrapper, así usa
siempre el SDK correcto sin rutas absolutas:

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

Si necesitás registrarlo desde cero en otra máquina:

```bash
claude mcp add dart --scope project -- fvm dart mcp-server
```

### Aprobar y verificar

Como es un `.mcp.json` de proyecto, Claude Code pide **aprobarlo explícitamente**
la primera vez (medida de seguridad):

1. Reiniciá la sesión de Claude Code (`claude`) desde la raíz del proyecto.
2. Aceptá el prompt de confianza del server `dart`.
3. Confirmá con `/mcp` (debe listar `dart` conectado) o:

   ```bash
   claude mcp list        # dart debe aparecer conectado
   ```

Prueba de fuego del auto-discovery — con la app corriendo, pedile al agente:

```
Lista las apps Dart corriendo en este workspace.
```

Si responde con tu app → el descubrimiento automático del DTD funciona. Si te
pide una URI del DTD a mano → estás en un SDK anterior a 3.44/3.12 (revisá que
Claude Code use el `dart` de FVM y no el global).

---

## Ejecutar la demo

1. **Lanzá la app** (dejá esta terminal abierta toda la demo — mantiene vivos el
   proceso y el DTD):

   ```bash
   fvm flutter run
   ```

   Elegí el simulador de iPhone. La pantalla muestra el `RenderFlex overflow`.

2. **Poné el contador en un valor visible** (ej. 7) antes de lanzar el prompt.
   Sirve para demostrar que el hot reload **preserva el estado**.

3. **Escribile al agente** (sin mencionar el archivo ni la solución):

   ```
   La app corriendo tiene un RenderFlex overflow en el dashboard.
   Conéctate a ella, identifica qué widget lo causa, aplica el fix
   y haz hot reload.
   ```

4. El agente cierra el loop: descubre la app → lee los errores de runtime →
   inspecciona el árbol de widgets → edita el código → hace hot reload →
   **vuelve a verificar** que ya no hay overflow. El contador sigue intacto.

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

El server `dart` expone, entre otras: `list_running_apps`, `get_runtime_errors`,
`widget_inspector`, `hot_reload`, `hot_restart`, `get_active_location`,
`launch_app`, `analyze_files`. Son las que el agente encadena para cerrar el loop.

## Problemas conocidos

- **El agente pide la URI del DTD** → Claude Code está usando un SDK < 3.44/3.12.
  Verificá que el MCP corra con `fvm dart`, no el `dart` global.
- **El hot reload no refleja cambios** → la terminal de `fvm flutter run` murió, o
  el cambio es fuera de la capa Dart (necesita hot restart `R`).
- **El overflow no aparece** → el viewport del simulador es más ancho de lo
  esperado; sumá una `MetricCard` o subí el ancho fijo (ver `claude/SPEC.md` §5.3).
