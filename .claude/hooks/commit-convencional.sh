#!/usr/bin/env bash
# Hook PreToolUse (matcher: Bash) que bloquea `git commit` cuyo mensaje
# no siga Conventional Commits (https://www.conventionalcommits.org/).
#
# Recibe en stdin el payload JSON del hook con {tool_name, tool_input, ...}.
# Sale con código 2 y un mensaje en stderr para bloquear la ejecución;
# sale con código 0 para permitirla.

set -euo pipefail

TIPOS='feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'
REGEX_CONVENCIONAL="^(${TIPOS})(\([a-zA-Z0-9_./-]+\))?!?: .+"

payload="$(cat)"

tool_name="$(jq -r '.tool_name // empty' <<<"$payload")"
if [[ "$tool_name" != "Bash" ]]; then
  exit 0
fi

command="$(jq -r '.tool_input.command // empty' <<<"$payload")"
if [[ -z "$command" ]]; then
  exit 0
fi

# Solo nos interesan invocaciones de `git commit`.
if ! grep -qE '(^|[;&|]|\s)git\s+commit(\s|$)' <<<"$command"; then
  exit 0
fi

# Si es --amend sin -m/-F/--message, git reutiliza el mensaje anterior:
# no hay mensaje nuevo que validar aquí.
if grep -qE '(^|\s)(--amend)(\s|$)' <<<"$command" \
  && ! grep -qE '(^|\s)(-m|--message|-F|--file)(\s|=)' <<<"$command"; then
  exit 0
fi

# Extraer el mensaje del commit desde -m "..." o --message="...".
# Solo se toma el primer -m (la línea de asunto), que es la que
# Conventional Commits exige que tenga el formato tipo(scope): descripción.
mensaje="$(python3 - "$command" <<'PYEOF'
import re
import shlex
import sys

cmd = sys.argv[1]
try:
    tokens = shlex.split(cmd)
except ValueError:
    print("")
    sys.exit(0)

mensaje = None
i = 0
while i < len(tokens):
    tok = tokens[i]
    if tok in ("-m", "--message"):
        if i + 1 < len(tokens):
            mensaje = tokens[i + 1]
        break
    if tok.startswith("--message="):
        mensaje = tok.split("=", 1)[1]
        break
    i += 1

print(mensaje if mensaje is not None else "")
PYEOF
)"

if [[ -z "$mensaje" ]]; then
  # No se pudo extraer un mensaje inline (por ejemplo -F archivo o commit
  # interactivo). No bloqueamos porque no hay nada verificable aquí.
  exit 0
fi

primera_linea="$(head -n1 <<<"$mensaje")"

if [[ ! "$primera_linea" =~ $REGEX_CONVENCIONAL ]]; then
  cat >&2 <<EOF
Commit rechazado: el mensaje no sigue Conventional Commits.

Mensaje recibido:
  "$primera_linea"

Formato esperado:
  <tipo>(<scope opcional>)<! opcional>: <descripción>

Tipos válidos: ${TIPOS//|/, }

Ejemplos válidos:
  feat: agregar validación de RUT
  fix(auth): corregir expiración de token
  refactor!: renombrar módulo de pagos
EOF
  exit 2
fi

exit 0
