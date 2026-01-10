import React, { useEffect, useState, useRef } from "react";
import {
  MapContainer,
  TileLayer,
  Marker,
  Popup,
  Polyline,
  useMap,
} from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { getOngoingReservations } from "./services/ProviderService";
import echo from "../echo";
import {
  FaUserTie,
  FaMapPin,
  FaRoute,
  FaArrowLeft,
  FaClock,
} from "react-icons/fa";
import { useNavigate } from "react-router-dom";

// Fix for default marker icons in Leaflet
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl:
    "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png",
  iconUrl:
    "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png",
  shadowUrl:
    "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png",
});

// Custom Icons
const providerIcon = new L.Icon({
  iconUrl: "https://cdn-icons-png.flaticon.com/512/2830/2830305.png", // Scooter/Delivery icon
  iconSize: [40, 40],
  iconAnchor: [20, 40],
});

const clientIcon = new L.Icon({
  iconUrl: "https://cdn-icons-png.flaticon.com/512/1271/1271167.png", // House/Location icon
  iconSize: [40, 40],
  iconAnchor: [20, 40],
});

// Helper component to auto-zoom/center map when markers change
const ChangeView = ({ center, zoom }) => {
  const map = useMap();
  useEffect(() => {
    map.setView(center, zoom);
  }, [center, zoom, map]);
  return null;
};

