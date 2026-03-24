#!/usr/bin/env bash

# ============================================================
# WEB-AX INSTALLER v3.1 (PRO / HARDENED EDITION)
# "Porque claramente el sistema no se va a romper solo..."
# ============================================================

set -euo pipefail
IFS=$'\n\t'

# --- Señales (por si decides cancelar como todo lo demás en tu vida) ---
trap 'cleanup; echo "[!] Interrumpido. Nada sorprendente."; exit 1' INT TERM

# --- Colores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m'

log(){ echo -e "$1"; }
info(){ log "${BLUE}[INFO]${NC} $1"; }
ok(){ log "${GREEN}[OK]${NC}   $1"; }
warn(){ log "${YELLOW}[WARN]${NC} $1"; }
err(){ log "${RED}[ERR]${NC}  $1"; }

# --- Paths (porque confiar en el cwd es como confiar en la gente) ---
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$BASE_DIR/core"
ENGINE_DIR="$BASE_DIR/engine"
INSTALL_DIR="/usr/local/share/web-ax"
BIN_PATH="/usr/local/bin/web-ax"
CONFIG_FILE="$HOME/.config/web-ax/config"

# --- Defaults ---
SCANNER_TIMEOUT=15
REPORT_LANG="es"
MIN_CVE_SEVERITY="MEDIUM"

# ============================================================
# LIMPIEZA (para cuando todo sale como siempre: mal)
# ============================================================

cleanup(){
    if [[ -d "$CORE_DIR" || -d "$ENGINE_DIR" ]]; then
        warn "Limpiando archivos generados... como si nada hubiera pasado"
        rm -rf "$CORE_DIR" "$ENGINE_DIR"
    fi
}

# Si algo explota en medio de la instalación, limpiamos
# (porque dejar basura es para los que no tienen dignidad)
trap 'cleanup; err "Instalación fallida. Sorprendente. No."; exit 1' ERR

# ============================================================
# UTILIDADES SEGURAS
# ============================================================

run(){
    # Ejecuta sin eval (porque no somos salvajes)
    local desc="$1"; shift
    if "$@"; then
        ok "$desc"
    else
        err "$desc falló. Como todo eventualmente."
        exit 1
    fi
}

require(){
    command -v "$1" &>/dev/null || { err "$1 no está instalado. Instálalo y vuelve a intentarlo, si tienes energía."; exit 1; }
}

# Verifica sudo antes de usarlo (porque asumir que tienes permisos
# es exactamente el tipo de optimismo que destruye servidores)
require_sudo(){
    if ! sudo -n true 2>/dev/null; then
        warn "Necesito sudo. Por favor autentica..."
        sudo true || { err "Sin sudo no hay instalación. Igual que en la vida real."; exit 1; }
    fi
    ok "sudo verificado"
}

# ============================================================
# CONFIG PARSER (sin ejecutar código, porque no somos idiotas)
# ============================================================

load_config(){
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS="=" read -r k v; do
            case "$k" in
                lang) REPORT_LANG="$v" ;;
                timeout)
                    # Validamos que sea un número entero (porque el mundo está lleno de gente creativa)
                    if [[ "$v" =~ ^[0-9]+$ ]]; then
                        SCANNER_TIMEOUT="$v"
                    else
                        warn "timeout inválido en config ('$v'). Usando default: $SCANNER_TIMEOUT"
                    fi
                    ;;
                min_severity) MIN_CVE_SEVERITY="$v" ;;
            esac
        done < "$CONFIG_FILE"
    fi
}

save_config(){
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" <<EOF
lang=$REPORT_LANG
timeout=$SCANNER_TIMEOUT
min_severity=$MIN_CVE_SEVERITY
EOF
}

# ============================================================
# GENERACIÓN DE ARCHIVOS
# ============================================================

