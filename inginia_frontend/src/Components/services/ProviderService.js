// src/services/ProviderService.js
import axios from "axios";
import { getMessaging, getToken } from "firebase/messaging";
const API_URL = "http://localhost:8000/api"; // adapte selon ton backend

// === FONCTION UTILITAIRE POUR RÉCUPÉRER LE TOKEN ===
const getAuthHeaders = () => {
  const token = localStorage.getItem("token");
  if (!token) throw new Error("Utilisateur non connecté");
  return { headers: { Authorization: `Bearer ${token}` } };
};

// === TOUTES LES ROUTES REQUIÈRENT AUTHENTIFICATION ===

// Récupérer les stats du prestataire
export const getProviderStats = async () => {
  const response = await axios.get(
    `${API_URL}/provider/stats`,
    getAuthHeaders()
  );
  return response.data;
};

export const createService = async (serviceData) => {
  try {
    const response = await axios.post(
      `${API_URL}/provider/services`,
      serviceData,
      getAuthHeaders()
    );
    return response.data;
  } catch (error) {
    console.error(
      "Erreur lors de la création du service :",
      error.response?.data || error.message
    );
    throw error;
  }
};

// Mettre à jour un service existant
export const updateService = async (serviceId, serviceData) => {
  try {
    const response = await axios.put(
      `${API_URL}/provider/services/${serviceId}`,
      serviceData,
      getAuthHeaders()
    );
    return response.data;
  } catch (error) {
    console.error(
      "Erreur lors de la mise à jour du service :",
      error.response?.data || error.message
    );
    throw error;
  }
};

export const getProviderDashboard = async (providerId) => {
  const token = localStorage.getItem("token");
  if (!token) throw new Error("Utilisateur non connecté");

  const response = await axios.get(
    `${API_URL}/provider/${providerId}/dashboard`,
    getAuthHeaders()
  );
  return response.data;
};

// // Récupérer les services du prestataire
export const getProviderServices = async (providerId) => {
  const token = localStorage.getItem("token");
  if (!token) throw new Error("Utilisateur non connecté");

  const response = await axios.get(
    `${API_URL}/provider/${providerId}/services`,
    getAuthHeaders()
  );
  return response.data;
};

// // Récupérer un prestataire par son ID
// export const getProviderById = async (id) => {
//   const response = await axios.get(`${API_URL}/users/${id}`, getAuthHeaders());
//   return response.data;
// };

// // Récupérer les avis d’un prestataire
// export const getProviderReviews = async (prestataireId) => {
//   const response = await axios.get(
//     `${API_URL}/avis/${prestataireId}`,
//     getAuthHeaders()
//   );
//   return response.data;
// };

// Envoyer un avis à un prestataire
export const submitReview = async (prestataireId, data) => {
  const response = await axios.post(
    `${API_URL}/avis/${prestataireId}`,
    data,
    getAuthHeaders()
  );
  return response.data;
};

// Récupérer toutes les professions
export const getProfessions = async () => {
  const response = await axios.get(`${API_URL}/professions`);
  return response.data;
};

export const getAllProvidersForClient = async () => {
  const token = localStorage.getItem("token");
  const res = await axios.get(`${API_URL}/providers`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  return res.data;
};

export const toggleFavorite = async (providerId) => {
  try {
    const res = await axios.post(
      `${API_URL}/favorite/${providerId}`,
      {}, // corps vide
      getAuthHeaders() // headers avec token
    );
    return res.data; // { favorited: true/false }
  } catch (err) {
    console.error("Erreur favoris:", err.response?.data || err.message);
    throw err;
  }
};

export const getFavorites = async () => {
  try {
    const res = await axios.get(`${API_URL}/favorites`, getAuthHeaders());
    return res.data;
  } catch (err) {
    console.error(
      "Erreur récupération favoris:",
      err.response?.data || err.message
    );
    throw err;
  }
};

export const getMyReservations = async () => {
  try {
    const res = await axios.get(
      `${API_URL}/client/my-reservations`,
      getAuthHeaders()
    );
    return res.data;
  } catch (err) {
    console.error("Erreur historique client:", err);
    return { reservations: [] };
  }
};

export const submitReservation = async (providerId, data) => {
  const token = localStorage.getItem("token");
  return axios.post(`${API_URL}/reservations/${providerId}`, data, {
    headers: { Authorization: `Bearer ${token}` },
  });
};
export const getReservationForProvider = async (providerId) => {
  try {
    const response = await axios.get(
      ` ${API_URL}/reservations/provider/${providerId}`,
      getAuthHeaders()
    );
    // Retourne la réservation ou null si aucune
    return response.data.reservation || null;
  } catch (error) {
    console.error("Erreur lors de la récupération de la réservation :", error);
    return null;
  }
};

export const getClientReservationsForProvider = async (
  clientId,
  providerId
) => {
  try {
    const res = await axios.get(
      ` ${API_URL}/client-reservations/${providerId}`,
      getAuthHeaders()
    );
    return res.data; // liste des réservations
  } catch (err) {
    console.error("Erreur récupération historique :", err);
    return [];
  }
};

// Récupérer toutes les réservations d'un prestataire
export const getProviderReservations = async () => {
  try {
    const response = await axios.get(
      `${API_URL}/provider/reservations`,
      getAuthHeaders()
    );
    return response.data.reservations || [];
  } catch (error) {
    console.error("Erreur lors de la récupération des réservations :", error);
    return [];
  }
};

// Mettre à jour le statut d'une réservation
export const updateReservationStatus = async (reservationId, status) => {
  try {
    const response = await axios.patch(
      `${API_URL}/provider/reservations/${reservationId}`,
      { status },
      getAuthHeaders()
    );
    return response.data;
  } catch (error) {
    console.error("Erreur lors de la mise à jour du statut :", error);
    throw error;
  }
};

// Récupérer les messages d'une réservation pour le chat
export const getReservationMessages = async (reservationId) => {
  try {
    const response = await axios.get(
      `${API_URL}/reservations/${reservationId}/messages`,
      getAuthHeaders()
    );
    return response.data.messages || [];
  } catch (error) {
    console.error("Erreur récupération messages :", error);
    return [];
  }
};

// Envoyer un message pour une réservation
export const sendReservationMessage = async (reservationId, message) => {
  try {
    const response = await axios.post(
      `${API_URL}/reservations/${reservationId}/messages`,
      { message },
      getAuthHeaders()
    );
    return response.data.message;
  } catch (error) {
    console.error("Erreur envoi message :", error);
    throw error;
  }
};
