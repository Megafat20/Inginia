import axios from "axios";

const API_URL = "http://localhost:8000/api";

export const login = async ({ email, password }) => {
  const response = await axios.post(
    `${API_URL}/login`,
    { email, password },
    { headers: { "Content-Type": "application/json" } }
  );
  
  if (response.data.token) {
    localStorage.setItem("token", response.data.token);
  }
  return response.data;
};


export const register = async (formData) => {
  // 1. On crée l'utilisateur
  await axios.post(`${API_URL}/register`, formData, {
    headers: { "Content-Type": "multipart/form-data" },
  });

  // 2. On récupère email et password depuis formData pour login
  const email = formData.get("email");
  const password = formData.get("password");

  const loginResponse = await axios.post(
    `${API_URL}/login`,
    { email, password },
    { headers: { "Content-Type": "application/json" } }
  );

  // 3. On stocke le token
  if (loginResponse.data.token) {
    localStorage.setItem("token", loginResponse.data.token);
  }

  return loginResponse.data; // renvoie user + token
};

export const getUser = async () => {
  const token = localStorage.getItem("token");
  return axios.get(`${API_URL}/me`, {  // pas /user
    headers: { Authorization: `Bearer ${token}` },
  });
};

export const logout = async () => {
  const token = localStorage.getItem("token");
  return axios.post(`${API_URL}/logout`, {}, {
    headers: { Authorization: `Bearer ${token}` },
  });
};


