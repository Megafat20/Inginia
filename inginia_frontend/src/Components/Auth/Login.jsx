import React, { useState } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { login } from "../services/AuthService";
import { useAuth } from "../Context/AuthContext";
import { GoogleLogin } from "@react-oauth/google";
// import jwt_decode from "jwt-decode";

const Login = () => {
  const { loginUser } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");

  const handleLogin = async (e) => {
    e.preventDefault();
    try {
      const data = await login({ email, password });
      if (data.token) localStorage.setItem("token", data.token);
      loginUser(data);

      // Redirection selon rôle
      if (data.user.role === "admin") navigate("/admin");
      else if (data.user.role === "prestataire") navigate("/providerdashboard");
      else if (data.user.role === "client") navigate("/clientdashboard");
      else navigate("/");
    } catch (err) {
      setError("Login failed. Check your credentials.");
    }
  };

  // const handleGoogleSignIn = async (credentialResponse) => {
  //   try {
  //     const decoded = jwt_decode(credentialResponse.credential);
  //     const userData = {
  //       nom: decoded.given_name || "",
  //       prenom: decoded.family_name || "",
  //       email: decoded.email,
  //       profile_photo: decoded.picture,
  //       google: true,
  //     };
  //     const res = await loginUser(userData, true); // backend doit gérer Google login
  //     localStorage.setItem("token", res.token);
  //     navigate("/dashboard");
  //   } catch (err) {
  //     setError("Connexion Google échouée");
  //   }
  // };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 via-white to-indigo-100 p-6">
      <div className="bg-white shadow-2xl rounded-3xl w-full max-w-6xl flex overflow-hidden relative">
        {/* Côté gauche */}
        <div className="hidden md:flex w-2/6 bg-indigo-600 flex-col justify-center items-center p-10 text-white">
          <img
            src="/images/inginia_logo.png"
            alt="Inginia Logo"
            className="w-32 mb-6"
          />
          <h2 className="text-3xl font-bold mb-4 text-center">
            Bienvenue sur Inginia
          </h2>
          
          <GoogleLogin
            onSuccess={async (credentialResponse) => {
          

              try {
                const res = await fetch(
                  "http://localhost:8000/api/auth/google",
                  {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                      credential: credentialResponse.credential,
                    }),
                  }
                );
                const data = await res.json();

                if (data.token) {
                  localStorage.setItem("token", data.token);
                  loginUser(data);

                  if (data.user.role === "admin") navigate("/admin");
                  else if (data.user.role === "prestataire")
                    navigate("/providerdashboard");
                  else navigate("/clientdashboard");
                } else {
                  setError("Erreur de connexion Google");
                }
              } catch (err) {
                console.error(err);
                setError("Erreur lors de la connexion avec Google");
              }
            }}
            onError={() => setError("Échec de la connexion Google")}
          />

          <p className="text-md mb-6 text-center">
            Connectez clients et prestataires facilement et rapidement.
          </p>
        </div>

        {/* Côté droit formulaire */}
        <div className="w-full md:w-4/6 p-10 relative flex flex-col items-center">
          {/* Toast / Message info */}
          {location.state?.from && (
            <div className="absolute top-4 left-1/2 transform -translate-x-1/2 bg-indigo-500 text-white px-4 py-2 rounded-xl shadow-lg text-center z-10">
              Connectez-vous pour accéder à plus de fonctionnalités
            </div>
          )}

          <h2 className="text-4xl font-extrabold text-center text-indigo-700 mb-4">
            Connexion
          </h2>
          <p className="text-center text-gray-500 mb-8">
            Connectez-vous pour accéder à votre compte 🚀
          </p>

          {error && (
            <div className="bg-red-100 text-red-700 p-3 rounded-xl mb-6 text-center font-medium w-full">
              {error}
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-6 w-full">
            <div>
              <label className="block text-gray-700 font-medium mb-1">
                Email
              </label>
              <input
                type="email"
                placeholder="Email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full border border-gray-300 rounded-lg p-3 text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 shadow-sm"
                required
              />
            </div>
            <div>
              <label className="block text-gray-700 font-medium mb-1">
                Mot de passe
              </label>
              <input
                type="password"
                placeholder="Mot de passe"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full border border-gray-300 rounded-lg p-3 text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 shadow-sm"
                required
              />
            </div>
            <button
              type="submit"
              className="w-full bg-indigo-600 text-white py-3 rounded-xl font-semibold text-lg shadow-lg hover:bg-indigo-700 transition transform hover:scale-[1.02]"
            >
              Connexion
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default Login;
