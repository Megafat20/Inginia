import Echo from "laravel-echo";
import Pusher from "pusher-js";

window.Pusher = Pusher;

const echo = new Echo({
  broadcaster: "reverb",
  key: process.env.REACT_APP_REVERB_APP_KEY || "inginia-key",
  wsHost: process.env.REACT_APP_REVERB_HOST || "localhost",
  wsPort: process.env.REACT_APP_REVERB_PORT || 8080,
  wssPort: process.env.REACT_APP_REVERB_PORT || 8080,
  forceTLS: (process.env.REACT_APP_REVERB_SCHEME || "http") === "https",
  enabledTransports: ["ws", "wss"],
  disableStats: true,

  // Endpoint d'authentification pour les canaux privés
  authEndpoint: "http://localhost:8000/broadcasting/auth",

  auth: {
    headers: {
      get Authorization() {
        return `Bearer ${localStorage.getItem("token")}`;
      },
    },
  },
});

export default echo;
