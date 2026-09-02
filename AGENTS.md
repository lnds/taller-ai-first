# AGENTS.md

Este archivo entrega guía a Claude Code (claude.ai/code) para trabajar con el código de este repositorio.

## Comandos

```sh
uv sync                                   # instalar dependencias (usa las versiones fijadas en .tool-versions)
uv run python -m carrito total --pedido 42        # correr el CLI
uv run python -m carrito total --pedido 42 --detalle
uv run python -m carrito total --pedido 42 --sin 2x1
uv run pytest                             # correr toda la suite
uv run pytest tests/test_descuentos.py -k nombre_del_test   # correr un solo test
uv sync --locked                          # falla si uv.lock quedó desfasado del pyproject.toml (lo usa el CI)
```

Los pedidos de ejemplo están hardcodeados en `datos/ejemplo.json` (pedidos 41-46, cada uno ejercitando una combinación distinta de promociones/cupones/región).

## Arquitectura

El cálculo del total de un pedido está deliberadamente partido en etapas, cada una en su propio módulo bajo `src/carrito/`, y `resumen.py` es el que las orquesta en orden:

1. **`precios.py`** — `subtotal()`: suma de `precio_linea()` (precio × cantidad) de cada línea.
2. **`descuentos.py`** — aplica primero las **promociones** (`PROMOCIONES`: `2x1`, `volumen`, `primera-compra`, calculadas sobre el subtotal y sumadas) y después los **cupones** del pedido, en un orden fijo: todos los cupones porcentuales antes que los de monto fijo (`total_con_descuentos()`). Este orden es una decisión de política comercial, no un detalle técnico: invertirlo cambia el total cuando el pedido trae más de un cupón (ver el test en `tests/test_descuentos.py`).
3. **`impuestos.py`** — `iva()`: 19% sobre el monto ya descontado.
4. **`envio.py`** — `costo_envio()`: por tramo de región (`TRAMOS`), gratis sobre los $50.000 o si el cliente es nuevo (`free_shipping_for_new_customer`).
5. **`dinero.py`** — aritmética compartida: todos los montos son pesos enteros (sin fracciones); `porcentaje()` redondea al peso más cercano vía `redondear()` (el medio peso redondea hacia arriba).

`resumen.py` combina estas etapas en un diccionario ordenado para presentación (Subtotal → Descuentos si hubo → IVA → Envío → Total). `cli.py` es el único consumidor de `resumen()`: parsea argumentos con `argparse` y formatea el resumen alineando columnas en texto plano.

`datos.py` carga y parsea `datos/ejemplo.json` a los dataclasses de `modelo.py` (`Producto`, `Linea`, `Cupon`, `Pedido`) — es la única fuente de datos, no hay base de datos ni API.

Promociones y cupones son mecanismos distintos: una **promoción** se activa por nombre en `pedido.promociones` y su lógica vive en `PROMOCIONES` (diccionario nombre → función) en `descuentos.py`; un **cupón** es un objeto (`Cupon`) con `tipo` (`"porcentaje"` o `"monto"`) y `valor`, y viene en `pedido.cupones`. Para agregar una promoción nueva, se registra una función en `PROMOCIONES` con la firma `(pedido, monto) -> int`.

## Convenciones

Nombres de funciones y variables en **inglés** de aquí en adelante (`volume_discount`, `free_shipping_for_new_customer`). El código existente mezcla inglés y español porque la base partió en español — no renombres lo ya existente solo por consistencia, pero todo código nuevo va en inglés. Docstrings, comentarios y mensajes de cara al usuario (CLI, README) se mantienen en español.

## Arbitraje documentación vs. código

Si detectas una contradicción entre lo que dice la documentación (README, AGENTS.md, docstrings) y lo que hace el código, prevalece la documentación como fuente de verdad — pero avisa explícitamente la discrepancia antes de actuar, no la resuelvas en silencio.
