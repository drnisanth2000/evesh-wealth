// Firebase Cloud Messaging Service Worker
// Handles background push notifications on web

importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

// Firebase config is injected at runtime via Flutter's --dart-define
// The service worker reads it from the main app via postMessage
let messaging = null;

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'FIREBASE_CONFIG') {
    if (!messaging) {
      firebase.initializeApp(event.data.config);
      messaging = firebase.messaging();
    }
  }
});

// Show background push notification
self.addEventListener('push', (event) => {
  if (!event.data) return;

  let payload;
  try {
    payload = event.data.json();
  } catch (_) {
    payload = { notification: { title: 'eVesh Alert', body: event.data.text() } };
  }

  const notification = payload.notification || {};
  const data = payload.data || {};

  const options = {
    body: notification.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: data.tag || 'evesh-alert',
    renotify: true,
    vibrate: [200, 100, 200],
    data: { url: data.click_action || '/alerts' },
    actions: [
      { action: 'view', title: 'View' },
      { action: 'dismiss', title: 'Dismiss' },
    ],
  };

  const severity = data.severity || 'LOW';
  if (severity === 'URGENT') options.urgency = 'high';

  event.waitUntil(
    self.registration.showNotification(notification.title || 'eVesh', options),
  );
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  if (event.action === 'dismiss') return;

  const url = event.notification.data?.url || '/alerts';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.focus();
          client.postMessage({ type: 'NAVIGATE', url });
          return;
        }
      }
      return clients.openWindow(url);
    }),
  );
});
