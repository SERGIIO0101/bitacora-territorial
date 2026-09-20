/* Bitácora Territorial 1.0.0 — service worker · Editor: Lab-S
   La referente trabaja en territorio, muchas veces sin señal: la app debe abrir igual. */
const CACHE = 'bitacora-1.0.0';
const SHELL = ['./', './index.html', './manifest.webmanifest', './icon.svg'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;

  // Navegación: red primero, caché como respaldo cuando no hay señal.
  if (req.mode === 'navigate'){
    e.respondWith(
      fetch(req)
        .then(r => { const copia = r.clone(); caches.open(CACHE).then(c => c.put('./index.html', copia)); return r; })
        .catch(() => caches.match('./index.html'))
    );
    return;
  }

  // Resto (incluidas las librerías de CDN): caché primero y se refresca en segundo plano.
  e.respondWith(
    caches.match(req).then(hit => hit || fetch(req).then(r => {
      if (r && r.status === 200 && (r.type === 'basic' || r.type === 'cors')){
        const copia = r.clone();
        caches.open(CACHE).then(c => c.put(req, copia));
      }
      return r;
    }).catch(() => new Response('', { status:504, statusText:'Sin conexión' })))
  );
});
