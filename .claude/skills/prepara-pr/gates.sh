#!/usr/bin/env bash
# Controles de calidad previos a abrir un PR. Muestra la salida de cada
# control y termina con código 1 si alguno falla.
set -uo pipefail

BASE_BRANCH="${1:-main}"
FAIL=0

run_check() {
  local name="$1"
  shift
  echo "=================================================="
  echo "-> ${name}"
  echo "=================================================="
  "$@"
  local status=$?
  if [ "$status" -ne 0 ]; then
    echo "[FALLO] ${name} (código ${status})"
    FAIL=1
  else
    echo "[OK] ${name}"
  fi
  echo
}

# El proyecto usa uv (ver uv.lock) para pytest; ruff y bandit no son
# dependencias del proyecto, así que se ejecutan como herramientas
# efímeras con `uvx` cuando está disponible.
if command -v uv >/dev/null 2>&1; then
  RUN=(uv run)
else
  RUN=()
fi

if command -v uvx >/dev/null 2>&1; then
  RUFF_CMD=(uvx ruff)
  BANDIT_CMD=(uvx bandit)
else
  RUFF_CMD=(ruff)
  BANDIT_CMD=(bandit)
fi

# 1. ruff sobre src/ y tests/
run_check "ruff check" "${RUFF_CMD[@]}" check src/ tests/

# 2. bandit sobre src/, solo severidad media o alta
run_check "bandit (severidad media/alta)" "${BANDIT_CMD[@]}" -r src/ --severity-level medium

# 3. pytest
run_check "pytest" "${RUN[@]}" pytest

# 4. Conventional Commits en los commits de la rama contra la base
check_conventional_commits() {
  local pattern='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-zA-Z0-9_.-]+\))?!?: .+'
  local bad=0
  local hash subject line

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    hash="${line%% *}"
    subject="${line#* }"
    if [[ "$subject" =~ $pattern ]]; then
      echo "  [OK] ${hash} ${subject}"
    else
      echo "  [MAL] ${hash} ${subject} (no cumple Conventional Commits)"
      bad=1
    fi
  done < <(git log "${BASE_BRANCH}..HEAD" --format='%h %s')

  return $bad
}
run_check "Conventional Commits (${BASE_BRANCH}..HEAD)" check_conventional_commits

echo "=================================================="
if [ "$FAIL" -ne 0 ]; then
  echo "RESULTADO: uno o más controles fallaron."
  exit 1
fi

echo "RESULTADO: todos los controles pasaron."
exit 0
