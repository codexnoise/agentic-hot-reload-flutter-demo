#!/usr/bin/env bash
#
# Restaura el estado con el RenderFlex overflow para volver a grabar la demo.
# Requiere el tag `demo-bug`, que apunta al commit con lib/ en estado roto.

set -euo pipefail

cd "$(dirname "$0")/.."

if ! git rev-parse --verify --quiet refs/tags/demo-bug >/dev/null; then
  echo "Error: no existe el tag 'demo-bug'." >&2
  echo "Creálo sobre el commit con el bug: git tag demo-bug <sha>" >&2
  exit 1
fi

git checkout demo-bug -- lib/

echo "Bug restaurado desde el tag 'demo-bug'."
echo "Hacé hot restart (R) en la sesión de 'fvm flutter run' para volver al estado inicial limpio."
