"""Orden de aplicación de los descuentos.

El README y el docstring de `carrito.descuentos` fijan la política: primero los
cupones porcentuales y, sobre el monto que queda, los vales de monto fijo.
"""

from carrito.descuentos import total_con_descuentos
from carrito.modelo import Cupon, Linea, Pedido, Producto


def test_el_cupon_porcentual_se_aplica_antes_del_vale_de_monto_fijo():
    # Subtotal redondo para que el orden se note en el resultado.
    producto = Producto(sku="ABC-1", nombre="Producto de prueba", precio=10_000)
    pedido = Pedido(
        numero=1,
        lineas=[Linea(producto=producto, cantidad=1)],
        cupones=[
            Cupon(codigo="PCT10", tipo="porcentaje", valor=10),
            Cupon(codigo="VALE2000", tipo="monto", valor=2_000),
        ],
    )

    # Política documentada: 10.000 - 10% = 9.000, y luego 9.000 - 2.000 = 7.000.
    # (Con el orden inverso daría 7.200, que es lo que distingue un caso del otro.)
    assert total_con_descuentos(pedido) == 7_000
