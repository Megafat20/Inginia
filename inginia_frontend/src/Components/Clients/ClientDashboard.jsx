import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../Context/AuthContext";
import axios from "axios";
import {
  getAllProvidersForClient,
  toggleFavorite,
  getMyReservations,
} from "../services/ProviderService";
import { formatXOF } from "../../utils/formatters";
import {
  FaCheckCircle,
  FaHeart,
  FaRegHeart,
  FaSearch,
  FaStar,
  FaMapMarkerAlt,
  FaArrowRight,
  FaCalendarAlt,
  FaClipboardList,
  FaCommentDots,
  FaTimesCircle,
  FaSatelliteDish,
} from "react-icons/fa";
import SOSButton from "../SOSButton";
import TrackingMap from "./TrackingMap";
import ChatModal from "../Providers/ProviderProfileSections/ChatModal";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";

const ClientDashboard = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [providers, setProviders] = useState([]);
  const [reservations, setReservations] = useState([]);
  const [professions, setProfessions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadingRes, setLoadingRes] = useState(false);

  // UI States
  const [activeTab, setActiveTab] = useState("home"); // home | reservations
  const [search, setSearch] = useState("");
  const [activeCategory, setActiveCategory] = useState("all");
  const [showFavoritesOnly, setShowFavoritesOnly] = useState(false);
  const [sortOption, setSortOption] = useState("rating_desc");
  const [trackingResId, setTrackingResId] = useState(null);
  const [activeChatRes, setActiveChatRes] = useState(null);

  useEffect(() => {
    fetchProviders();
    fetchProfessions();
    fetchReservations();
  }, []);

  const fetchProviders = async () => {
    try {
      setLoading(true);
      const data = await getAllProvidersForClient();
      setProviders(data);
    } catch (err) {
      console.error("Erreur fetch providers:", err);
    } finally {
      setLoading(false);
    }
  };

  const fetchProfessions = async () => {
    try {
      const res = await axios.get("http://localhost:8000/api/professions");
      setProfessions(res.data.data || res.data || []);
    } catch (e) {
      console.error("Erreur categs", e);
    }
  };

  const fetchReservations = async () => {
    try {
      setLoadingRes(true);
      const data = await getMyReservations();
      setReservations(data.reservations || []);
    } catch (e) {
      console.error("Erreur reservations", e);
    } finally {
      setLoadingRes(false);
    }
  };

  const handleFavoriteToggle = async (e, providerId) => {
    e.stopPropagation();
    try {
      const data = await toggleFavorite(providerId);
      setProviders((prev) =>
        prev.map((p) =>
          p.id === providerId ? { ...p, favorited: data.favorited } : p
        )
      );
    } catch (err) {
      console.error("Erreur favoris:", err);
    }
  };

  // --- FILTER LOGIC ---
  const filteredProviders = providers
    .filter((p) => {
      const nameMatch = p.name?.toLowerCase().includes(search.toLowerCase());
      const professionMatch = p.professions?.some((t) =>
        t.name?.toLowerCase().includes(search.toLowerCase())
      );
      const categoryMatch =
        activeCategory === "all"
          ? true
          : p.professions?.some(
              (prof) =>
                prof.id === activeCategory || prof.name === activeCategory
            );

      return (nameMatch || professionMatch) && categoryMatch;
    })
    .filter((p) => !showFavoritesOnly || p.favorited)
    .sort((a, b) => {
      if (sortOption === "price_asc")
        return (a.min_price || 0) - (b.min_price || 0);
      if (sortOption === "price_desc")
        return (b.min_price || 0) - (a.min_price || 0);
      return (b.rating || 0) - (a.rating || 0);
    });

  return (
    <div className="min-h-screen bg-[#F8FAFC] font-sans text-slate-900 pb-20 relative overflow-hidden">
      {/* Dynamic Background Blobs */}
      <div className="absolute top-[-10%] right-[-10%] w-[500px] h-[500px] bg-blue-100/50 rounded-full blur-[120px] pointer-events-none"></div>
      <div className="absolute bottom-[20%] left-[-10%] w-[400px] h-[400px] bg-indigo-100/40 rounded-full blur-[100px] pointer-events-none"></div>

      {/* --- HERO SECTION --- */}
      {activeTab === "home" && (
        <div className="relative h-[480px] flex flex-col items-center justify-center text-center px-4 overflow-hidden rounded-b-[4rem] shadow-2xl">
          <div className="absolute inset-0 bg-[#0F172A]">
            <img
              src="https://images.unsplash.com/photo-1621905235294-7500bed49da7?q=80&w=2000&auto=format&fit=crop"
              className="w-full h-full object-cover opacity-30 mix-blend-overlay scale-110 animate-slowZoom"
              alt="Hero Background"
            />
            <div className="absolute inset-0 bg-gradient-to-b from-blue-600/20 via-slate-900/80 to-slate-900"></div>
          </div>

          <div className="relative z-10 w-full max-w-full mx-auto space-y-8 px-4">
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-blue-500/10 backdrop-blur-md border border-white/10 rounded-full text-blue-300 text-sm font-bold tracking-wider uppercase animate-fadeIn">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-blue-500"></span>
              </span>
              Services disponibles 24/7
            </div>

            <h1 className="text-5xl md:text-7xl font-black text-white tracking-tight leading-[1.1] animate-slideUp">
              L'expertise pro <br />
              <span className="bg-gradient-to-r from-blue-400 to-indigo-300 bg-clip-text text-transparent">
                au bout des doigts.
              </span>
            </h1>

            <div className="bg-white/10 backdrop-blur-xl p-2 rounded-3xl border border-white/20 shadow-2xl flex flex-col md:flex-row items-center gap-2 max-w-3xl mx-auto animate-fadeIn delay-300">
              <div className="flex-1 flex items-center px-6 w-full h-14">
                <FaSearch className="text-blue-400 mr-4 text-xl" />
                <input
                  type="text"
                  placeholder="De quoi avez-vous besoin ? (Électricien, Coach...)"
                  className="w-full h-full bg-transparent focus:outline-none text-white font-medium placeholder-slate-400"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                />
              </div>
              <button className="bg-blue-600 hover:bg-blue-500 hover:scale-105 active:scale-95 text-white rounded-2xl px-10 py-4 font-black transition-all w-full md:w-auto shadow-[0_0_20px_rgba(37,99,235,0.4)]">
                Trouver un Pro
              </button>
            </div>
          </div>
        </div>
      )}

      {/* --- FLOATING NAVIGATION --- */}
      <div className="max-w-7xl mx-auto px-4 -mt-8 relative z-20">
        <div className="bg-white p-2 rounded-[2rem] shadow-xl border border-slate-100 flex justify-center gap-2 w-fit mx-auto">
          <button
            onClick={() => setActiveTab("home")}
            className={`flex items-center gap-3 px-8 py-4 rounded-3xl font-black transition-all duration-500 ${
              activeTab === "home"
                ? "bg-slate-900 text-white shadow-lg"
                : "text-slate-500 hover:bg-slate-50"
            }`}
          >
            <FaSearch className={activeTab === "home" ? "text-blue-400" : ""} />{" "}
            Explorer
          </button>
          <button
            onClick={() => setActiveTab("reservations")}
            className={`flex items-center gap-3 px-8 py-4 rounded-3xl font-black transition-all duration-500 ${
              activeTab === "reservations"
                ? "bg-slate-900 text-white shadow-lg"
                : "text-slate-500 hover:bg-slate-50"
            }`}
          >
            <FaClipboardList
              className={activeTab === "reservations" ? "text-blue-400" : ""}
            />{" "}
            Mes Missions
          </button>
        </div>
      </div>

      {/* --- CONTENT : HOME --- */}
      {activeTab === "home" && (
        <div className="max-w-7xl mx-auto px-4 mt-16 animate-fadeIn">
          {/* Enhanced Filters */}
          <div className="mb-12 space-y-8">
            <div className="flex flex-col md:flex-row justify-between items-end gap-6">
              <div className="w-full md:w-2/3">
                <h2 className="text-2xl font-black text-slate-900 mb-6 flex items-center gap-3">
                  <div className="w-2 h-8 bg-blue-600 rounded-full"></div>
                  Catégories populaires
                </h2>
                <div className="flex gap-3 overflow-x-auto pb-4 scrollbar-hide mask-fade-right">
                  <button
                    onClick={() => setActiveCategory("all")}
                    className={`whitespace-nowrap px-6 py-3 rounded-2xl font-bold transition-all border-2 ${
                      activeCategory === "all"
                        ? "bg-blue-600 border-blue-600 text-white shadow-lg shadow-blue-200"
                        : "bg-white border-slate-100 text-slate-500 hover:border-slate-300"
                    }`}
                  >
                    Tout voir
                  </button>
                  {professions.map((cat) => (
                    <button
                      key={cat.id}
                      onClick={() => setActiveCategory(cat.id)}
                      className={`whitespace-nowrap px-6 py-3 rounded-2xl font-bold transition-all border-2 ${
                        activeCategory === cat.id
                          ? "bg-blue-600 border-blue-600 text-white shadow-lg shadow-blue-200"
                          : "bg-white border-slate-100 text-slate-500 hover:border-slate-300"
                      }`}
                    >
                      {cat.name}
                    </button>
                  ))}
                </div>
              </div>

              <div className="flex items-center gap-3 w-full md:w-auto">
                <div className="relative group">
                  <select
                    value={sortOption}
                    onChange={(e) => setSortOption(e.target.value)}
                    className="appearance-none bg-white border-2 border-slate-100 text-slate-700 text-sm rounded-2xl px-6 py-3.5 pr-12 font-bold cursor-pointer hover:border-blue-400 transition-all focus:ring-4 focus:ring-blue-100"
                  >
                    <option value="rating_desc">⭐ Mieux notés</option>
                    <option value="price_asc">💰 Moins chers</option>
                    <option value="price_desc">💎 Haut de gamme</option>
                  </select>
                  <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-slate-400">
                    <FaArrowRight className="rotate-90 text-xs" />
                  </div>
                </div>

                <button
                  onClick={() => setShowFavoritesOnly(!showFavoritesOnly)}
                  className={`p-3.5 rounded-2xl border-2 transition-all duration-300 ${
                    showFavoritesOnly
                      ? "bg-rose-50 border-rose-200 text-rose-500 shadow-lg shadow-rose-100 scale-110"
                      : "bg-white border-slate-100 text-slate-400 hover:text-rose-500 hover:border-rose-100"
                  }`}
                >
                  {showFavoritesOnly ? (
                    <FaHeart className="text-xl" />
                  ) : (
                    <FaRegHeart className="text-xl" />
                  )}
                </button>
              </div>
            </div>
          </div>

          {/* Grid Layout */}
          {loading ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-10">
              {[...Array(8)].map((_, i) => (
                <div
                  key={i}
                  className="bg-white rounded-[2rem] p-4 shadow-sm border border-slate-50"
                >
                  <Skeleton height={220} borderRadius={24} className="mb-4" />
                  <Skeleton width="60%" height={24} className="mb-2" />
                  <Skeleton width="40%" height={16} />
                </div>
              ))}
            </div>
          ) : filteredProviders.length === 0 ? (
            <div className="text-center py-32 bg-white rounded-[3rem] border-4 border-dashed border-slate-50">
              <div className="w-24 h-24 bg-slate-50 rounded-full flex items-center justify-center mx-auto mb-6 text-4xl">
                🔎
              </div>
              <h3 className="text-2xl font-black text-slate-800 mb-2">
                Aucun résultat trouvé
              </h3>
              <p className="text-slate-400 font-medium">
                Réessayez avec d'autres mots-clés ou filtres.
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-10 animate-slideUp">
              {filteredProviders.map((p) => (
                <div
                  key={p.id}
                  onClick={() => navigate(`/provider/${p.id}`)}
                  className="group bg-white rounded-[2rem] cursor-pointer hover:shadow-[0_20px_50px_rgba(15,23,42,0.1)] transition-all duration-500 border border-slate-100 overflow-hidden relative"
                >
                  <div className="relative h-64 bg-slate-100 overflow-hidden">
                    <img
                      src={
                        p.photo
                          ? `http://localhost:8000/storage/profile_photos/${p.photo}`
                          : "https://via.placeholder.com/600x800"
                      }
                      alt={p.name}
                      className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-slate-900/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>

                    {/* Floating Info */}
                    <div className="absolute top-4 right-4 flex flex-col gap-2">
                      <button
                        onClick={(e) => handleFavoriteToggle(e, p.id)}
                        className={`backdrop-blur-md p-3 rounded-2xl shadow-lg transition-all active:scale-90 ${
                          p.favorited
                            ? "bg-rose-500 text-white"
                            : "bg-white/80 text-slate-400 hover:bg-white hover:text-rose-500"
                        }`}
                      >
                        {p.favorited ? <FaHeart /> : <FaRegHeart />}
                      </button>
                    </div>

                    {p.verified && (
                      <div className="absolute bottom-4 left-4 bg-white/95 backdrop-blur px-4 py-2 rounded-xl text-[10px] font-black text-blue-600 flex items-center gap-2 shadow-xl tracking-widest uppercase">
                        <FaCheckCircle className="text-blue-500" /> Profil
                        Vérifié
                      </div>
                    )}
                  </div>

                  <div className="p-6 relative">
                    <div className="flex justify-between items-start mb-4">
                      <div>
                        <h3 className="font-black text-xl text-slate-900 mb-1 leading-tight group-hover:text-blue-600 transition-colors">
                          {p.name}
                        </h3>
                        <p className="text-slate-400 text-sm font-bold flex items-center gap-1.5">
                          <FaMapMarkerAlt className="text-blue-500" />{" "}
                          {p.location || "Localisation non spécifiée"}
                        </p>
                      </div>
                      <div className="bg-amber-50 text-amber-600 px-3 py-1.5 rounded-xl flex items-center gap-1.5 text-sm font-black shadow-sm shadow-amber-100">
                        <FaStar className="text-amber-400" />
                        <span>{p.rating || "5.0"}</span>
                      </div>
                    </div>

                    <div className="flex flex-wrap gap-2 mb-6">
                      {p.professions?.slice(0, 2).map((prof, i) => (
                        <span
                          key={i}
                          className="text-[10px] uppercase tracking-wider font-black bg-slate-50 text-slate-500 px-3 py-1.5 rounded-lg border border-slate-100"
                        >
                          {prof.name}
                        </span>
                      ))}
                    </div>

                    <div className="pt-5 border-t border-slate-50 flex justify-between items-center">
                      <div className="flex flex-col">
                        <span className="text-[10px] text-slate-400 uppercase font-black tracking-widest mb-0.5">
                          Tarif de base
                        </span>
                        <p className="font-black text-2xl text-slate-900">
                          {p.min_price ? formatXOF(p.min_price) : "Contact"}
                        </p>
                      </div>
                      <div className="w-12 h-12 bg-slate-900 text-white rounded-2xl flex items-center justify-center transform transition-all duration-500 group-hover:bg-blue-600 group-hover:rotate-[360deg] shadow-lg">
                        <FaArrowRight />
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* --- CONTENT : RESERVATIONS --- */}
      {activeTab === "reservations" && (
        <div className="max-w-4xl mx-auto px-4 mt-16 animate-fadeIn pb-20">
          <div className="flex items-center gap-4 mb-10">
            <div className="w-12 h-12 bg-blue-600 rounded-2xl flex items-center justify-center shadow-lg shadow-blue-200">
              <FaClipboardList className="text-white text-xl" />
            </div>
            <div>
              <h2 className="text-4xl font-black text-slate-900">
                Suivi des missions
              </h2>
              <p className="text-slate-500 font-bold">
                Consultez l'historique et le statut de vos demandes
              </p>
            </div>
          </div>

          {loadingRes ? (
            <div className="space-y-6">
              {[...Array(4)].map((_, i) => (
                <div
                  key={i}
                  className="bg-white p-6 rounded-[2rem] border border-slate-50 shadow-sm flex gap-6"
                >
                  <Skeleton width={80} height={80} borderRadius={20} />
                  <div className="flex-1">
                    <Skeleton width="40%" height={24} className="mb-2" />
                    <Skeleton width="60%" height={16} />
                  </div>
                </div>
              ))}
            </div>
          ) : reservations.length === 0 ? (
            <div className="text-center py-32 bg-white rounded-[3rem] border-4 border-dashed border-slate-50">
              <div className="w-24 h-24 bg-blue-50 rounded-full flex items-center justify-center mx-auto mb-6 text-4xl">
                📋
              </div>
              <h3 className="text-2xl font-black text-slate-800 mb-2">
                Aucune mission trouvée
              </h3>
              <p className="text-slate-400 font-medium mb-8">
                Commencez par trouver un expert pour vos travaux.
              </p>
              <button
                onClick={() => setActiveTab("home")}
                className="bg-slate-900 text-white px-10 py-4 rounded-2xl font-black hover:bg-blue-600 transition-all shadow-xl"
              >
                Explorer les profils
              </button>
            </div>
          ) : (
            <div className="space-y-6">
              {reservations.map((r) => (
                <div
                  key={r.id}
                  className="bg-white rounded-[2.5rem] shadow-sm border border-slate-100 p-8 flex flex-col md:flex-row items-center gap-8 hover:shadow-[0_20px_40px_rgba(15,23,42,0.05)] transition-all group"
                >
                  <div className="relative flex-shrink-0">
                    <img
                      src={
                        r.provider?.photo
                          ? `http://localhost:8000/storage/profile_photos/${r.provider.photo}`
                          : "https://via.placeholder.com/150"
                      }
                      alt="Pro"
                      className="w-24 h-24 rounded-[1.8rem] object-cover border-[3px] border-slate-50 shadow-inner group-hover:scale-105 transition-transform"
                    />
                    <div className="absolute -bottom-2 -right-2 w-8 h-8 bg-white rounded-full flex items-center justify-center shadow-md">
                      <div
                        className={`w-3.5 h-3.5 rounded-full ${
                          r.status === "accepted"
                            ? "bg-green-500 animate-pulse"
                            : r.status === "pending"
                            ? "bg-amber-500"
                            : "bg-slate-300"
                        }`}
                      ></div>
                    </div>
                  </div>

                  <div className="flex-1 text-center md:text-left">
                    <div className="flex flex-col md:flex-row md:items-center gap-3 mb-2">
                      <h3 className="font-black text-2xl text-slate-900 leading-tight">
                        {r.provider?.name || "Expert"}
                      </h3>
                      <span
                        className={`w-fit mx-auto md:mx-0 px-4 py-1.5 rounded-full text-[10px] font-black uppercase tracking-widest ${
                          r.status === "pending"
                            ? "bg-amber-100 text-amber-700"
                            : r.status === "completed"
                            ? "bg-green-100 text-green-700"
                            : r.status === "accepted"
                            ? "bg-blue-100 text-blue-700"
                            : "bg-slate-100 text-slate-600"
                        }`}
                      >
                        {r.status === "pending"
                          ? "En attente"
                          : r.status === "accepted"
                          ? "En cours"
                          : r.status === "completed"
                          ? "Terminée"
                          : "Refusée"}
                      </span>
                    </div>

                    <p className="text-slate-500 font-bold mb-4 flex items-center justify-center md:justify-start gap-2">
                      <span className="w-1.5 h-1.5 bg-blue-600 rounded-full"></span>
                      {r.competance?.title ||
                        r.other_service ||
                        "Prestation standard"}
                    </p>

                    <div className="flex flex-wrap justify-center md:justify-start gap-3 mt-3">
                      <div className="flex items-center gap-2 px-4 py-2 bg-slate-50 rounded-xl text-slate-600 text-xs font-bold">
                        <FaCalendarAlt className="text-blue-500" />
                        {new Date(r.requested_date).toLocaleDateString(
                          "fr-FR",
                          { day: "numeric", month: "long" }
                        )}
                      </div>
                    </div>
                  </div>

                  <div className="flex flex-col gap-3 min-w-[200px]">
                    {r.status === "accepted" && (
                      <button
                        onClick={() => setTrackingResId(r.id)}
                        className="bg-blue-600 text-white hover:bg-blue-700 px-6 py-4 rounded-2xl font-black transition-all flex items-center justify-center gap-3 shadow-lg shadow-blue-100 group/btn"
                      >
                        <FaSatelliteDish className="group-hover/btn:rotate-12 transition-transform" />{" "}
                        SUIVRE
                      </button>
                    )}
                    <button
                      onClick={() => setActiveChatRes(r)}
                      className="bg-slate-900 text-white hover:bg-slate-800 px-6 py-4 rounded-2xl font-black transition-all flex items-center justify-center gap-3 shadow-xl group/chat"
                    >
                      <FaCommentDots className="group-hover/chat:scale-110 transition-transform" />{" "}
                      Chat
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* --- CHAT MODAL --- */}
      {activeChatRes && (
        <ChatModal
          provider={activeChatRes.provider}
          reservation={activeChatRes}
          user={user}
          closeModal={() => setActiveChatRes(null)}
        />
      )}

      {/* --- TRACKING MODAL --- */}
      {trackingResId && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/60 backdrop-blur-md p-4 animate-fadeIn">
          <div className="bg-white w-full max-w-4xl rounded-[3rem] shadow-2xl h-[600px] flex flex-col overflow-hidden animate-bounceIn border border-white/20">
            <div className="p-8 bg-slate-50 border-b border-slate-100 flex justify-between items-center">
              <div>
                <h3 className="font-black text-2xl text-slate-900 flex items-center gap-3">
                  <div className="relative flex h-3 w-3">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                    <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
                  </div>
                  Suivi Temps Réel
                </h3>
                <p className="text-slate-400 font-bold text-sm">
                  Votre expert est en route vers votre position
                </p>
              </div>
              <button
                onClick={() => setTrackingResId(null)}
                className="w-12 h-12 bg-white rounded-2xl flex items-center justify-center text-slate-400 hover:text-rose-500 transition-all shadow-sm border border-slate-100 hover:rotate-90"
              >
                <FaTimesCircle className="text-2xl" />
              </button>
            </div>
            <div className="flex-1 relative">
              <TrackingMap reservationId={trackingResId} />
            </div>
          </div>
        </div>
      )}

      <SOSButton />

      <style>{`
        @keyframes slowZoom {
          from { transform: scale(1); }
          to { transform: scale(1.15); }
        }
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes slideUp { from { opacity: 0; transform: translateY(30px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes bounceIn { 
          0% { transform: scale(0.9); opacity: 0; } 
          70% { transform: scale(1.02); opacity: 1; } 
          100% { transform: scale(1); } 
        }
        .animate-slowZoom { animation: slowZoom 30s infinite alternate ease-in-out; }
        .animate-fadeIn { animation: fadeIn 0.8s ease-out; }
        .animate-slideUp { animation: slideUp 0.8s ease-out; }
        .animate-bounceIn { animation: bounceIn 0.6s cubic-bezier(0.34, 1.56, 0.64, 1); }
        .delay-300 { animation-delay: 300ms; fill-mode: backwards; }
        .scrollbar-hide::-webkit-scrollbar { display: none; }
        .mask-fade-right { -webkit-mask-image: linear-gradient(to right, black 85%, transparent 100%); mask-image: linear-gradient(to right, black 85%, transparent 100%); }
      `}</style>
    </div>
  );
};

export default ClientDashboard;
