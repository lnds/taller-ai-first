from carrito.descuentos import total_con_descuentos
from carrito.modelo import Cupon, Linea, Pedido, Producto


def test_cupon_porcentaje_se_aplica_antes_que_el_de_monto_fijo():
    """El README documenta el orden: primero porcentaje, después monto fijo."""
    producto = Producto(sku="LANA-03", nombre="Chal de lana", precio=36900)
    pedido = Pedido(
        numero=45,
        lineas=[Linea(producto, 2)],
        cupones=[
            Cupon(codigo="OTONO10", tipo="porcentaje", valor=10),
            Cupon(codigo="VALE5000", tipo="monto", valor=5000),
        ],
    )

    # Subtotal 73800 -> -10% = 66420 -> -5000 = 61420.
    # Si el monto fijo se aplicara primero el resultado sería 61920.
    assert total_con_descuentos(pedido) == 61420
