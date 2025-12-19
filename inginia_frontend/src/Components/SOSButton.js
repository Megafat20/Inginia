import React, { useState } from "react";
import axios from "../axios"; // Assurez-vous que le chemin est correct

const SOSButton = () => {
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState(null);

  const handleSOS = () => {
    if (
      !window.confirm(
        "Êtes-vous sûr de vouloir lancer une alerte SOS Urgence ?"
      )
    )
      return;

    setLoading(true);
    setMessage(null);

    if (!navigator.geolocation) {
      alert("La géolocalisation n'est pas supportée par votre navigateur.");
      setLoading(false);
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords;

        // Envoi de l'alerte au backend
        axios
          .post("/api/sos", {
            latitude,
            longitude,
            problem_type: "general", // Pourrait être dynamique (choix user)
            description: "Urgence signalée via le bouton SOS",
          })
          .then((response) => {
            setMessage("🚨 Alerte envoyée aux prestataires !");
            // alert("Alerte SOS diffusée avec succès !");
          })
          .catch((error) => {
            console.error("Erreur SOS:", error);
            setMessage("❌ Erreur lors de l'envoi de l'alerte.");
          })
          .finally(() => {
            setLoading(false);
          });
      },
      (error) => {
        console.error("Erreur GPS:", error);
        setMessage("❌ Impossible d'obtenir votre position.");
        setLoading(false);
      }
    );
  };

  return (
    <div
      style={{ position: "fixed", bottom: "30px", right: "30px", zIndex: 1000 }}
    >
      <button
        onClick={handleSOS}
        disabled={loading}
        title="Urgence SOS"
        style={{
          backgroundColor: "#ff4444",
          color: "white",
          width: "80px",
          height: "80px",
          borderRadius: "50%",
          border: "4px solid white",
          fontSize: "18px",
          fontWeight: "bold",
          boxShadow: "0 4px 20px rgba(255, 68, 68, 0.6)",
          cursor: loading ? "not-allowed" : "pointer",
          animation: loading ? "pulse 1.5s infinite" : "none",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          flexDirection: "column",
        }}
      >
        {loading ? (
          <span style={{ fontSize: "20px" }}>⌛</span>
        ) : (
          <>
            <span style={{ fontSize: "24px" }}>🚨</span>
            <span style={{ fontSize: "12px" }}>SOS</span>
          </>
        )}
      </button>
      {message && (
        <div
          style={{
            position: "absolute",
            bottom: "90px",
            right: "0",
            backgroundColor: "white",
            padding: "10px",
            borderRadius: "8px",
            boxShadow: "0 2px 10px rgba(0,0,0,0.1)",
            width: "200px",
            fontSize: "14px",
            color: "#333",
            textAlign: "center",
          }}
        >
          {message}
        </div>
      )}

      <style>
        {`
                @keyframes pulse {
                    0% { transform: scale(1); box-shadow: 0 0 0 0 rgba(255, 68, 68, 0.7); }
                    70% { transform: scale(1.1); box-shadow: 0 0 0 20px rgba(255, 68, 68, 0); }
                    100% { transform: scale(1); box-shadow: 0 0 0 0 rgba(255, 68, 68, 0); }
                }
        `}
      </style>
    </div>
  );
};

export default SOSButton;
