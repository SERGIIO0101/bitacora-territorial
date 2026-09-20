# Bitácora Territorial

**Versión 1.2.0 · Editor: Lab-S · Alcaldía Municipal de Simití, Bolívar**

PWA para una referente territorial de alcaldía municipal: capturar evidencias desde el celular durante la
jornada y sacar los entregables oficiales —actas de comité, diapositivas ejecutivas e informe mensual de
ejecución— sin maquetar nada a mano.

El eje del sistema son las **11 obligaciones contractuales**. Todo lo que se captura se clasifica bajo una
de ellas, y los tres entregables se arman leyendo esa clasificación.

## Cómo ejecutarla

Doble clic en **`Abrir Bitacora.bat`**: levanta el servidor y abre la app. La ventana de consola muestra
también la dirección para entrar desde el celular en la misma red Wi-Fi. O a mano:

```bash
python -m http.server 5199 --bind 0.0.0.0
```

Abrir `http://localhost:5199/index.html`.

**Para instalarla como aplicación** (icono propio, pantalla completa, sin señal) hace falta HTTPS: el
navegador no registra el service worker ni da acceso al micrófono en `http://` salvo en `localhost`.
Ver [PUBLICAR.md](PUBLICAR.md) — GitHub Pages, gratis y en diez minutos.

No hay build ni `npm install`: React, Tailwind y Lucide se cargan desde CDN y el JSX se compila en el
navegador con Babel standalone.

## Archivos

| Archivo | Qué es |
|---|---|
| `index.html` | La app completa, lista para servir. **Generado** — no editar a mano. |
| `app.html` | La misma app sin el envoltorio `<html>`, que es lo que se publica como artifact. **Generado.** |
| `build/p1..p9.html` | El código fuente real, por capas. Aquí se edita. |
| `build.py` | Ensambla las capas en `app.html` e `index.html`. |
| `db/schema.json` | Modelo lógico de datos, con notas de diseño por campo. |
| `db/supabase.sql` | Esquema ejecutable: tablas, vistas del semáforo, RLS, storage y siembra de las 11 obligaciones. |
| `prompts/system-prompt-redaccion.md` | System prompt del redactor institucional, con ejemplo de entrada y salida. |
| `docs/` | Lo que sirve GitHub Pages: los 4 archivos que el navegador necesita. **Generado** por `build.py`. |
| `PUBLICAR.md` | Cómo publicarla en GitHub Pages para poder instalarla como app. |
| `Abrir Bitacora.bat` | Doble clic: levanta el servidor local y abre la app en el navegador. |
| `public/` | Escudo del municipio. `build.py` lo optimiza e incrusta; no se referencia como archivo externo. |
| `sw.js`, `manifest.webmanifest`, `icon.svg` | Capa PWA. `icon.svg` lleva el escudo incrustado. |

### Reconstruir después de editar `build/`

```bash
python build.py
```

Regenera `app.html` e `index.html`. Las nueve capas se funden en **un solo** `<script type="text/babel">`:
Babel declara sus helpers (`_excluded`, `_objectWithoutProperties`) en el ámbito global de cada script que
compila, así que dos bloques que usen `...rest` en las props chocan con «Identifier '_excluded' has already
been declared» y el segundo bloque no llega a ejecutarse. `build.py` lo verifica al ensamblar.

### Qué hay en cada capa

| Capa | Contenido |
|---|---|
| `p1` | Tokens de color de los tres temas, estilos de la hoja de documento, reglas de impresión, config de Tailwind y las librerías de CDN. |
| `p2` | Matriz de las 11 obligaciones, utilidades de fecha, semáforo y el motor `redactarInstitucional()`. |
| `p3` | Persistencia en `localStorage`, datos de ejemplo y las salidas (copiar a Word, imprimir, descargar). |
| `p4` | Generadores: acta, informe mensual y diapositivas. |
| `p5` | Primitivas de interfaz y pantalla de Inicio. |
| `p6` | Captura rápida. |
| `p7` | Actas: listado y editor. |
| `p8` | Entregables y Ajustes. |
| `p9` | Visor de documento y la aplicación. |

## Identidad institucional

