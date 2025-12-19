// import axios from "axios";
// import { getMessaging, getToken, isSupported } from "firebase/messaging";
// import { app } from "../../Firebase";

// export const registerFcmToken = async (authToken) => {
//   try {
//     const supported = await isSupported();
//     if (!supported) return;

//     const messaging = getMessaging(app);
//     const vapidKey = "BLsxsDjv-FtmlbNzvm_LtsBq1Cp0GV0VWN2rODJ1ZiZqNAaZ_pKD_XlCVeofO7LW4KpS0bhLolnYI9lNp9Uf6BA";

//     const fcmToken = await getToken(messaging, { vapidKey });
//     if (!fcmToken) return;

//     await axios.post(
//       "http://localhost:8000/api/devices/register",
//       { token: fcmToken, platform: "web" },
//       { headers: { Authorization: `Bearer ${authToken}` } }
//     );

//     console.log("✅ Token FCM enregistré:", fcmToken);
//   } catch (error) {
//     console.error("❌ Erreur enregistrement FCM:", error);
//   }
// };
