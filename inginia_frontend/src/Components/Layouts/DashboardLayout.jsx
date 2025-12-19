import React, { useState } from "react";
import { Outlet, useNavigate } from "react-router-dom";
import Navbar from "../Navbar";
import Sidebar from "./Sidebar"; // la sidebar "drawer"
import { useAuth } from "../Context/AuthContext";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

import SOSListener from "../SOSListener";
import NotificationListener from "../NotificationListener";

const DashboardLayout = () => {
  const [isSidebarExpanded, setIsSidebarExpanded] = useState(false);
  const { user } = useAuth();
  const navigate = useNavigate();

  const toggleSidebar = () => {
    if (!user) {
      toast.info("Connectez-vous pour accéder à plus de fonctionnalités", {
        position: "top-right",
        autoClose: 3000,
      });
      navigate("/login", { state: { from: "dashboard" } });
      return;
    }
    setIsSidebarExpanded((prev) => !prev);
  };

  return (
    <div className="flex flex-col min-h-screen bg-slate-50/50 overflow-x-hidden">
      <SOSListener />
      <NotificationListener />
      <ToastContainer />

      {/* Navbar (Fixée en haut) */}
      <Navbar onLogoClick={toggleSidebar} toggleSidebar={toggleSidebar} />

      <div className="flex flex-1 pt-20">
        {/* Sidebar persistante et repliable */}
        {user && (
          <Sidebar
            isExpanded={isSidebarExpanded}
            onToggle={() => setIsSidebarExpanded(!isSidebarExpanded)}
          />
        )}

        {/* Contenu principal occupant toute la largeur */}
        <main
          className={`flex-1 transition-all duration-500 ease-in-out ${
            user ? (isSidebarExpanded ? "pl-72" : "pl-20") : ""
          }`}
        >
          {/* Decorative background elements */}
          <div className="fixed top-0 right-0 -z-10 w-1/2 h-1/2 bg-gradient-to-br from-blue-50/20 to-transparent blur-3xl pointer-events-none"></div>
          <div className="fixed bottom-0 left-0 -z-10 w-1/2 h-1/2 bg-gradient-to-tr from-indigo-50/20 to-transparent blur-3xl pointer-events-none"></div>

          <div className="w-full min-h-full p-4 md:p-8 animate-fadeIn">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
};

export default DashboardLayout;
