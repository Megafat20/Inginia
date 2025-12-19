import React, { useEffect, useState, useRef } from "react";
import echo from "../echo";
import { useAuth } from "./Context/AuthContext";
import axios from "axios";
import { useNavigate } from "react-router-dom";
import {
  FaExclamationTriangle,
  FaMapMarkerAlt,
  FaCheck,
  FaTimes,
} from "react-icons/fa";

const SOSListener = () => {
  const { user } = useAuth();
  const [alertData, setAlertData] = useState(null);
  const audioRef = useRef(null);
  const navigate = useNavigate();

  useEffect(() => {
    // N'écouter que si l'utilisateur est un prestataire
    if (!user || user.role !== "prestataire") return;

    const channel = echo.channel("urgent-requests");

    channel.listen(".urgent.created", (e) => {
      console.log("🔥 URGENCE RECUE :", e);
      const data = e.requestData || e;
      setAlertData(data);
      playAlarm();
    });

    return () => {
      echo.leave("urgent-requests");
      stopAlarm();
    };
  }, [user]);

  const playAlarm = () => {
    if (!audioRef.current) {
      audioRef.current = new Audio("/alert.mp3");
      audioRef.current.loop = true;
    }
    audioRef.current
      .play()
      .catch((e) => console.log("Audio autoplay blocked", e));
  };

  const stopAlarm = () => {
    if (audioRef.current) {
      audioRef.current.pause();
      audioRef.current.currentTime = 0;
    }
  };

  const handleAccept = async () => {
    stopAlarm();
    try {
      const token = localStorage.getItem("token");
      const res = await axios.post(
        "http://localhost:8000/api/sos/accept",
        {
          client_id: alertData.user_id,
          latitude: alertData.latitude,
          longitude: alertData.longitude,
          problem_type: alertData.problem_type,
        },
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (res.data.reservation_id) {
        // On stocke l'ID du chat à ouvrir
        localStorage.setItem("open_chat_id", res.data.reservation_id);
        // Redirection vers le dashboard prestataire qui saura ouvrir le chat
        // On force un reload ou on change de route pour rafraichir
        navigate("/providerdashboard");
        window.location.reload(); // Pour être sûr que le dashboard recharge les réservations et ouvre le chat
      }
    } catch (e) {
      console.error("Erreur accept mission", e);
      alert("Erreur lors de l'acceptation de la mission.");
    }
    setAlertData(null);
  };

  const handleRefuse = () => {
    stopAlarm();
    setAlertData(null);
  };

  if (!alertData) return null;

  return (
    <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/80 backdrop-blur-sm animate-fadeIn">
      {/* Effet rouge pulsatile en fond */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden">
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-red-600 rounded-full blur-[150px] opacity-20 animate-pulse"></div>
      </div>

      <div className="relative bg-white w-full max-w-lg rounded-3xl shadow-2xl overflow-hidden border-4 border-red-500 animate-bounceIn">
        {/* Header Rouge Urgent */}
        <div className="bg-red-600 p-6 text-center relative overflow-hidden">
          <div className="absolute top-0 left-0 w-full h-full bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')] opacity-10"></div>
          <FaExclamationTriangle className="text-white text-6xl mx-auto mb-2 animate-bounce" />
          <h2 className="text-3xl font-black text-white uppercase tracking-wider">
            Urgence SOS
          </h2>
          <p className="text-red-100 font-semibold">
            Intervention immédiate requise
          </p>
        </div>

        <div className="p-8 space-y-6">
          {/* Détails du problème */}
          <div className="text-center">
            <h3 className="text-2xl font-bold text-gray-800 mb-2">
              {alertData.problem_type}
            </h3>
            <p className="text-gray-600 bg-gray-50 p-4 rounded-xl border border-gray-100 italic">
              "{alertData.description}"
            </p>
          </div>

          {/* Localisation (Simulation) */}
          <div className="flex items-center justify-center gap-2 text-blue-600 font-semibold bg-blue-50 py-2 rounded-lg">
            <FaMapMarkerAlt />
            <span>Client à proximité (~2km)</span>
          </div>

          {/* Actions */}
          <div className="grid grid-cols-2 gap-4 pt-4">
            <button
              onClick={handleRefuse}
              className="px-6 py-4 rounded-xl font-bold text-gray-500 hover:bg-gray-100 hover:text-gray-700 transition flex flex-col items-center gap-1"
            >
              <FaTimes className="text-xl" />
              Ignorer
            </button>

            <button
              onClick={handleAccept}
              className="px-6 py-4 rounded-xl font-bold text-white bg-green-600 hover:bg-green-700 shadow-lg hover:shadow-green-500/30 transition flex flex-col items-center gap-1 transform hover:scale-105"
            >
              <FaCheck className="text-xl" />
              ACCEPTER
            </button>
          </div>
        </div>

        {/* Timer Footer (Visuel) */}
        <div className="bg-gray-50 px-6 py-3 text-center text-xs text-gray-400 border-t">
          Appuyez sur ACCEPTER pour confirmer l'intervention.
        </div>
      </div>

      <style>{`
            @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
            @keyframes bounceIn { 
                0% { transform: scale(0.8); opacity: 0; } 
                60% { transform: scale(1.05); opacity: 1; } 
                100% { transform: scale(1); } 
            }
        `}</style>
    </div>
  );
};

export default SOSListener;
