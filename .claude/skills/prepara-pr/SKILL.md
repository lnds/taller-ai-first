---
name: prepara-pr
description: Ejecuta controles de calidad (ruff, bandit, pytest, Conventional Commits) sobre la rama actual y, si todos pasan y el agente revisor-pr aprueba el diff contra main, abre el pull request con gh. Usalo cuando te pida enviar un PR para revisión.
---

# prepara-pr

Prepara y abre el pull request de la rama actual, pero solo si pasa una serie de controles de calidad y una revisión de código.

## Pasos

1. **Verifica que estás en una rama distinta de `main`** y que hay commits en `main..HEAD`. Si no hay commits, informa al usuario y detente.

2. **Ejecuta los controles de calidad** corriendo el script `gates.sh` de esta carpeta de skill (ruta relativa a este archivo `SKILL.md`):

   ```
   bash .claude/skills/prepara-pr/gates.sh main
   ```

   Muestra la salida completa del script al usuario. El script imprime el resultado de cada uno de los cuatro controles (ruff, bandit, pytest, Conventional Commits) y termina con código de salida 1 si alguno falló.

   - Si el script termina con código distinto de 0, **detente**: informa al usuario cuáles controles fallaron (según la salida) y no continúes con la revisión ni con la apertura del PR.

3. **Si todos los controles pasan**, invoca al subagente `revisor-pr` (vía la herramienta Agent) para que revise el diff de la rama actual contra `main`. Pídele explícitamente que compare `main..HEAD` (todos los commits de la rama, no solo el último) y que entregue su veredicto final (`APROBADO` o `RECHAZADO`) según su formato de salida habitual.

4. **Interpreta el veredicto del revisor:**
   - Si el veredicto es `RECHAZADO`: **no abras el PR**. Muestra al usuario los problemas encontrados por el revisor y detente ahí.
   - Si el veredicto es `APROBADO`: continúa al siguiente paso.

5. **Abre el pull request** usando `gh`:

   - Determina la rama actual con `git branch --show-current`.
   - Empuja la rama al remoto si no está publicada o si tiene commits nuevos: `git push -u origin <rama-actual>` (confirma con el usuario antes de hacer push si aún no se ha subido nada, dado que es una acción visible para terceros).
   - Crea el PR con `gh pr create --base main --title "<título>" --body "<resumen>"`, generando el título y el resumen a partir de los commits de la rama (`git log main..HEAD`). No incluyas atribución a Claude en el título ni en el cuerpo del PR.
   - Reporta al usuario la URL del PR creado.

## Notas

- `gates.sh` acepta opcionalmente la rama base como primer argumento (por defecto `main`).
- Si `bandit` no está instalado localmente, el script intenta ejecutarlo vía `uvx bandit`.
- Nunca omitas los controles ni la revisión del subagente para "ahorrar tiempo": el propósito del skill es justamente bloquear la apertura del PR cuando algo no está en orden.
