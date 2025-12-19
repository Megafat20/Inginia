import React from "react";
import { Link, useLocation } from "react-router-dom";
import {
  FaUserCircle,
  FaShieldAlt,
  FaCog,
  FaBell,
  FaSignOutAlt,
  FaChartLine,
  FaQuestionCircle,
  FaChevronRight,
  FaHome,
} from "react-icons/fa";
import { useAuth } from "../Context/AuthContext";

const Sidebar = ({ isExpanded, onToggle }) => {
  const { user, logoutUser } = useAuth();
  const location = useLocation();

  const menuItems = [
    { path: "/", icon: <FaHome />, label: "Accueil" },
    {
      path: "/parametres/profile",
      icon: <FaUserCircle />,
      label: "Mon Profil",
    },
    { path: "/parametres/security", icon: <FaShieldAlt />, label: "Sécurité" },
    { path: "/parametres/preferences", icon: <FaCog />, label: "Préférences" },
    {
      path: "/parametres/notifications",
      icon: <FaBell />,
      label: "Notifications",
    },
    { path: "/stats", icon: <FaChartLine />, label: "Analytiques" },
    { path: "/help", icon: <FaQuestionCircle />, label: "Aide & Support" },
  ];

  return (
    <aside
      className={`fixed left-0 top-0 h-full bg-white border-r border-slate-100 z-[70] transition-all duration-500 ease-in-out flex flex-col pt-20 ${
        isExpanded ? "w-72" : "w-20"
      }`}
    >
      {/* Toggle Button - Floating on the right edge */}
      <button
        onClick={onToggle}
        className="absolute -right-3 top-24 bg-blue-600 text-white w-6 h-6 rounded-full flex items-center justify-center shadow-lg hover:bg-blue-700 transition-all z-10"
      >
        <FaChevronRight
          className={`text-[10px] transition-transform duration-500 ${
            isExpanded ? "rotate-180" : ""
          }`}
        />
      </button>

      {/* User Mini Profile (Collapsed vs Expanded) */}
      <div
        className={`px-4 py-6 transition-all duration-500 ${
          isExpanded ? "mb-4" : "mb-8"
        }`}
      >
        <div
          className={`flex items-center gap-4 bg-slate-50 border border-slate-100/50 rounded-2xl transition-all duration-500 overflow-hidden ${
            isExpanded ? "p-4" : "p-2 justify-center"
          }`}
        >
          <div className="w-10 h-10 min-w-[40px] rounded-xl bg-blue-600 flex items-center justify-center text-white font-bold text-lg shadow-lg shadow-blue-100">
            {user?.name?.charAt(0) || user?.email?.charAt(0).toUpperCase()}
          </div>
          {isExpanded && (
            <div className="flex-1 min-w-0 animate-fadeIn">
              <p className="text-sm font-black text-slate-800 truncate">
                {user?.name || "Utilisateur"}
              </p>
              <p className="text-[10px] text-slate-500 font-bold uppercase tracking-tighter truncate">
                {user?.role}
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 overflow-x-hidden overflow-y-auto px-3 space-y-2 scrollbar-hide">
        {menuItems.map((item) => (
          <Link
            key={item.path}
            to={item.path}
            className={`flex items-center gap-4 py-3.5 rounded-xl transition-all duration-300 group relative ${
              location.pathname === item.path
                ? "bg-blue-600 text-white shadow-lg shadow-blue-200"
                : "text-slate-500 hover:bg-blue-50 hover:text-blue-600"
            } ${isExpanded ? "px-4" : "justify-center"}`}
          >
            <span
              className={`text-xl transition-all duration-300 ${
                location.pathname === item.path
                  ? "text-white"
                  : "text-blue-500 group-hover:scale-110"
              }`}
            >
              {item.icon}
            </span>

            {isExpanded && (
              <span className="font-bold text-sm whitespace-nowrap animate-fadeIn">
                {item.label}
              </span>
            )}

            {/* Tooltip for collapsed mode */}
            {!isExpanded && (
              <div className="absolute left-full ml-4 px-3 py-1 bg-slate-800 text-white text-xs rounded-lg opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity whitespace-nowrap z-50">
                {item.label}
              </div>
            )}

            {location.pathname === item.path && isExpanded && (
              <div className="ml-auto w-1.5 h-1.5 rounded-full bg-white animate-pulse"></div>
            )}
          </Link>
        ))}
      </nav>

      {/* Footer / Logout */}
      <div className="p-4 border-t border-slate-50 space-y-4">
        <button
          onClick={logoutUser}
          className={`w-full flex items-center gap-4 py-3.5 rounded-xl bg-rose-50 text-rose-600 font-black text-xs uppercase tracking-widest hover:bg-rose-100 transition-all group overflow-hidden ${
            isExpanded ? "px-6" : "justify-center"
          }`}
        >
          <FaSignOutAlt className="text-lg group-hover:rotate-12 transition-transform" />
          {isExpanded && <span className="animate-fadeIn">Déconnexion</span>}
        </button>

        {isExpanded && (
          <div className="flex flex-col items-center gap-1 animate-fadeIn">
            <span className="text-[10px] text-slate-300 font-black tracking-widest uppercase">
              INGINIA PLATFORM
            </span>
            <span className="text-[10px] text-slate-400 font-bold">
              V 2.5.0
            </span>
          </div>
        )}
      </div>
    </aside>
  );
};

export default Sidebar;
