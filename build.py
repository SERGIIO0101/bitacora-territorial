#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Ensambla build/p1..p9.html en:
  app.html    — fragmento que se publica como artifact (sin <html>/<head>/<body>)
  index.html  — página autónoma para servir localmente como PWA

Las capas p2..p9 se concatenan dentro de UN SOLO <script type="text/babel">.
Es obligatorio: Babel declara sus helpers (_excluded, _objectWithoutProperties…)
en el ámbito global de cada script que compila, así que dos bloques que usen
`...rest` en las props chocan con «Identifier '_excluded' has already been
declared» y el segundo bloque no llega a ejecutarse.
"""
import base64
import io
import os
import re
import sys

RAIZ = os.path.dirname(os.path.abspath(__file__))
CAPAS = ['p%d.html' % n for n in range(1, 10)]
ESCUDO = os.path.join(RAIZ, 'public', 'Escudo_del_municipio_de_simiti.png')
ESCUDO_ANCHO = 320      # ~4x el tamaño impreso en el membrete
ESCUDO_COLORES = 128
ABRE_SCRIPT = re.compile(r'^\s*<script type="text/babel"[^>]*>\s*\n', re.M)
CIERRA_SCRIPT = re.compile(r'\n\s*</script>\s*$')

ENVOLTURA = u'''<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="description" content="Captura de evidencias en campo y generacion de actas, diapositivas e informes de ejecucion contractual.">
<meta name="theme-color" content="#0E5A78">
<meta name="author" content="Lab-S">
<meta name="publisher" content="Lab-S">
<meta name="application-name" content="Bitacora Territorial">
<meta name="version" content="1.0.0">
<link rel="manifest" href="manifest.webmanifest">
<link rel="icon" href="icon.svg" type="image/svg+xml">
<style>
  :root{color-scheme:light dark;padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}
  body{margin:0}
  img{max-width:100%}
  [hidden]{display:none!important}
</style>
@@HEAD@@</head>
<body>
@@BODY@@</body>
</html>
'''


def escudo_data_uri():
    """El escudo de public/ viaja incrustado: el visor de artifacts bloquea
    imágenes externas y los .doc exportados tienen que abrir sin la carpeta."""
    if not os.path.exists(ESCUDO):
        print('aviso: no hay escudo en public/, se usa el marcador de texto')
        return ''
    crudo = open(ESCUDO, 'rb').read()
    try:
        from PIL import Image
        im = Image.open(io.BytesIO(crudo)).convert('RGB')
        alto = int(round(im.size[1] * (ESCUDO_ANCHO / float(im.size[0]))))
        buf = io.BytesIO()
        (im.resize((ESCUDO_ANCHO, alto), Image.LANCZOS)
           .quantize(colors=ESCUDO_COLORES, method=Image.MEDIANCUT)
           .save(buf, format='PNG', optimize=True))
        if buf.tell() < len(crudo):
            crudo = buf.getvalue()
    except ImportError:
        print('aviso: sin Pillow, el escudo se incrusta sin optimizar')
    print('escudo     %7d bytes incrustados' % len(crudo))
    return 'data:image/png;base64,' + base64.b64encode(crudo).decode('ascii')


PUBLICABLES = ['index.html', 'sw.js', 'manifest.webmanifest', 'icon.svg']


def publicar_docs():
    """docs/ es lo que sirve GitHub Pages: solo los 4 archivos que el
    navegador necesita. Se regenera en cada build para que nunca quede vieja."""
    destino = os.path.join(RAIZ, 'docs')
    if not os.path.isdir(destino):
        os.makedirs(destino)
    io.open(os.path.join(destino, '.nojekyll'), 'w', encoding='utf-8').write('')
    for nombre in PUBLICABLES:
        origen = os.path.join(RAIZ, nombre)
        if not os.path.exists(origen):
            sys.exit('Falta %s para publicar' % origen)
        open(os.path.join(destino, nombre), 'wb').write(open(origen, 'rb').read())
    print('docs/      %d archivos listos para GitHub Pages' % len(PUBLICABLES))


def leer(nombre):
    ruta = os.path.join(RAIZ, 'build', nombre)
    if not os.path.exists(ruta):
        sys.exit('Falta la capa %s' % ruta)
    return io.open(ruta, encoding='utf-8').read()


def cuerpo_jsx(texto, nombre):
    """Quita el <script> de apertura y cierre para poder fundir las capas."""
    sin_apertura, n = ABRE_SCRIPT.subn('', texto, count=1)
    if not n:
        sys.exit('La capa %s no abre con <script type="text/babel">' % nombre)
    sin_cierre, n = CIERRA_SCRIPT.subn('', sin_apertura.rstrip(), count=1)
    if not n:
        sys.exit('La capa %s no cierra con </script>' % nombre)
    return sin_cierre


def main():
    cabecera = leer(CAPAS[0])
    partes = [cuerpo_jsx(leer(c), c) for c in CAPAS[1:]]

    escudo = ('<script>' + chr(10) + '  window.ESCUDO_MUNICIPAL = "' + escudo_data_uri() + '";' + chr(10) + '</script>' + chr(10) + chr(10))

    app = (cabecera.rstrip() + '\n\n' + escudo
           + '<script type="text/babel" data-presets="react">\n'
           + '\n\n'.join(partes)
           + '\n</script>\n')
    io.open(os.path.join(RAIZ, 'app.html'), 'w', encoding='utf-8').write(app)

    corte = app.index('<div id="root">')
    pagina = ENVOLTURA.replace('@@HEAD@@', app[:corte]).replace('@@BODY@@', app[corte:])
    io.open(os.path.join(RAIZ, 'index.html'), 'w', encoding='utf-8').write(pagina)

    print('app.html   %7d caracteres' % len(app))
    print('index.html %7d caracteres' % len(pagina))
    print('bloques text/babel: 1')
    publicar_docs()


if __name__ == '__main__':
    main()