La app está configurada para el **municipio de Simití, Bolívar**. El escudo de `public/` se incrusta en el
bundle como data URI (`window.ESCUDO_MUNICIPAL`) y aparece en tres sitios: la cabecera de la app, el membrete
de cada acta e informe, y la portada de las diapositivas. Va incrustado y no como archivo externo por dos
razones: el visor de artifacts bloquea imágenes de fuera del documento, y un `.doc` exportado tiene que
abrirse en otro computador sin llevar la carpeta detrás.

`build.py` lo reescala a 320 px y lo cuantiza a 128 colores antes de incrustarlo (66 KB → 35 KB); para
cambiar de municipio basta reemplazar el PNG de `public/` y volver a construir.

Los datos que encabezan y cierran los documentos vienen del portal oficial
(https://www.simiti-bolivar.gov.co): dirección Calle 12 # 5-31 — Palacio Municipal, código postal 135020,
conmutador (+57) 318 354 0171, alcaldia@simiti-bolivar.gov.co, y el lema «Tierra encantadora y bella».
Todos son editables en Ajustes → *Contacto institucional*.

**La secretaría viene en «Secretaría General».** El portal publica el Despacho del Alcalde, la Secretaría
General, la Secretaría de Planeación e Infraestructura y la Secretaría de Desarrollo Económico,
Agroindustrial y Medio Ambiente, pero no dice de cuál depende este contrato: en Ajustes hay un atajo con
esas cuatro y el campo queda libre para escribir otra. El nombre del contratista, el supervisor y el número
de contrato siguen como marcadores entre comillas angulares hasta que los completes.

## Autoría y versión

La ficha de la app vive en un solo sitio, la constante `APP` de `build/p2.html`:

```js
const APP = { nombre:'Bitácora Territorial', version:'1.0.0', editor:'Lab-S', anio:'2026' };
```

De ahí sale el pie de la app y la tarjeta *Acerca de* en Ajustes. `build.py` escribe además las etiquetas
`<meta name="author">` y `<meta name="publisher">` en `index.html`, y el `manifest.webmanifest` lleva
`author` y `publisher`. Al subir de versión hay que tocar tres sitios: `APP.version`, el `version` del
manifest y `CACHE` en `sw.js` (si la versión de caché no cambia, los móviles siguen sirviendo la copia
vieja desde el service worker).

**Lo que esos metadatos no hacen.** La columna *Editor* de «Aplicaciones instaladas» de Windows no se lee
del manifest: la pone el instalador a partir del certificado con que se firmó. Una PWA instalada desde el
navegador aparece publicada por el navegador, no por Lab-S. Para que Windows muestre *Lab-S* ahí hace falta
empaquetarla como MSIX y firmarla con un certificado de firma de código a nombre de Lab-S (unos 200–400 USD
al año en una autoridad certificadora; un certificado autofirmado sirve para pruebas pero dispara la
advertencia de SmartScreen). Lo que sí queda con el nombre: el pie de la app, *Acerca de*, el manifest, las
`<meta>` del HTML y la cabecera de `sw.js`.

**Los documentos oficiales no llevan la marca.** Las actas y los informes se radican a nombre de la
Alcaldía y los firma la contratista con su supervisor; meter un proveedor en el membrete de un documento
oficial es raro y puede generar preguntas en la interventoría. Si aun así lo quieres, es una línea en
`ctrlDoc()` de `build/p4.html`.

## Reglas de uso en campo

La app está construida para usarse de pie, con una mano, saliendo de una reunión.

**Tres toques por acción principal.**

| Acción | Toques |
|---|---|
| Ver el avance | 0 — el semáforo de las 11 obligaciones está en la primera pantalla, sin abrir nada |
| Registrar una foto | `(+)` → *Tomar foto* → *Guardar* |
| Dictar una nota | `(+)` → *Grabar nota* → *Guardar* |
| Exportar cualquier entregable | *Entregables* → el botón del documento (abre la vista previa) |

El dictado usa `continuous: false`: se cierra solo al hacer pausa y redacta el texto institucional sin pedir
un toque de «detener», que sería el cuarto. El botón de detener sigue ahí para cortar antes, pero no es
necesario.

**Botón (+) central.** La barra inferior tiene cuatro destinos y, en el medio, el botón de captura elevado.
Es lo primero que la mano encuentra al abrir la app; dentro de la captura se vuelve una X para salir.

**Cero escritura obligatoria.** Nada en la captura exige teclado: la obligación se elige en tarjetas con
icono, el espacio y el lugar en chips tomados del historial, y los participantes con `−` / `+` y atajos de
5 a 30. El teclado solo aparece si se abre *Más detalles* o se toca *Otro lugar*.

**Autocompletado.** Fecha y hora se ponen solas. La obligación, el tipo, el lugar y la instancia se
precargan con lo más frecuente de los últimos 60 días (`sugerirContexto()` en `build/p2.html`); la tarjeta
sugerida se marca para que se vea por qué viene elegida. El título se deriva de la instancia o del tipo más
la fecha si se deja vacío.

**Feed de tarjetas.** Inicio es un muro tipo red social: foto grande, etiqueta de la obligación, punto
verde/ámbar/rojo del estado y dos acciones al pie (*Ver* y *Acta*). Se revisa con el pulgar, sin abrir nada.
El semáforo completo de las 11 obligaciones sigue a un toque, en *Ver todo*.

**Exportar de un clic.** Los tres entregables salen con un botón cada uno y abren la vista previa de
inmediato. Si el mes no tiene acta levantada, *Acta de comité* arma un borrador con la última sesión
capturada y lo deja editable en la pestaña Actas.

## Decisiones que conviene conocer

**Las metas mensuales son el denominador del semáforo.** Cada obligación trae una `meta` de actividades por
mes (`build/p2.html`, y `sembrar_obligaciones()` en el SQL). Verde ≥ 100 %, ámbar ≥ 40 %, rojo por debajo o
sin registros. Son estimaciones de referencia: ajústalas a la realidad del contrato antes de usarlas para
reportar.

**La nota cruda no se sobrescribe.** Lo que la referente dicta en campo se guarda en `nota_cruda` y la
versión institucional en `descripcion`. Es trazabilidad, y también permite volver a redactar si cambia el
prompt.

**Los documentos se ven siempre en papel blanco**, en los dos temas de la app: son documentos que se
imprimen y se firman, no pantallas.

**Las fotos se comprimen** a 1280 px de lado mayor y JPEG 0.62 antes de guardarse. Si el navegador llena su
cuota, la app guarda los datos sin las imágenes en vez de perder la sesión, y lo avisa en Ajustes.

**Salida a Word.** «Copiar a Word» pone el documento en el portapapeles como `text/html`, así que pegar con
Ctrl+V en Word conserva tablas, encabezados y fotos. «Imprimir / PDF» usa el diálogo del navegador contra un
CSS de impresión con saltos de página en los anexos. La descarga de archivo cambia según dónde corra: en la
PWA local baja un `.doc` que Word abre nativamente; publicada como artifact, la descarga la media la
plataforma y el archivo sale como `.html` (Word lo abre igual y permite «Guardar como .docx»).

## Estado actual y siguiente paso

Es un frontend funcional con estado local. Para llevarlo a producción:

1. Conectar `db/supabase.sql` y reemplazar `cargarEstado`/`guardarEstado` (`build/p3.html`) por el cliente de
   Supabase, subiendo las evidencias al bucket `evidencias` en lugar de guardar data URLs.
2. Conectar el redactor real: `redactarInstitucional()` pasa a ser el respaldo sin conexión y el botón llama a
   la API con el system prompt de `prompts/`.
3. Congelar el informe al radicarlo, guardando su HTML en `informes.html` para que el documento radicado no
   cambie si después se editan las actividades.

## Sobre los datos de ejemplo

La app abre con trece actividades y un acta de muestra de septiembre de 2026, para que el panel y los
entregables se vean funcionando. Las evidencias de ejemplo llevan impreso el rótulo «EVIDENCIA DE EJEMPLO».
El municipio, el escudo y los datos de contacto ya son los reales de Simití; lo que queda como marcador
entre comillas angulares es lo que no se puede deducir: «Nombre del contratista», «C.C. N.º», el supervisor
y el valor mensual. Ajustes → *Quitar datos de ejemplo* borra las actividades y actas de muestra de una vez.
