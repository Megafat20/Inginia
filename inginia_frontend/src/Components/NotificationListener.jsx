/* eslint-disable react-hooks/exhaustive-deps */
import React, { useEffect } from "react";
import { useAuth } from "./Context/AuthContext";
import echo from "../echo";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

const NotificationListener = () => {
  const { user } = useAuth();

  useEffect(() => {
    const userId = user?.id || user?._id || user?.pk;
    if (!userId) {
      console.log("🔔 [NotificationListener] Pas d'ID utilisateur, attente...");
      return;
    }

    console.log(
      `🔔 [NotificationListener] Tentative de connexion au canal App.Models.User.${userId}...`
    );

    // On s'assure d'écouter sur le canal privé
    const channel = echo.private(`App.Models.User.${userId}`);

    // On écoute les événements de type 'notification' (broadcastAs)
    channel.listen(".notification", (e) => {
      console.log("✅ [NotificationListener] EVENEMENT RECU !", e);

      toast.info(
        <div className="flex flex-col">
          <span className="font-bold text-slate-900 border-b border-gray-100 pb-1 mb-1">
            {e.title || "Nouveau message"}
          </span>
          <span className="text-sm text-slate-600 line-clamp-2">
            {e.body || e.message}
          </span>
        </div>,
        {
          position: "top-right",
          autoClose: 5000,
          hideProgressBar: false,
          closeOnClick: true,
          pauseOnHover: true,
          draggable: true,
          theme: "colored",
        }
      );
    });

    // Debugging channel subscription
    channel.on("pusher:subscription_succeeded", () => {
      console.log(
        `📡 [NotificationListener] Abonnement RÉUSSI au canal privé ${userId}`
      );
    });

    channel.on("pusher:subscription_error", (status) => {
      console.error(
        `❌ [NotificationListener] Erreur d'abonnement au canal privé ${userId}:`,
        status
      );
    });

    return () => {
      console.log(
        `🔕 [NotificationListener] Quitte le canal App.Models.User.${userId}`
      );
      echo.leave(`App.Models.User.${userId}`);
    };
  }, [user?.id]); // Utiliser l'id pour éviter les rerenders inutiles si l'objet changes

  return null;
};

export default NotificationListener;
