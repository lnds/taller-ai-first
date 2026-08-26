"""Línea de comandos del carrito."""

import argparse

from carrito.datos import pedido
from carrito.descuentos import PROMOCIONES
from carrito.precios import precio_linea
from carrito.resumen import resumen


def main():
    parser = argparse.ArgumentParser(prog="carrito")
    parser.add_argument("comando", choices=["total"])
    parser.add_argument("--pedido", type=int, required=True)
    parser.add_argument("--sin", action="append", choices=sorted(PROMOCIONES), default=[])
    parser.add_argument("--detalle", action="store_true")
    args = parser.parse_args()

    elegido = pedido(args.pedido)
    elegido.promociones = [p for p in elegido.promociones if p not in args.sin]
    if args.detalle:
        ancho_nombre = max((len(linea.producto.nombre) for linea in elegido.lineas), default=0)
        ancho_cantidad = max((len(str(linea.cantidad)) for linea in elegido.lineas), default=0)
        ancho_precio = max((len(str(precio_linea(linea))) for linea in elegido.lineas), default=0)
        for linea in elegido.lineas:
            print(
                f"{linea.producto.nombre:<{ancho_nombre}} "
                f"x {linea.cantidad:>{ancho_cantidad}} "
                f"{precio_linea(linea):>{ancho_precio}}"
            )
        print("-")
    datos = resumen(elegido)
    ancho_etiqueta = max((len(etiqueta) for etiqueta in datos), default=0)
    ancho_monto = max((len(str(monto)) for monto in datos.values()), default=0)
    for etiqueta, monto in datos.items():
        print(f"{etiqueta:<{ancho_etiqueta}}  {monto:>{ancho_monto}}")


if __name__ == "__main__":
    main()
