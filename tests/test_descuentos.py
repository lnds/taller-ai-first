"""Orden de aplicación de los descuentos del pedido."""

from carrito.descuentos import total_con_descuentos
from carrito.modelo import Cupon, Linea, Pedido, Producto


def test_cupon_porcentual_se_aplica_antes_que_el_vale_de_monto_fijo():
    """El porcentaje corre sobre el subtotal; el vale, sobre lo que queda.

    Subtotal 10.000 → 10% deja 9.000 → el vale de 2.000 deja 7.000.
    Con el orden invertido el total sería 7.200, así que el resultado
    distingue una política de la otra.
    """
    pedido = Pedido(
        numero=1,
        lineas=[Linea(producto=Producto(sku="A-1", nombre="Ancla", precio=10_000), cantidad=1)],
        cupones=[
            Cupon(codigo="PCT10", tipo="porcentaje", valor=10),
            Cupon(codigo="VALE2000", tipo="monto", valor=2_000),
        ],
    )

    assert total_con_descuentos(pedido) == 7_000
