'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "39dea26aab7063ff466c9ad8c5775b22",
"assets/AssetManifest.bin.json": "d86ed9be7f952f0feb4aecf398cd677e",
"assets/AssetManifest.json": "e000c5720246686a3f6656608fe40bae",
"assets/assets/animations/coupon_animation.json": "de476ce8f2c2b22bde0fc04eb356567c",
"assets/assets/fonts/Tajawal-Bold.ttf": "eab7ea352053b0c99755933b0e7ede70",
"assets/assets/fonts/Tajawal-Regular.ttf": "435d5fcde3884b45f82a2bfa34617aea",
"assets/assets/icon/apps.svg": "3bb62fa589b4533da155c89ead1808b0",
"assets/assets/icon/apps_active.svg": "99639af74d900f557a215096b239c542",
"assets/assets/icon/grid.svg": "6b62fdf5a746c95a935a4ec84929d780",
"assets/assets/icon/home.svg": "72366dd8f30acd07ae41d52c1a980822",
"assets/assets/icon/home_active.svg": "e7295ac108b0b9748deac7c42e492080",
"assets/assets/icon/house-blank.svg": "b38192dafcd233ba38669f820b02d908",
"assets/assets/icon/menu.svg": "99639af74d900f557a215096b239c542",
"assets/assets/icon/share.svg": "eb459806926e0beddb9d37e70b7ad8e2",
"assets/assets/icon/share_windows.svg": "55d77c14e41f71466d319c80491dbbb4",
"assets/assets/icon/star.svg": "0439828087dbd33f4e50a2dd78449a4f",
"assets/assets/icon/star_active.svg": "0402a63cccaecc4820075e5c4327a0ab",
"assets/assets/icon/ticket.svg": "4474d6eccbcf087220de427a31199e05",
"assets/assets/icon/ticket_active.svg": "daf5ebc627952b8600393db6c3abad2b",
"assets/assets/image/google.png": "ca2f7db280e9c773e341589a81c15082",
"assets/assets/image/login.png": "151239dbb0326949a97b286ef7909afd",
"assets/assets/image/logine.png": "0e77af196c1321b79e121912d8bcb6a0",
"assets/assets/image/Rbhan.png": "7ff6f7f4342974052ea7538bb70260bc",
"assets/assets/image/Rbhan.svg": "a308d77172b299e1983d946db4ed3808",
"assets/assets/image/signup.png": "b3e9a3e639376b724052eccc46c3b27d",
"assets/assets/image/signupe.png": "96a97c561a62cdcb007888d9aa62f003",
"assets/assets/lang/ar.json": "b787f1179ce44a0fdce0de232dac2d31",
"assets/assets/lang/en.json": "12fc2ae7ce67f2bb849ec075142f7f4b",
"assets/FontManifest.json": "32765036925fab5389d06b2c17dd6b0e",
"assets/fonts/MaterialIcons-Regular.otf": "8893520cd482526069c2b349177a4f22",
"assets/NOTICES": "64e7a8f9c1d39878e755a3a7368e3f12",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/packages/quickalert/assets/confirm.gif": "bdc3e511c73e97fbc5cfb0c2b5f78e00",
"assets/packages/quickalert/assets/error.gif": "c307db003cf53e131f1c704bb16fb9bf",
"assets/packages/quickalert/assets/info.gif": "90d7fface6e2d52554f8614a1f5deb6b",
"assets/packages/quickalert/assets/loading.gif": "ac70f280e4a1b90065fe981eafe8ae13",
"assets/packages/quickalert/assets/success.gif": "dcede9f3064fe66b69f7bbe7b6e3849f",
"assets/packages/quickalert/assets/warning.gif": "f45dfa3b5857b812e0c8227211635cc4",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"favicon.png": "2d88a80763e8bd1765e9c6931ecf49d5",
"flutter.js": "4b2350e14c6650ba82871f60906437ea",
"flutter_bootstrap.js": "f4d8174da2ceaf2d6f63350d803de106",
"icons/apple-touch-icon.png": "d2b1814f4ef6cfa4cfd413a95791125f",
"icons/icon-192.png": "9885992c4c1609f26fc5a9429869684b",
"icons/icon-512.png": "645de80a89294883a964920eab5f277c",
"icons/Icon-maskable-192.png": "51f5a9c65e8ef1ab7a6b82cc3a110f78",
"icons/Icon-maskable-512.png": "8c163a49e9538fa4bf98f01230049bef",
"index.html": "bfaa4457093d7b94d2f3bdf1ce794193",
"/": "bfaa4457093d7b94d2f3bdf1ce794193",
"main.dart.js": "d7b01480f58101d410335263897e7024",
"manifest.json": "ded0e22ae7551004b3eaa8aeb5e0d6a1",
"version.json": "01dc582b311024577f3e95bae7051808"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
