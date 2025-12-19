import axios from "axios";

const API_URL = "http://localhost:8000/api"; // adapte selon ton backend

// === FONCTION UTILITAIRE POUR RÉCUPÉRER LE TOKEN ===
const getAuthHeaders = () => {
  const token = localStorage.getItem("token");
  return token
    ? { headers: { Authorization: `Bearer ${token}` } }
    : {}; // pas de headers → appel public
};

/* -------------------- ROUTES PUBLIQUES -------------------- */

// Prestataires populaires
export const getPopularProviders = async () => {
  try {
    const response = await axios.get(`${API_URL}/providers/popular`);
    return response.data; // tableau des prestataires
  } catch (err) {
    console.error("❌ Erreur récupération prestataires :", err);
    return [];
  }
};

// Catégories
export const getPopularCategories = async () => {
  try {
    const response = await axios.get(`${API_URL}/categories`);
    return response.data.map((c) => ({
      id: c.id,
      name: c.name,
      icon: c.icon || "🛠",
      total: c.prestataires_count,
    }));
  } catch (err) {
    console.error("❌ Erreur récupération catégories :", err);
    return [];
  }
};

// Recherche (publique)
export const getSearchResults = async (query) => {
  try {
    const res = await axios.get(
      `${API_URL}/search?query=${encodeURIComponent(query)}`
    );
    return res.data.providers || [];
  } catch (error) {
    console.error("❌ Erreur recherche :", error);
    return [];
  }
};

// Voir les avis d’un prestataire (publique)
export const getPrestataireAvis = async (prestataireId) => {
  try {
    const res = await axios.get(`${API_URL}/avis/${prestataireId}`);
    return res.data || [];
  } catch (error) {
    console.error("❌ Erreur récupération avis :", error);
    return [];
  }
};

// Voir les services d’un prestataire (publique)
export const getServicesByProvider = async (providerId) => {
  try {
    const res = await axios.get(`${API_URL}/provider/${providerId}/services`);
    return res.data || [];
  } catch (error) {
    console.error("❌ Erreur récupération services :", error);
    return [];
  }
};

/* -------------------- ROUTES PROTÉGÉES -------------------- */

// Filtrage par catégorie (si backend protège)
export const handleCategoryClick = async (categoryId) => {
  try {
    const res = await axios.get(
      `${API_URL}/providers/category/${categoryId}`,
      getAuthHeaders()
    );
    return res.data;
  } catch (err) {
    console.error(
      "❌ Erreur filtrage par catégorie :",
      err.response?.data || err.message
    );
    return { error: true, providers: [] };
  }
};

// Recommandations sans besoin spécifique
export const recommands = async (userLatitude, userLongitude) => {
  try {
    const res = await axios.post(
      `${API_URL}/prestataires/recommandes`,
      { latitude: userLatitude, longitude: userLongitude },
      getAuthHeaders()
    );
    return res.data || [];
  } catch (error) {
    console.error("❌ Erreur recommandations :", error);
    return [];
  }
};

// Recommandations avec besoin spécifique
export const recommands2 = async (userLatitude, userLongitude, besoin) => {
  try {
    const res = await axios.post(
      `${API_URL}/prestataires/recommandes`,
      { latitude: userLatitude, longitude: userLongitude, besoin },
      getAuthHeaders()
    );
    return res.data || [];
  } catch (error) {
    console.error("❌ Erreur recommandations :", error);
    return [];
  }
};

