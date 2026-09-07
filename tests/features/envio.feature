# language: es
# Regla de envío gratis
#
# Decisiones de negocio para esta regla:
#   1. El umbral de $50.000 se evalúa ANTES de aplicar cualquier descuento
#      (cupón o promoción), es decir, sobre el monto bruto del pedido.
#   2. El IVA (19%) SÍ cuenta para el umbral: se compara el monto bruto
#      con IVA incluido, no el neto.
#   3. Las promociones descuentan igual que los cupones: ninguna de las
#      dos afecta el umbral, porque este se evalúa antes de aplicar
#      cualquiera de ellas.
#   4. El umbral es inclusivo: con exactamente $50.000 (bruto, con IVA)
#      el envío es gratis.
#   5. Un cliente nuevo tiene envío gratis en su primera compra,
#      independiente del monto del pedido.

Característica: Envío gratis según el monto del pedido

  Esquema del escenario: El umbral se evalúa sobre el monto bruto con IVA, sin descuentos
    Dado que el carrito tiene un producto "Notebook básico" a $<precio> con cantidad 1
    Y el pedido no tiene cupones ni promociones
    Y el cliente no es nuevo
    Y la región de despacho es "metropolitana"
    Entonces el subtotal es $<subtotal>
    Y el IVA sobre el subtotal es $<iva>
    Y el monto bruto con IVA es $<monto_bruto_con_iva>
    Y el envío es <envio>

    Ejemplos:
      | precio | subtotal | iva   | monto_bruto_con_iva | envio           |
      | 30000  | 30.000   | 5.700 | 35.700               | $3.990 (pagado) |
      | 42016  | 42.016   | 7.983 | 49.999               | $3.990 (pagado) |
      | 42017  | 42.017   | 7.983 | 50.000               | gratis          |
      | 42018  | 42.018   | 7.983 | 50.001               | gratis          |

  # Nota sobre los cálculos del esquema anterior:
  #   - Con cantidad 1, el subtotal es igual al precio del producto.
  #   - IVA = redondear(subtotal × 19%). Ej.: 42.016 × 0,19 = 7.983,04 → $7.983.
  #   - Monto bruto con IVA = subtotal + IVA. Ej.: 42.017 + 7.983 = $50.000.
  #   - $3.990 es el tramo de envío para la región "metropolitana".

  Escenario: Un cupón porcentual no afecta el umbral, porque este ya se evaluó sobre el bruto
    Dado que el carrito tiene un producto "Silla ergonómica" a $60.000 con cantidad 1
    Y el pedido tiene un cupón porcentual de 50%
    Y el cliente no es nuevo
    Y la región de despacho es "metropolitana"
    Entonces el subtotal es $60.000
    Y el IVA sobre el subtotal es $11.400
    Y el monto bruto con IVA es $71.400
    # $71.400 ya supera el umbral de $50.000: el envío queda gratis en este punto,
    # antes de que el cupón se aplique.
    Y el monto luego de aplicar el cupón es $30.000
    # $60.000 - (50% de $60.000) = $60.000 - $30.000 = $30.000
    # Ese monto post-cupón queda muy por debajo de $50.000, pero no importa:
    # el umbral no se vuelve a evaluar sobre él.
    Y el envío es gratis

  Escenario: Una promoción no afecta el umbral, porque este ya se evaluó sobre el bruto
    Dado que el carrito tiene un producto "Teclado mecánico" a $21.000 con cantidad 4
    Y el pedido tiene la promoción "2x1"
    Y el cliente no es nuevo
    Y la región de despacho es "metropolitana"
    Entonces el subtotal es $84.000
    # 4 unidades a $21.000 = $84.000
    Y el IVA sobre el subtotal es $15.960
    # $84.000 × 19% = $15.960 exacto
    Y el monto bruto con IVA es $99.960
    # $99.960 ya supera el umbral de $50.000: el envío queda gratis en este punto,
    # antes de que la promoción se aplique.
    Y el monto luego de aplicar la promoción es $42.000
    # 2x1 sobre 4 unidades: 2 pares, 1 unidad gratis por par → 2 unidades gratis
    # $84.000 - (2 × $21.000) = $84.000 - $42.000 = $42.000
    # Ese monto post-promoción queda muy por debajo de $50.000, pero no importa:
    # el umbral no se vuelve a evaluar sobre él.
    Y el envío es gratis

  Escenario: Un cliente nuevo tiene envío gratis sin importar el monto ni el umbral
    Dado que el carrito tiene un producto "Cargador USB-C" a $10.000 con cantidad 1
    Y el pedido no tiene cupones ni promociones
    Y el cliente es nuevo
    Y la región de despacho es "extremo"
    Entonces el subtotal es $10.000
    Y el IVA sobre el subtotal es $1.900
    Y el monto bruto con IVA es $11.900
    # $11.900 está muy por debajo del umbral de $50.000, y la región "extremo"
    # tiene el tramo de envío más caro. Aun así, el envío es gratis porque
    # el cliente es nuevo: esta regla no depende del umbral.
    Y el envío es gratis
