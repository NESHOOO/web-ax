package main

// ============================================================
// WEB-AX SCANNER — módulo core
// "Hace un GET. Mide cuánto tarda. Se va. Como debería ser todo."
// ============================================================

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"
)

func main() {
	if len(os.Args) < 2 {
		// Sin URL no hay escáner. Sin escáner no hay reporte. Sin reporte, ¿para qué estás aquí?
		fmt.Println("{\"error\":\"no url\"}")
		return
	}

	target := os.Args[1]

	// Si no trae esquema lo asumimos http (el optimismo tiene sus usos)
	if !strings.HasPrefix(target, "http") {
		target = "http://" + target
	}

	// Timeout configurable en el installer — por defecto 15s
	// Si el servidor tarda más que eso, el problema no somos nosotros
	client := &http.Client{Timeout: time.Second * 15}
	start := time.Now()

	resp, err := client.Get(target)
	if err != nil {
		out, _ := json.Marshal(map[string]string{"error": err.Error()})
		fmt.Println(string(out))
		return
	}
	defer resp.Body.Close()

	// Empaquetamos lo que nos importa y nos vamos
	out, _ := json.Marshal(map[string]interface{}{
		"url":     target,
		"status":  resp.StatusCode,
		"latency": time.Since(start).String(),
		"server":  resp.Header.Get("Server"),
	})

	fmt.Println(string(out))
}
