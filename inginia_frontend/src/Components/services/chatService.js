import axios from "axios";

const API_URL = "http://localhost:8000/api";

// Récupérer le token depuis le localStorage ou contexte
const getAuthHeaders = () => {
  const token = localStorage.getItem("token"); // ou depuis ton contexte Auth
  return {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  };
};

// Récupérer tous les messages d'une réservation
export const getMessages = async (reservationId) => {
  try {
    const response = await axios.get(
      `${API_URL}/reservations/${reservationId}/messages`,
      getAuthHeaders()
    );
    return response.data; // { messages: [...] }
  } catch (err) {
    console.error("Erreur lors de la récupération des messages:", err);
    throw err;
  }
};

// Envoyer un message pour une réservation
export const sendMessage = async (reservationId, messageData) => {
  try {
    const response = await axios.post(
      `${API_URL}/reservations/${reservationId}/messages`,
      messageData,
      getAuthHeaders()
    );
    return response.data.message; // { id, content, sender_id, created_at, ... }
  } catch (err) {
    console.error("Erreur lors de l'envoi du message:", err);
    throw err;
  }
};
