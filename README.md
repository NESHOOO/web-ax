# WEB-AX v1.0
### *"Porque claramente el sistema no se va a romper solo"*

> Un escáner web minimalista, funcional, y escrito con el nivel exacto de entusiasmo que merece un lunes por la mañana.

---

## ¿Qué es esto?

**web-ax** es una herramienta de línea de comandos que escanea una URL y te dice cosas que probablemente ya sabías:

- Si el servidor responde (o no, como la gente)
- El HTTP status code
- La latencia
- Qué servidor usa (si es que no lo oculta, como sus problemas)

Está escrita en Go y Python. Porque una sola tecnología habría sido demasiado simple, y la simplicidad está sobrevalorada.

---

## Requisitos

Lo mínimo para que esto funcione. Igual que en la vida.

| Cosa | Por qué |
|------|---------|
| `bash` | Obvio. Si no tienes bash, tienes problemas más grandes. |
| `go` | Para compilar el escáner. Sí, compilamos en instalación. No, no es ideal. |
| `python3` | Para el analyzer. Viene de fábrica en Linux Mint, así que no hay excusa. |
| `sudo` | Para instalar en rutas del sistema. Si no tienes sudo, habla con tu sysadmin. |

---

## Instalación

```bash
# Dale permisos (porque los archivos no se ejecutan solos)
chmod +x web_ax_installer_pro.sh

# Instala (y reza un poco si quieres, no hace daño)
sudo ./web_ax_installer_pro.sh install
```

El installer va a:

1. Verificar que tienes `go` y `python3` — si no los tienes, te lo dice con toda la dignidad posible y se va
2. Pedir `sudo` **antes** de empezar — no a mitad, no cuando ya rompiste algo
3. Generar el código fuente (sí, lo genera al vuelo, es una decisión de diseño, no un bug)
4. Compilar el binario de Go
5. Copiar todo a `/usr/local/share/web-ax/`
6. Crear el comando `web-ax` en `/usr/local/bin/`
7. Guardar tu configuración en `~/.config/web-ax/config`
8. Limpiar los temporales — porque el orden es una virtud, aunque nadie lo practique

Si algo falla en el camino, el installer limpia lo que generó. No te deja basura. Al menos uno de nosotros tiene principios.

---

## Uso

```bash
# Uso básico
web-ax https://ejemplo.com

# Con verbose (para cuando necesitas más información de la que querías)
web-ax --verbose https://ejemplo.com

# Con debug (para cuando verbose no fue suficiente sufrimiento)
web-ax --debug https://ejemplo.com
```

### Ejemplo de salida

```
--- REPORTE ---
URL: https://ejemplo.com
Status: 200
Server: nginx
```

O si el servidor oculta su identidad:

```
Server: oculto, como tus problemas
```

---

## Configuración

El archivo de config vive en `~/.config/web-ax/config`. Puedes editarlo a mano porque somos personas civilizadas:

```ini
lang=es
timeout=15
min_severity=MEDIUM
```

| Variable | Qué hace | Default | Observaciones |
|----------|----------|---------|---------------|
| `lang` | Idioma de reportes | `es` | Reservado para soporte multilenguaje futuro. Por ahora solo `es`. Ambicioso, pero honesto. |
| `timeout` | Segundos antes de rendirse | `15` | Solo números enteros. El installer valida esto. No seas creativo. |
| `min_severity` | Severidad mínima de CVEs | `MEDIUM` | Feature futura. Por ahora solo está ahí para que el archivo no se vea vacío. |

> ⚠️ **Nota sobre `timeout`:** Si pones algo que no sea un número entero, el installer lo ignora y usa el default. No porque sea inteligente, sino porque aprendimos de los errores ajenos.

---

## Estructura del proyecto

```
/usr/local/share/web-ax/
├── core/
│   └── web-ax-scanner      # Binario Go. Hace el HTTP GET. Simple. Funcional.
└── engine/
    └── analyzer.py         # Script Python. Procesa el JSON. También simple.

/usr/local/bin/
└── web-ax                  # Wrapper bash. Una capa más de complejidad inútil,
                            # pero al menos está documentada.

~/.config/web-ax/
└── config                  # Tu configuración. Tuya. No la pierdas.
```

---

## Cómo funciona por dentro

Para los curiosos, los masoquistas, o quien tenga que mantener esto después:

```
web-ax <url>
    │
    ▼
web-ax-scanner (Go)
    │  Hace GET a la URL
    │  Mide latencia
    │  Regresa JSON por stdout
    │
    ▼
analyzer.py (Python)
    │  Lee el JSON por stdin
    │  Formatea el reporte
    │  Lo imprime
    ▼
Tu terminal
    (esperando respuestas que el universo no tiene)
```

Sí, es un pipe. Sí, es simple. No, no hay base de datos. No, no hay dashboard. Eso es un feature, no una limitación.

---

## Desinstalación

El installer no incluye uninstall. Porque nadie nunca desinstala nada, todos sabemos cómo termina eso.

Pero si eres de los pocos con disciplina:

```bash
sudo rm -rf /usr/local/share/web-ax
sudo rm /usr/local/bin/web-ax
rm -rf ~/.config/web-ax
```

Listo. Como si nunca hubiera existido. Igual que algunas relaciones.

---

## Preguntas frecuentes

**¿Por qué compila en tiempo de instalación?**
Porque así funciona. Si quieres un binario pre-compilado, mándame un PR.

**¿Por qué Go y Python juntos?**
Go para velocidad en el HTTP. Python para flexibilidad en el análisis. O quizás fue un accidente que escaló. Las dos cosas pueden ser verdad.

**¿Qué pasa si no tengo `go` instalado?**
El installer te lo dice claramente y se detiene. No adivina, no intenta workarounds creativos, no falla silenciosamente. Solo te dice la verdad. Un lujo poco común.

**¿Soporta HTTPS?**
Sí. Si la URL empieza con `http` la usa tal cual. Si no, le agrega `http://`. Para forzar HTTPS simplemente ponlo en la URL.

**¿Tiene tests?**
No. Siguiente pregunta.

---

## Changelog

### v1.0 — *"Hardened Edition"*
- ✅ Validación de `timeout` antes de interpolarlo en código Go (era un bug, ahora no)
- ✅ Verificación de `sudo` al inicio, no cuando ya es tarde
- ✅ Limpieza automática de temporales en caso de fallo
- ✅ `$FLAG` con comillas en el wrapper (pequeño, importante, ignorado hasta hoy)
- ✅ Comentarios sarcásticos intactos — algunos bugs se corrigen, el tono no

### v0.9 — *"Pro Edition"*
- Versión inicial. Funcionaba. Más o menos.

---

## Licencia

Úsalo, modifícalo, rómpelo. Si lo mejoras, comparte. Si lo rompes, no me menciones.

---

*Escrito con resignación productiva y café insuficiente.*
