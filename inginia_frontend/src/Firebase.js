// import { initializeApp } from "firebase/app";
// import { getMessaging, getToken, onMessage, deleteToken, isSupported } from "firebase/messaging";

// const firebaseConfig = {
//     apiKey: "AIzaSyBenEhLbRBaM3vMakvAckJQ6rm1Eh7wRmk",
//     authDomain: "inginiaapp.firebaseapp.com",
//     projectId: "inginiaapp",
//     storageBucket: "inginiaapp.firebasestorage.app",
//     messagingSenderId: "1042799065470",
//     appId: "1:1042799065470:web:5c36ad065d915e6634db2f",
// };

// const app = initializeApp(firebaseConfig);

// export const initMessaging = async () => {
//   const supported = await isSupported().catch(() => false);
//   if (!supported) return null;

//   try {
//     const registration = await navigator.serviceWorker.register('/firebase-messaging-sw.js');
//     console.log('SW enregistré:', registration);
//   } catch (err) {
//     console.error('Erreur SW:', err);
//   }


//   const messaging = getMessaging(app);

//   // Demande de permission & token
//   const permission = await Notification.requestPermission();
//   if (permission !== 'granted') return null;

//   // IMPORTANT: ta clé VAPID publique depuis la console Firebase
//   const vapidKey = "BLsxsDjv-FtmlbNzvm_LtsBq1Cp0GV0VWN2rODJ1ZiZqNAaZ_pKD_XlCVeofO7LW4KpS0bhLolnYI9lNp9Uf6BA";

//   const token = await getToken(messaging, { vapidKey });
//   return { messaging, token };
// };

// // écouter les messages en foreground (onglet ouvert)
// export const listenForegroundMessages = (messaging, cb) => {
//   if (!messaging) return;
//   onMessage(messaging, (payload) => cb?.(payload));
// };

// // supprimer le token (logout)
// export const revokeMessaging = async (messaging) => {
//   if (!messaging) return;
//   try { await deleteToken(messaging); } catch {}
// };

// export { app };