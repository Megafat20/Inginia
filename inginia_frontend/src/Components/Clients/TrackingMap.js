/* eslint-disable react-hooks/exhaustive-deps */
import React, { useEffect, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup, useMap } from "react-leaflet";
import L from "leaflet";
import axios from "axios";
import echo from "../../echo";
import "leaflet/dist/leaflet.css";

// Fix icônes
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: require("leaflet/dist/images/marker-icon-2x.png"),
  iconUrl: require("leaflet/dist/images/marker-icon.png"),
  shadowUrl: require("leaflet/dist/images/marker-shadow.png"),
});

// Composant pour recentrer la carte quand la position change
const RecenterMap = ({ lat, lng }) => {
  const map = useMap();
  useEffect(() => {
    map.flyTo([lat, lng], map.getZoom());
  }, [lat, lng]);
  return null;
};

const TrackingMap = ({ reservationId }) => {
  const [position, setPosition] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchInitialPosition = async () => {
      try {
        const token = localStorage.getItem("token");
        const res = await axios.get(
          `http://localhost:8000/api/reservations/${reservationId}`,
          {
            headers: { Authorization: `Bearer ${token}` },
          }
        );

        if (res.data.provider_lat && res.data.provider_lng) {
          setPosition({
            lat: parseFloat(res.data.provider_lat),
            lng: parseFloat(res.data.provider_lng),
          });
        }
      } catch (err) {
        console.error("Erreur fetch initial position:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchInitialPosition();

    console.log(`📡 Connexion au channel reservation.${reservationId}...`);
    const channel = echo.private(`reservation.${reservationId}`);

    channel.listen(".provider.moved", (e) => {
      // console.log("📍 Position reçue:", e);
      setPosition({
        lat: parseFloat(e.latitude),
        lng: parseFloat(e.longitude),
      });
    });

    return () => {
      console.log("Déconnexion tracking");
      echo.leave(`reservation.${reservationId}`);
    };
  }, [reservationId]);

  if (loading)
    return (
      <div className="h-full flex flex-col items-center justify-center bg-gray-50 text-gray-400 animate-pulse">
        <p>Chargement de la carte...</p>
      </div>
    );

  if (!position)
    return (
      <div className="h-full flex flex-col items-center justify-center bg-gray-50 text-gray-500 animate-pulse">
        <span className="text-2xl mb-2">📡</span>
        <p>Recherche du signal GPS du prestataire...</p>
        <p className="text-xs mt-2">
          Le prestataire doit activer sa localisation.
        </p>
      </div>
    );

  return (
    <MapContainer
      center={[position.lat, position.lng]}
      zoom={15}
      style={{ height: "100%", width: "100%" }}
    >
      <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
      <Marker position={[position.lat, position.lng]}>
        <Popup>
          <b>Prestataire en route</b>
          <br />
          Mise à jour en temps réel.
        </Popup>
      </Marker>
      <RecenterMap lat={position.lat} lng={position.lng} />
    </MapContainer>
  );
};

export default TrackingMap;
