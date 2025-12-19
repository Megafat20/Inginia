import React, { useState, useEffect } from "react";
import { Link, useNavigate, useLocation } from "react-router-dom";
import {
  FaBars,
  FaBell,
  FaUserCircle,
  FaSignOutAlt,
  FaChevronDown,
} from "react-icons/fa";
import { useAuth } from "./Context/AuthContext";
import Logo from "./Logo";

const Navbar = ({ onLogoClick, toggleSidebar }) => {
  const { user, logoutUser, loading } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [isScrolled, setIsScrolled] = useState(false);
  const [showDropdown, setShowDropdown] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  if (loading) return null;

  const handleLogout = () => {
    logoutUser();
    navigate("/login");
  };

  const navLinks = [
    { name: "Accueil", path: "/" },
    ...(user?.role === "admin" ? [{ name: "Admin", path: "/admin" }] : []),
    ...(user?.role === "prestataire"
      ? [{ name: "Dashboard", path: "/providerdashboard" }]
      : []),
    ...(user?.role === "client"
      ? [{ name: "Exploration", path: "/clientdashboard" }]
      : []),
  ];

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-[60] transition-all duration-300 border-b border-slate-200 py-3 bg-white/95 backdrop-blur-xl shadow-sm`}
    >
      <div className="max-w-full mx-auto px-6 flex justify-between items-center">
        {/* Logo + Hamburger */}
        <div className="flex items-center gap-6">
          <button
            className="p-2 rounded-xl transition-all hover:bg-slate-100 md:hidden text-slate-800"
            onClick={onLogoClick}
          >
            <FaBars size={22} />
          </button>

          <div className="scale-110">
            <Logo toggleSidebar={toggleSidebar} />
          </div>
        </div>

        {/* Liens principaux (desktop) */}
        <div className="hidden md:flex items-center space-x-1">
          {navLinks.map((link) => (
            <Link
              key={link.path}
              to={link.path}
              className={`px-4 py-2 rounded-full font-semibold transition-all duration-300 ${
                location.pathname === link.path
                  ? "bg-blue-600 text-white shadow-md shadow-blue-200 scale-105"
                  : "text-slate-600 hover:text-blue-600 hover:bg-blue-50"
              }`}
            >
              {link.name}
            </Link>
          ))}
        </div>

        {/* Auth & Actions */}
        <div className="flex items-center gap-4">
          {!user ? (
            <div className="flex items-center gap-3">
              <Link
                to="/login"
                className="px-5 py-2 rounded-full text-sm font-bold transition-all text-slate-700 hover:bg-slate-100"
              >
                Connexion
              </Link>
              <Link
                to="/register"
                className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-full text-sm font-bold shadow-lg shadow-blue-200 hover:scale-[1.02] active:scale-95 transition-all"
              >
                Rejoindre
              </Link>
            </div>
          ) : (
            <div className="flex items-center gap-3 relative">
              {/* Notification Badge */}
              <button className="p-2.5 rounded-full transition-all relative group bg-slate-100 text-slate-600">
                <FaBell size={18} />
                <span className="absolute top-0 right-0 w-3 h-3 bg-rose-500 border-2 border-white rounded-full animate-pulse"></span>
              </button>

              {/* User Toggle */}
              <button
                onClick={() => setShowDropdown(!showDropdown)}
                className="flex items-center gap-2 p-1.5 pl-3 rounded-full border transition-all hover:shadow-md active:scale-95 bg-white border-slate-200 text-slate-700"
              >
                <div className="w-8 h-8 rounded-full bg-blue-600 text-white flex items-center justify-center font-bold text-sm">
                  {user.name?.charAt(0) || "U"}
                </div>
                <FaChevronDown
                  size={12}
                  className={`transition-transform duration-300 ${
                    showDropdown ? "rotate-180" : ""
                  }`}
                />
              </button>

              {/* Dropdown Menu */}
              {showDropdown && (
                <>
                  <div
                    className="fixed inset-0 z-40"
                    onClick={() => setShowDropdown(false)}
                  ></div>
                  <div className="absolute top-full right-0 mt-3 w-56 bg-white rounded-2xl shadow-2xl border border-slate-100 py-2 z-50 animate-bounceIn">
                    <div className="px-4 py-3 border-b border-slate-50 mb-1">
                      <p className="text-xs text-slate-400 font-bold uppercase tracking-tighter">
                        Connecté avec
                      </p>
                      <p className="text-sm font-bold text-slate-800 truncate">
                        {user.email}
                      </p>
                    </div>

                    <button
                      onClick={() => {
                        setShowDropdown(false);
                        toggleSidebar();
                      }}
                      className="w-full flex items-center gap-3 px-4 py-2.5 text-slate-600 hover:bg-slate-50 transition-colors text-sm"
                    >
                      <FaUserCircle className="text-blue-500" /> Mon Espace
                    </button>

                    <button
                      onClick={handleLogout}
                      className="w-full flex items-center gap-3 px-4 py-2.5 text-rose-500 hover:bg-rose-50 transition-colors text-sm font-semibold"
                    >
                      <FaSignOutAlt /> Déconnexion
                    </button>
                  </div>
                </>
              )}
            </div>
          )}
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
