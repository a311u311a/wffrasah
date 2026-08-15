importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBsK3Pi9_3tsBwVJRyAGL2_zeOxUpLXYJc',
  authDomain: 'coupon-d52b2.firebaseapp.com',
  databaseURL: 'https://coupon-d52b2-default-rtdb.firebaseio.com',
  projectId: 'coupon-d52b2',
  storageBucket: 'coupon-d52b2.appspot.com',
  messagingSenderId: '314843853869',
  appId: '1:314843853869:web:66cbfb1794075edb4f74a4',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const data = payload.data || {};
  const title = notification.title || data.title || 'New notification';
  const options = {
    body: notification.body || data.body || '',
    icon: '/icons/icon-192.png',
    image: notification.image || data.image_url,
    data,
  };

  self.registration.showNotification(title, options);
});