const AdminTracking = () => {
  const navigate = useNavigate();
  const [reservations, setReservations] = useState([]);
  const [selectedRes, setSelectedRes] = useState(null);
  const [providerPos, setProviderPos] = useState(null);
  const [route, setRoute] = useState([]);
  const [distance, setDistance] = useState(null);
  const [duration, setDuration] = useState(null);
  const echoRef = useRef(null);

  useEffect(() => {
    loadOngoing();
    const interval = setInterval(loadOngoing, 30000); // Refresh list every 30s
    return () => clearInterval(interval);
  }, []);

  const loadOngoing = async () => {
    const res = await getOngoingReservations();
    setReservations(res);
  };

  const handleSelectReservation = (res) => {
    setSelectedRes(res);
    setProviderPos(
      res.provider_lat && res.provider_lng
        ? [res.provider_lat, res.provider_lng]
        : null
    );

    // Subscribe to real-time updates
    if (echoRef.current) {
      echo.leave(`reservation.${selectedRes?.id}`);
    }

    echoRef.current = echo
      .private(`reservation.${res.id}`)
      .listen(".provider.moved", (e) => {
        console.log("📍 Provider moved:", e);
        setProviderPos([e.latitude, e.longitude]);
      });

    // Initial route calculation if locations are available
    if (res.provider_lat && res.client_lat) {
      fetchRoute(
        [res.provider_lat, res.provider_lng],
        [res.client_lat, res.client_lng]
      );
    }
  };

  const fetchRoute = async (start, end) => {
    try {
      const response = await fetch(
        `https://router.project-osrm.org/route/v1/driving/${start[1]},${start[0]};${end[1]},${end[0]}?overview=full&geometries=geojson`
      );
      const data = await response.json();
      if (data.routes && data.routes[0]) {
        const coords = data.routes[0].geometry.coordinates.map((c) => [
          c[1],
          c[0],
        ]);
        setRoute(coords);
        setDistance((data.routes[0].distance / 1000).toFixed(1));
        setDuration(Math.round(data.routes[0].duration / 60));
      }
    } catch (error) {
      console.error("OSRM Route error:", error);
    }
  };

  useEffect(() => {
    if (selectedRes && providerPos) {
      fetchRoute(providerPos, [selectedRes.client_lat, selectedRes.client_lng]);
    }
  }, [providerPos, selectedRes]);

  return (
    <div className="flex flex-col h-screen bg-slate-50 overflow-hidden">
      {/* Header */}
      <div className="bg-white p-4 border-b flex items-center justify-between shadow-sm z-10">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate("/admin")}
            className="p-2 hover:bg-slate-100 rounded-xl transition-all"
          >
            <FaArrowLeft />
          </button>
          <h1 className="text-xl font-black text-slate-900">
            Suivi <span className="text-blue-600">Live</span> Glovo-Style
          </h1>
        </div>

        {selectedRes && (
          <div className="flex gap-4">
            <div className="bg-blue-50 px-4 py-2 rounded-2xl flex items-center gap-2">
              <FaRoute className="text-blue-600" />
              <span className="text-sm font-black text-blue-700">
                {distance} km
              </span>
            </div>
            <div className="bg-amber-50 px-4 py-2 rounded-2xl flex items-center gap-2">
              <FaClock className="text-amber-600" />
              <span className="text-sm font-black text-amber-700">
                {duration} min
              </span>
            </div>
          </div>
        )}
      </div>

      <div className="flex-1 flex overflow-hidden">
        {/* Sidebar - Ongoing Missions */}
        <div className="w-80 bg-white border-r overflow-y-auto p-4 space-y-4 shadow-xl z-20">
          <h2 className="text-xs font-black text-slate-400 uppercase tracking-widest pl-2">
            Missions en route
          </h2>

          {reservations.length === 0 ? (
            <div className="py-10 text-center opacity-50">
              <p className="text-sm">Aucune mission en cours</p>
            </div>
          ) : (
            reservations.map((r) => (
              <div
                key={r.id}
                onClick={() => handleSelectReservation(r)}
                className={`p-4 rounded-3xl border-2 transition-all cursor-pointer ${
                  selectedRes?.id === r.id
                    ? "border-blue-500 bg-blue-50/30"
                    : "border-slate-50 hover:border-blue-200"
                }`}
              >
                <div className="flex items-center gap-3 mb-3">
                  <div className="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center font-black">
                    {r.provider?.name?.charAt(0)}
                  </div>
                  <div>
                    <p className="text-sm font-black text-slate-800">
                      {r.provider?.name}
                    </p>
                    <p className="text-[10px] font-black uppercase text-blue-600 tracking-tighter">
                      VERS
                    </p>
                  </div>
                </div>
                <div className="space-y-1">
                  <p className="text-xs font-bold text-slate-500 flex items-center gap-2">
                    <FaUserTie size={10} /> Client: {r.client?.name}
                  </p>
                  <p className="text-xs text-slate-400 truncate">
                    {r.commentaire || "Pas de description"}
                  </p>
                </div>
              </div>
            ))
          )}
        </div>

        {/* Map */}
        <div className="flex-1 relative">
          {!selectedRes ? (
            <div className="absolute inset-0 flex items-center justify-center bg-slate-100 z-30">
              <div className="text-center">
                <div className="w-20 h-20 bg-white rounded-full flex items-center justify-center mx-auto mb-4 border-2 border-blue-100 shadow-xl">
                  <FaMapPin className="text-blue-600 text-2xl animate-bounce" />
                </div>
                <p className="text-slate-500 font-bold">
                  Sélectionnez une mission pour voir le suivi en direct
                </p>
              </div>
            </div>
          ) : (
            <MapContainer
              center={providerPos || [33.5731, -7.5898]}
              zoom={13}
              style={{ height: "100%", width: "100%" }}
            >
              <TileLayer
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
              />

              {providerPos && <ChangeView center={providerPos} zoom={15} />}

              {providerPos && (
                <Marker position={providerPos} icon={providerIcon}>
                  <Popup>
                    <div className="font-bold">
                      Prestataire: {selectedRes.provider?.name}
                    </div>
                    <div className="text-xs">En route vers le client...</div>
                  </Popup>
                </Marker>
              )}

              {selectedRes.client_lat && (
                <Marker
                  position={[selectedRes.client_lat, selectedRes.client_lng]}
                  icon={clientIcon}
                >
                  <Popup>
                    <div className="font-bold">
                      Client: {selectedRes.client?.name}
                    </div>
                    <div className="text-xs">
                      {selectedRes.adresse || "Lieu d'intervention"}
                    </div>
                  </Popup>
                </Marker>
              )}

              {route.length > 0 && (
                <Polyline
                  positions={route}
                  color="#4F46E5"
                  weight={5}
                  opacity={0.6}
                  dashArray="10, 10"
                />
              )}
            </MapContainer>
          )}
        </div>
      </div>
    </div>
  );
};

export default AdminTracking;
