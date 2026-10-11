#!/usr/bin/env python3
"""Sirve la versión web del juego (build/web) para probarla.

    python3 servir.py            ->  http://localhost:8000   (sólo esta computadora)
    python3 servir.py --https    ->  https://<tu IP>:8443    (celular u otra PC de la red)

Godot sólo arranca en un «contexto seguro». http://localhost lo es, pero
http://<IP> y http://0.0.0.0 no, y ahí el juego muestra el error
«Secure Context - Check web server configuration (use HTTPS)».
Para entrar desde otro dispositivo hace falta HTTPS: con --https este script
crea un certificado autofirmado y el navegador pedirá aceptarlo una vez
(«Avanzado» -> «Aceptar el riesgo y continuar»).
"""
import argparse
import functools
import http.server
import socket
import ssl
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent
WEB = RAIZ / "build" / "web"
CERTIFICADOS = RAIZ / "build" / "certificado"


def ips_locales() -> list[str]:
    """IPv4 de esta computadora en sus redes; primero las de casa u oficina (192.168.*)."""
    ips = []
    try:
        salida = subprocess.run(["ip", "-4", "-o", "addr", "show", "scope", "global"],
                                capture_output=True, text=True, check=True).stdout
        ips = [linea.split()[3].split("/")[0] for linea in salida.splitlines()]
    except (OSError, subprocess.CalledProcessError, IndexError):
        pass
    if not ips:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(("10.255.255.255", 1))  # no envía nada; sólo elige la interfaz
            ips = [s.getsockname()[0]]
        except OSError:
            ips = []
        finally:
            s.close()
    return sorted(set(ips), key=lambda ip: (not ip.startswith("192.168."), ip))


def certificado(ips: list[str]) -> tuple[Path, Path]:
    """Certificado autofirmado válido para localhost y para las IP locales."""
    CERTIFICADOS.mkdir(parents=True, exist_ok=True)
    nombre = "-".join(ips) or "local"
    cert = CERTIFICADOS / f"cert-{nombre}.pem"
    clave = CERTIFICADOS / f"clave-{nombre}.pem"
    if not cert.exists():
        nombres = ",".join(["DNS:localhost", "IP:127.0.0.1"] + [f"IP:{ip}" for ip in ips])
        subprocess.run(
            ["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "365",
             "-keyout", str(clave), "-out", str(cert),
             "-subj", "/CN=Ladrillos Combinatorios",
             # Certificado de servidor, no de autoridad (CA): Firefox no deja aceptar uno de CA.
             "-addext", "basicConstraints=critical,CA:FALSE",
             "-addext", "keyUsage=critical,digitalSignature,keyEncipherment",
             "-addext", "extendedKeyUsage=serverAuth",
             "-addext", f"subjectAltName={nombres}"],
            check=True, capture_output=True)
    return cert, clave


class Manejador(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, ".wasm": "application/wasm"}

    def log_message(self, formato, *args):
        pass  # sin una línea por cada archivo pedido


def main() -> None:
    p = argparse.ArgumentParser(description="Sirve build/web para jugar en el navegador.")
    p.add_argument("--https", action="store_true", help="HTTPS para entrar desde otros dispositivos de la red")
    p.add_argument("--puerto", type=int, help="puerto (por defecto 8000, o 8443 con --https)")
    args = p.parse_args()

    if not (WEB / "index.html").exists():
        sys.exit("No existe build/web/index.html. Exporta primero el juego (preajuste «Web»).")

    manejador = functools.partial(Manejador, directory=str(WEB))
    if args.https:
        ips = ips_locales()
        puerto = args.puerto or 8443
        servidor = http.server.ThreadingHTTPServer(("0.0.0.0", puerto), manejador)
        contexto = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        contexto.load_cert_chain(*certificado(ips))
        servidor.socket = contexto.wrap_socket(servidor.socket, server_side=True)
        print("Juego disponible con HTTPS:")
        print(f"  En esta computadora:      https://localhost:{puerto}")
        for ip in ips:
            print(f"  Desde otro dispositivo:   https://{ip}:{puerto}")
        if len(ips) > 1:
            print("  (usa la de la red a la que está conectado el otro dispositivo; en casa suele ser 192.168.…)")
        print("El certificado es autofirmado: el navegador mostrará una advertencia la primera vez;")
        print("elige «Avanzado» y luego «Aceptar el riesgo y continuar» (o «Continuar al sitio»).")
    else:
        puerto = args.puerto or 8000
        servidor = http.server.ThreadingHTTPServer(("127.0.0.1", puerto), manejador)
        print(f"Juego disponible en:  http://localhost:{puerto}")
        print("(Usa exactamente esa dirección. Para abrirlo desde otro dispositivo: python3 servir.py --https)")
    print("Ctrl+C para detener.")
    try:
        servidor.serve_forever()
    except KeyboardInterrupt:
        print()


if __name__ == "__main__":
    main()
