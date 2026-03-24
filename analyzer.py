#!/usr/bin/env python3

# ============================================================
# WEB-AX ANALYZER — módulo engine
# "Lee JSON. Imprime cosas. No hace magia. La magia no existe."
# ============================================================

import sys
import json

# Porque claro, todo va a salir perfecto... seguro.


def main():
    raw = sys.stdin.read()

    # Intentamos parsear. Si falla, al menos lo decimos con dignidad.
    try:
        data = json.loads(raw)
    except Exception:
        print("Error leyendo JSON. Nada nuevo.")
        return

    # Si el scanner murió, lo reportamos y nos vamos
    if "error" in data:
        print("Scanner murió:", data["error"])
        return

    # El reporte. Simple. Sin adornos. Como debería ser todo.
    print("\n--- REPORTE ---")
    print("URL:     ", data.get("url"))
    print("Status:  ", data.get("status"))
    print("Latency: ", data.get("latency"))
    print("Server:  ", data.get("server") or "oculto, como tus problemas")


if __name__ == "__main__":
    main()
