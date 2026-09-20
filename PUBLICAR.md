# Publicar la app para poder instalarla

Mientras la app se abre desde `localhost` o desde una IP de la red, el navegador **no la deja instalar**:
exige HTTPS para el service worker y el micrófono. Publicarla en GitHub Pages lo resuelve, es gratis y la
dirección no caduca.

Lo que se publica es la carpeta `docs/`: solo `index.html`, `sw.js`, `manifest.webmanifest` e `icon.svg`.
`build.py` la regenera en cada construcción, así que nunca queda vieja.

---

## Paso 1 — Crear el repositorio (en github.com, 2 minutos)

1. Entra a https://github.com/new
2. **Repository name:** `bitacora-territorial`
3. **Public** (obligatorio: GitHub Pages gratis no funciona en repositorios privados)
4. **No** marques «Add a README file» — este proyecto ya trae el suyo
5. Botón **Create repository**

## Paso 2 — Subir el proyecto

En la carpeta `C:\BitacoraTerritorial`, cambiando `TU-USUARIO` por tu usuario de GitHub:

```bash
git remote add origin https://github.com/TU-USUARIO/bitacora-territorial.git
git push -u origin main
```

La primera vez, Git abrirá una ventana para que inicies sesión en GitHub. Autoriza y listo.

## Paso 3 — Encender GitHub Pages

1. En el repositorio, pestaña **Settings**
2. Menú lateral izquierdo → **Pages**
3. En **Source** elige **Deploy from a branch**
4. En **Branch** elige `main` y, en la carpeta de al lado, **`/docs`**
5. **Save**

Espera 1–2 minutos. La misma página te muestra la dirección:

```
https://TU-USUARIO.github.io/bitacora-territorial/
```

---

## Paso 4 — Instalarla

**En el celular (Android/Chrome):** abre la dirección → menú de tres puntos → **Instalar aplicación**.
Queda con el escudo de Simití en la pantalla de inicio, abre a pantalla completa sin barra del navegador
y funciona sin señal después de la primera carga.

**En el celular (iPhone/Safari):** abre la dirección → botón compartir → **Añadir a pantalla de inicio**.

**En el computador (Chrome o Edge):** abre la dirección → icono de instalar en la barra de direcciones
(o menú → *Instalar Bitácora Territorial*). Queda como programa con su ventana propia.

Después de instalarla ya no necesitas el `Abrir Bitacora.bat` ni tener el computador encendido:
la app vive en el celular.

---

## Cada vez que cambies algo

```bash
python build.py
git add -A
git commit -m "Descripcion del cambio"
git push
```

GitHub Pages se actualiza solo en un minuto. En los celulares que ya la tienen instalada, el service worker
sirve la copia guardada hasta que cambie el nombre de la caché: **sube `CACHE` en `sw.js`** (por ejemplo a
`bitacora-1.0.1`) junto con `APP.version` en `build/p2.html` y `version` en `manifest.webmanifest`, o la
actualización no llegará.

---

## Qué queda público y qué no

Público: el código de la app, el escudo del municipio y los datos de contacto que ya están en el portal
oficial de la alcaldía.

**Nunca se publica tu gestión.** Las actividades, las fotos, las actas y los datos del contrato se guardan
en el almacenamiento del navegador de tu dispositivo (`localStorage`) y no viajan a ningún servidor. GitHub
solo aloja los archivos de la aplicación, igual que un programa instalador no contiene los documentos que
después escribes con él.
