#OFFLINE_VERSION = pwa.offline.version
CACHE_NAME = 'tiny-umbrella-cache'
OFFLINE_URL = '/tiny-umbrella/index.html'

self.addEventListener 'install', (evt) =>
  evt.waitUntil(() =>
    cache = await caches.open CACHE_NAME
    cache.add(new Request OFFLINE_URL, {cache: 'reload'})
  )()

self.addEventListener 'activate', (evt) =>
  evt.waitUntil(() =>
    if self.registration.navigationPreload?
      t = await self.registration.navigationPreload.enable()
  )()
  self.clients.claim()


self.addEventListener 'fetch', (evt) =>
  #
  #console.log 'fetching...'
  null
