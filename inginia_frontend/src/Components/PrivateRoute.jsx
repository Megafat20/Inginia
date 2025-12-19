import React from "react";
import { Navigate, useLocation } from "react-router-dom";
import { useAuth } from "./Context/AuthContext";
import { toast } from "react-toastify"; // si tu utilises react-toastify

const PrivateRoute = ({ children, role }) => {
  const { user } = useAuth();
  const location = useLocation();

  if (!user) {
    toast.info("Connectez-vous pour accéder à cette page");
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (role && user.role !== role) {
    toast.error("Vous n'avez pas la permission d'accéder à cette page");
    return <Navigate to="/" replace />;
  }

  return children;
};

export default PrivateRoute;
