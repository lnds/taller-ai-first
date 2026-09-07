"""Costo de envío según la región de destino.

Sobre cierto monto el envío no se cobra. El umbral se compara contra el
subtotal del pedido con IVA incluido, antes de aplicar cupones o
promociones.
"""

TRAMOS = {
    "metropolitana": 3990,
    "regiones": 5990,
    "extremo": 12990,
}

UMBRAL_ENVIO_GRATIS = 50000


def free_shipping_for_new_customer(order) -> bool:
    """Los clientes nuevos no pagan envío en su primera compra."""
    return order.cliente_nuevo


def costo_envio(pedido, monto_bruto_con_iva: int) -> int:
    if free_shipping_for_new_customer(pedido):
        return 0
    if monto_bruto_con_iva >= UMBRAL_ENVIO_GRATIS:
        return 0
    return TRAMOS.get(pedido.region, TRAMOS["regiones"])
