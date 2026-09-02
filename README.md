# carrito

Cálculo del total de un pedido: precios, descuentos, impuesto y envío.

```sh
uv sync
uv run python -m carrito total --pedido 42
```

## Cómo se arma el total

1. **Subtotal** — la suma de las líneas.
2. **Descuentos** — primero los cupones porcentuales, después los vales de monto
   fijo. El orden importa cuando hay más de uno.
3. **IVA** — 19% sobre el monto ya descontado.
4. **Envío** — según la región, gratis sobre los $50.000.
