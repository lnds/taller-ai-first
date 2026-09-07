"""Steps de pytest-bdd para tests/features/envio.feature.

Traduce, sin tocar carrito/, las decisiones de negocio de la regla de envío
gratis a ejercicios sobre el pipeline real (precios -> descuentos -> IVA ->
envío). Donde la implementación actual difiere de esas decisiones, el test
debe fallar: eso es lo que documenta el desacuerdo.
"""

import re

import pytest
from pytest_bdd import given, parsers, scenarios, then

from carrito import descuentos, impuestos, precios
from carrito.modelo import Cupon, Linea, Pedido, Producto
from carrito.resumen import resumen

scenarios("features/envio.feature")


def _a_entero(monto: str) -> int:
    """Convierte "50.000" o "$50.000" a 50000."""
    return int(monto.replace("$", "").replace(".", ""))


def _envio_esperado(texto: str) -> int:
    """Convierte "gratis" o "$3.990 (pagado)" al monto de envío esperado."""
    if "gratis" in texto.lower():
        return 0
    coincidencia = re.search(r"\$[\d.]+", texto)
    assert coincidencia is not None, f"no encontré un monto en {texto!r}"
    return _a_entero(coincidencia.group())


@pytest.fixture
def pedido() -> Pedido:
    return Pedido(numero=1)


@given(
    parsers.parse(
        'que el carrito tiene un producto "{nombre}" a ${precio} con cantidad {cantidad:d}'
    )
)
def agregar_producto(pedido: Pedido, nombre: str, precio: str, cantidad: int) -> None:
    producto = Producto(sku=nombre, nombre=nombre, precio=_a_entero(precio))
    pedido.lineas.append(Linea(producto=producto, cantidad=cantidad))


@given("el pedido no tiene cupones ni promociones")
def sin_cupones_ni_promociones(pedido: Pedido) -> None:
    assert pedido.cupones == []
    assert pedido.promociones == []


@given(parsers.parse("el pedido tiene un cupón porcentual de {valor:d}%"))
def agregar_cupon_porcentual(pedido: Pedido, valor: int) -> None:
    pedido.cupones.append(Cupon(codigo="CUPON", tipo="porcentaje", valor=valor))


@given(parsers.parse('el pedido tiene la promoción "{nombre}"'))
def agregar_promocion(pedido: Pedido, nombre: str) -> None:
    pedido.promociones.append(nombre)


@given("el cliente no es nuevo")
def cliente_no_nuevo(pedido: Pedido) -> None:
    pedido.cliente_nuevo = False


@given("el cliente es nuevo")
def cliente_nuevo(pedido: Pedido) -> None:
    pedido.cliente_nuevo = True


@given(parsers.parse('la región de despacho es "{region}"'))
def fijar_region(pedido: Pedido, region: str) -> None:
    pedido.region = region


@then(parsers.parse("el subtotal es {monto}"))
def verificar_subtotal(pedido: Pedido, monto: str) -> None:
    assert precios.subtotal(pedido) == _a_entero(monto)


@then(parsers.parse("el IVA sobre el subtotal es {monto}"))
def verificar_iva(pedido: Pedido, monto: str) -> None:
    assert impuestos.iva(precios.subtotal(pedido)) == _a_entero(monto)


@then(parsers.parse("el monto bruto con IVA es {monto}"))
def verificar_monto_bruto_con_iva(pedido: Pedido, monto: str) -> None:
    subtotal = precios.subtotal(pedido)
    assert subtotal + impuestos.iva(subtotal) == _a_entero(monto)


@then(parsers.parse("el monto luego de aplicar el cupón es {monto}"))
def verificar_monto_post_cupon(pedido: Pedido, monto: str) -> None:
    assert descuentos.total_con_descuentos(pedido) == _a_entero(monto)


@then(parsers.parse("el monto luego de aplicar la promoción es {monto}"))
def verificar_monto_post_promocion(pedido: Pedido, monto: str) -> None:
    assert descuentos.total_con_descuentos(pedido) == _a_entero(monto)


@then(parsers.parse("el envío es {envio}"))
def verificar_envio(pedido: Pedido, envio: str) -> None:
    assert resumen(pedido)["Envío"] == _envio_esperado(envio)