create_files(){
    info "Creando estructura... porque nada existe hasta que lo creas tú"
    mkdir -p "$CORE_DIR" "$ENGINE_DIR"

    # Timeout validado antes de llegar aquí, así que la interpolación es segura
    # (pero lo validamos igual, porque la paranoia es una virtud)
    local safe_timeout
    if [[ "$SCANNER_TIMEOUT" =~ ^[0-9]+$ ]]; then
        safe_timeout="$SCANNER_TIMEOUT"
    else
        warn "Timeout sospechoso detectado. Usando 15 por defecto."
        safe_timeout=15
    fi

    cat > "$CORE_DIR/scanner.go" <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "net/http"
    "os"
    "strings"
    "time"
)

func main(){
    if len(os.Args) < 2 {
        fmt.Println("{\\"error\\":\\"no url\\"}")
        return
    }

    target := os.Args[1]
    if !strings.HasPrefix(target, "http") {
        target = "http://" + target
    }

    client := &http.Client{Timeout: time.Second * ${safe_timeout}}
    start := time.Now()

    resp, err := client.Get(target)
    if err != nil {
        out,_ := json.Marshal(map[string]string{"error": err.Error()})
        fmt.Println(string(out))
        return
    }
    defer resp.Body.Close()

    out,_ := json.Marshal(map[string]interface{}{
        "url": target,
        "status": resp.StatusCode,
        "latency": time.Since(start).String(),
        "server": resp.Header.Get("Server"),
    })

    fmt.Println(string(out))
}
EOF

    cat > "$ENGINE_DIR/analyzer.py" <<'EOF'
import sys, json

# Porque claro, todo va a salir perfecto... seguro.

def main():
    raw = sys.stdin.read()
    try:
        data = json.loads(raw)
    except Exception:
        print("Error leyendo JSON. Nada nuevo.")
        return

    if "error" in data:
        print("Scanner murió:", data["error"])
        return

    print("\n--- REPORTE ---")
    print("URL:", data.get("url"))
    print("Status:", data.get("status"))
    print("Server:", data.get("server") or "oculto, como tus problemas")

if __name__ == "__main__":
    main()
EOF

    ok "Archivos generados"
}

# ============================================================
# BUILD
# ============================================================

build(){
    info "Compilando... porque nada dice estabilidad como compilar en producción"
    (
        cd "$CORE_DIR"
        # go mod init falla si ya existe — lo ignoramos con dignidad
        go mod init webax 2>/dev/null || true
        if ! go build -o web-ax-scanner scanner.go; then
            err "El compilador también tuvo un mal día."
            exit 1
        fi
    )
    ok "Compilado"
}

# ============================================================
# INSTALL
# ============================================================

install(){
    info "Verificando dependencias"
    require go
    require python3
    require_sudo

    load_config
    create_files
    build

    run "Crear dirs"     sudo mkdir -p "$INSTALL_DIR/core" "$INSTALL_DIR/engine"
    run "Copiar binario" sudo cp "$CORE_DIR/web-ax-scanner" "$INSTALL_DIR/core/"
    run "Copiar analyzer" sudo cp "$ENGINE_DIR/analyzer.py" "$INSTALL_DIR/engine/"

    sudo tee "$BIN_PATH" >/dev/null <<'EOF'
#!/usr/bin/env bash

# wrapper (porque todo necesita una capa más de complejidad inútil)

FLAG=""
if [[ "${1:-}" == "--verbose" || "${1:-}" == "--debug" ]]; then
    FLAG="$1"
    shift
fi

# Validamos que haya URL (el optimismo no es una estrategia)
if [[ -z "${1:-}" ]]; then
    echo "Uso: web-ax [--verbose|--debug] <url>"
    exit 1
fi

/usr/local/share/web-ax/core/web-ax-scanner "$1" | python3 /usr/local/share/web-ax/engine/analyzer.py "$FLAG"
EOF

    run "Permisos" sudo chmod +x "$BIN_PATH"

    # Limpiamos temporales (orden y dignidad, en ese orden)
    rm -rf "$CORE_DIR" "$ENGINE_DIR"

    save_config

    ok "Instalado, otra cosa mas checa README:dm o aprende a usalo no te voy a enseñar nada."
}

# ============================================================
# MAIN
# ============================================================

case "${1:-install}" in
    install) install ;;
    *) echo "uso: $0 install" ;;
esac
