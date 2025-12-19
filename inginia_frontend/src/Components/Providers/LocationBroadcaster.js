import React, { useEffect, useState } from "react";
import axios from "axios";

const LocationBroadcaster = ({ reservationId, isTracking }) => {
  const [status, setStatus] = useState("idle"); // idle, tracking, error
  const [coords, setCoords] = useState(null);

  useEffect(() => {
    if (!isTracking || !reservationId) {
      setStatus("idle");
      return;
    }

    // console.log("🛰️ Démarrage du tracking GPS haute précision...");
    setStatus("tracking");

    const watchId = navigator.geolocation.watchPosition(
      (position) => {
        const { latitude, longitude, accuracy } = position.coords;
        // console.log(`📍 Position capturée : ${latitude}, ${longitude} (Précision: ${accuracy}m)`);

        // Filtre basique : Si la précision est trop mauvaise (>100m) on peut choisir d'ignorer ou juste logger
        if (accuracy > 1000) {
          console.warn("Précision GPS faible : " + accuracy + "m");
        }

        setCoords({ latitude, longitude });

        // Envoi au backend
        axios
          .post(
            `http://localhost:8000/api/reservations/${reservationId}/location`,
            { latitude, longitude },
            {
              headers: {
                Authorization: `Bearer ${localStorage.getItem("token")}`,
              },
            }
          )
          .catch((err) => console.error("Erreur envoi GPS", err));
      },
      (error) => {
        console.error("Erreur GPS:", error);
        setStatus("error");
      },
      {
        enableHighAccuracy: true, // Force l'utilisation du GPS matériel
        timeout: 10000, // Timeout de 10s avant erreur
        maximumAge: 0, // Pas de cache de position
      }
    );

    return () => navigator.geolocation.clearWatch(watchId);
  }, [reservationId, isTracking]);

  if (!isTracking) return null;

  return (
    <div className="fixed bottom-20 right-4 md:bottom-4 md:right-4 bg-gray-900/95 backdrop-blur-md text-white px-5 py-3 rounded-2xl shadow-2xl z-[9999] flex items-center gap-4 border border-gray-700 transition-all hover:scale-105 cursor-default">
      {status === "tracking" ? (
        <>
          <div className="relative flex h-3 w-3">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
          </div>
          <div className="flex flex-col">
            <span className="text-xs font-bold uppercase tracking-widest text-green-400">
              LIVE TRACKING
            </span>
            <span className="text-sm font-semibold">
              Position partagée avec le client
            </span>
            {coords && (
              <span className="text-[10px] text-gray-500 font-mono mt-0.5">
                {coords.latitude.toFixed(5)}, {coords.longitude.toFixed(5)}
              </span>
            )}
          </div>
        </>
      ) : status === "error" ? (
        <>
          <div className="w-3 h-3 bg-red-500 rounded-full animate-pulse"></div>
          <div className="flex flex-col">
            <span className="text-xs font-bold uppercase text-red-400">
              ERREUR GPS
            </span>
            <span className="text-sm">Veuillez autoriser la localisation</span>
          </div>
        </>
      ) : null}
    </div>
  );
};

export default LocationBroadcaster;
