import React, { createContext, useState, useEffect, useContext } from "react";
import { getUser, logout as logoutService } from "../services/AuthService";

export const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true); // 🔹 état loading

  useEffect(() => {
    const init = async () => {
      try {
        const res = await getUser();
        setUser(res.data);
      } catch {
        setUser(null);
      } finally {
        setLoading(false); // 🔹 on termine le chargement
      }
    };
    init();
  }, []);

  const loginUser = (userData) => {
    localStorage.setItem("token", userData.token); // stocke le token
    setUser(userData.user || userData); 
  };

  const logoutUser = async () => {
    await logoutService();
    localStorage.removeItem("token");
    setUser(null);
  };

  // Context/AuthContext.jsx
  const updateUser = async (updatedData) => {
    try {
      const formData = new FormData();
      for (const key in updatedData) {
        if (updatedData[key]) formData.append(key, updatedData[key]);
      }
  
      const res = await fetch(`/api/users/${user._id}`, {
        method: "PUT",
        body: formData, // pas de Content-Type, FormData le gère
      });
  
      if (!res.ok) throw new Error("Erreur lors de la mise à jour du profil");
  
      const data = await res.json();
      setUser(data);
    } catch (err) {
      console.error(err);
      throw err;
    }
  };
  


  return (
    <AuthContext.Provider value={{ user, loginUser, logoutUser, loading }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
