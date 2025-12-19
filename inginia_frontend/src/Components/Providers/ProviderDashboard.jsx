import React, { useEffect, useState } from "react";
import axios from "axios";
import ServiceForm from "./ServiceForm";
import ChatBox from "./ProviderProfileSections/ChatBot";
import LocationBroadcaster from "./LocationBroadcaster";
import { useAuth } from "../Context/AuthContext";
import { useParams } from "react-router-dom";
import {
  getProviderDashboard,
  getProviderServices,
  updateReservationStatus,
} from "../services/ProviderService";
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer } from "recharts";
import {
  FaCheckCircle,
  FaHourglassHalf,
  FaClipboardList,
  FaStar,
  FaTimesCircle,
  FaMapMarkerAlt,
  FaEnvelope,
  FaPhone,
  FaTools,
  FaCalendarAlt,
  FaCommentDots,
  FaTrash,
  FaPen,
} from "react-icons/fa";
import Spinner from "../Common/Spinner";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";
import { MapContainer, TileLayer, Marker } from "react-leaflet";

import L from "leaflet";
import "leaflet/dist/leaflet.css";
import ReviewList from "./ProviderProfileSections/ReviewList";
import Planning from "../Planning";

// Correction des icônes par défaut de Leaflet
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: require("leaflet/dist/images/marker-icon-2x.png"),
  iconUrl: require("leaflet/dist/images/marker-icon.png"),
  shadowUrl: require("leaflet/dist/images/marker-shadow.png"),
});

const COLORS = ["#10B981", "#F59E0B", "#EF4444"]; // Green, Yellow, Red (Tailwind shades)

const ProviderDashboard = () => {
  const { id } = useParams();
  const { user, loading: authLoading } = useAuth();
  const providerId = id || user?.id;

  // States
  const [profile, setProfile] = useState({});
  const [competances, setCompetances] = useState([]);
  const [reviews, setReviews] = useState([]);
  const [reservations, setReservations] = useState([]);
  const [loadingReservations, setLoadingReservations] = useState(true);
  const [stats, setStats] = useState({
    totalServices: 0,
    totalReservations: 0,
    completed: 0,
    pending: 0,
    declined: 0,
    satisfactionRate: 0,
  });
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("dashboard");
  const [showForm, setShowForm] = useState(false);
  const [editingService, setEditingService] = useState(null);
  const [servicePage, setServicePage] = useState(1);
  const servicesPerPage = 6;
  const [openChat, setOpenChat] = useState(null);
  const [openMap, setOpenMap] = useState(null);
  const [loadingServices, setLoadingServices] = useState(true);

  // ---- FETCH DASHBOARD ----
  const fetchDashboard = async () => {
    if (!providerId) return;
    try {
      setLoading(true);
      setLoadingReservations(true);
      setLoadingServices(true);
      const data = await getProviderDashboard(providerId);
      if (!data?.provider) throw new Error("Utilisateur introuvable");

      setProfile(data.provider);
      setCompetances(data.competances);
      setReviews(data.reviews || []);
      setReservations(data.reservations || []);

      // Stats Logic
      const completed = (data.reservations || []).filter(
        (r) => r.status === "completed"
      ).length;
      const pending = (data.reservations || []).filter(
        (r) => r.status === "pending"
      ).length;
      const declined = (data.reservations || []).filter(
        (r) => r.status === "declined"
      ).length;
      const totalReservations = completed + pending + declined;
      const satisfactionRate = totalReservations
        ? Math.round((completed / totalReservations) * 100)
        : 0;

      setStats({
        totalServices: data.competances.length,
        completed,
        pending,
        declined,
        totalReservations,
        satisfactionRate,
      });
    } catch (err) {
      console.error("Erreur dashboard:", err);
    } finally {
      setLoading(false);
      setLoadingReservations(false);
      setLoadingServices(false);
    }
  };

  useEffect(() => {
    if (!authLoading) fetchDashboard();
  }, [providerId, authLoading]);

  // Auto-Start Tracking for Accepted Missions
  const [activeTrackingMission, setActiveTrackingMission] = useState(null);
  useEffect(() => {
    // Trouve la mission acceptée la plus récente
    const active = reservations
      .filter((r) => r.status === "accepted")
      .sort((a, b) => new Date(b.updated_at) - new Date(a.updated_at))[0];

    if (active) {
      console.log("📍 Mission active détectée pour tracking:", active.id);
      setActiveTrackingMission(active.id);
    } else {
      setActiveTrackingMission(null);
    }
  }, [reservations]);

  // Auto-open chat from SOS or redirection
  useEffect(() => {
    const autoOpenChatId = localStorage.getItem("open_chat_id");
    if (autoOpenChatId) {
      setOpenChat(parseInt(autoOpenChatId));
      setActiveTab("reservations");
      localStorage.removeItem("open_chat_id");
    }
  }, []);

  // Pagination Services
  const paginatedServices = competances.slice(
    (servicePage - 1) * servicesPerPage,
    servicePage * servicesPerPage
  );

  // ---- ACTIONS ----
  const fetchAllServices = async () => {
    if (!profile.id) return;
    try {
      setLoadingServices(true);
      const data = await getProviderServices(profile.id);
      setCompetances(data.competances);
      fetchDashboard();
    } catch (err) {
      console.error(err);
    } finally {
      setLoadingServices(false);
    }
  };

  const handleEdit = (service) => {
    setEditingService(service);
    setShowForm(true);
  };

  const handleDelete = async (serviceId) => {
    if (!window.confirm("Voulez-vous vraiment supprimer ce service ?")) return;
    try {
      const token = localStorage.getItem("token");
      await axios.delete(`/api/provider/services/${serviceId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      fetchAllServices();
    } catch (err) {
      console.error(err);
    }
  };

  const handleStatusChange = async (id, status) => {
    try {
      const updated = await updateReservationStatus(id, status);
      setReservations((prev) =>
        prev.map((r) => (r.id === id ? updated.reservation : r))
      );
      fetchDashboard();
    } catch (err) {
      console.error(err);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen bg-slate-50">
        <Spinner size={6} borderColor="blue-600" />
      </div>
    );
  }

  const pieData = [
    { name: "Terminés", value: stats.completed },
    { name: "En attente", value: stats.pending },
    { name: "Refusés", value: stats.declined },
  ];

  // --- UI COMPONENTS ---

  const StatCard = ({ icon: Icon, title, value, color, delay }) => (
    <div
      className={`bg-white p-6 rounded-2xl shadow-sm border border-slate-100 flex items-center gap-5 hover:shadow-lg transition-all duration-300 transform hover:-translate-y-1 animate-fadeIn delay-${delay}`}
    >
      <div
        className={`p-4 rounded-xl ${color} bg-opacity-10 text-${
          color.split("-")[1]
        }-600`}
      >
        <Icon className={`text-3xl ${color.replace("bg-", "text-")}`} />
      </div>
      <div>
        <p className="text-slate-500 font-medium text-sm uppercase tracking-wider">
          {title}
        </p>
        <h3 className="text-3xl font-extrabold text-slate-800">{value}</h3>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-[#F8FAFC] font-sans text-slate-900 pb-20 relative overflow-hidden">
      {/* Dynamic Background Blobs */}
      <div className="absolute top-[-10%] right-[-10%] w-[500px] h-[500px] bg-indigo-100/50 rounded-full blur-[120px] pointer-events-none"></div>
      <div className="absolute bottom-[20%] left-[-10%] w-[400px] h-[400px] bg-blue-100/40 rounded-full blur-[100px] pointer-events-none"></div>

      {/* --- HEADER BANNER --- */}
      <div className="relative h-[280px] flex items-center justify-center overflow-hidden">
        <div className="absolute inset-0 bg-[#0F172A]">
          <img
            src="https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?q=80&w=2000&auto=format&fit=crop"
            className="w-full h-full object-cover opacity-20 scale-110 animate-slowZoom"
            alt="Dashboard Banner"
          />
          <div className="absolute inset-0 bg-gradient-to-b from-blue-900/40 via-slate-900/80 to-[#F8FAFC]"></div>
        </div>

        <div className="relative z-10 w-full max-w-full mx-auto px-4 text-center md:text-left">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-white/10 backdrop-blur-md rounded-full text-blue-200 text-xs font-black tracking-widest uppercase mb-4 animate-fadeIn">
            <FaClipboardList className="animate-pulse" /> Espace Prestataire
          </div>
          <h1 className="text-4xl md:text-5xl font-black text-white tracking-tight animate-slideUp">
            Votre activité, <br />
            <span className="bg-gradient-to-r from-blue-400 to-indigo-300 bg-clip-text text-transparent italic">
              en un coup d'œil.
            </span>
          </h1>
        </div>
      </div>

      <div className="max-w-full mx-auto px-4 sm:px-6 lg:px-8 -mt-20 relative z-10">
        {/* PROFILE HEADER CARD */}
        <div className="bg-white/70 backdrop-blur-2xl rounded-[3rem] shadow-[0_20px_50px_rgba(15,23,42,0.08)] p-8 md:p-10 flex flex-col md:flex-row items-center md:items-center gap-10 border border-white/50 animate-bounceIn">
          <div className="relative group">
            <div className="absolute inset-0 bg-blue-500 rounded-[2.5rem] blur-xl opacity-20 group-hover:opacity-40 transition-opacity"></div>
            <img
              src={
                profile.photo
                  ? `http://localhost:8000/storage/profile_photos/${profile.photo}`
                  : "/default-profile.png"
              }
              alt="Profil"
              className="relative w-44 h-44 rounded-[2.5rem] object-cover border-4 border-white shadow-xl bg-white transition-transform group-hover:scale-105"
            />
            {profile.verified_at && (
              <div
                className="absolute -bottom-2 -right-2 bg-blue-600 text-white p-3 rounded-2xl border-4 border-white shadow-lg animate-bounce"
                title="Compte Vérifié"
              >
                <FaCheckCircle className="text-xl" />
              </div>
            )}
          </div>

          <div className="flex-1 text-center md:text-left space-y-4">
            <div>
              <h2 className="text-4xl font-black text-slate-900 leading-tight">
                {profile.name}
              </h2>
              <div className="flex flex-wrap justify-center md:justify-start gap-3 mt-3">
                {profile.professions?.map((p, i) => (
                  <span
                    key={i}
                    className="bg-white border border-slate-100 shadow-sm px-4 py-2 rounded-2xl text-xs font-black text-slate-600 uppercase tracking-wider flex items-center gap-2"
                  >
                    <div className="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>{" "}
                    {p.name}
                  </span>
                ))}
              </div>
            </div>

            <div className="flex flex-wrap justify-center md:justify-start gap-6 text-slate-500 font-bold text-sm">
              {profile.location && (
                <span className="flex items-center gap-2 bg-slate-50 px-4 py-2 rounded-xl border border-slate-100">
                  <FaMapMarkerAlt className="text-blue-500" />{" "}
                  {profile.location}
                </span>
              )}
              <span className="flex items-center gap-2 bg-slate-50 px-4 py-2 rounded-xl border border-slate-100">
                <FaStar className="text-amber-400" /> {profile.rating || "5.0"}{" "}
                (Évaluation)
              </span>
            </div>
          </div>

          <div className="bg-slate-900 text-white p-8 rounded-[2.5rem] text-center shadow-2xl relative overflow-hidden group min-w-[180px]">
            <div className="absolute top-0 right-0 w-24 h-24 bg-blue-600/20 rounded-full -mr-12 -mt-12 blur-2xl group-hover:scale-150 transition-transform"></div>
            <span className="block text-[10px] text-blue-300 uppercase font-black tracking-[0.2em] mb-2 opacity-70">
              Points Inginia
            </span>
            <div className="text-4xl font-black mb-1">1,240</div>
            <div className="text-[10px] font-bold text-green-400">
              +12% ce mois
            </div>
          </div>
        </div>

        {/* --- NAVIGATION TABS --- */}
        <div className="flex flex-wrap gap-3 mt-12 mb-10 justify-center">
          {[
            { id: "dashboard", label: "Vue d'ensemble", icon: FaClipboardList },
            { id: "reservations", label: "Mes Missions", icon: FaCalendarAlt },
            { id: "compétances", label: "Catalogue", icon: FaTools },
            { id: "planning", label: "Agenda", icon: FaHourglassHalf },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center gap-3 px-8 py-4 rounded-3xl font-black transition-all duration-500 shadow-sm ${
                activeTab === tab.id
                  ? "bg-slate-900 text-white shadow-xl shadow-slate-200 -translate-y-1"
                  : "bg-white text-slate-400 hover:text-slate-600 hover:shadow-md"
              }`}
            >
              <tab.icon
                className={activeTab === tab.id ? "text-blue-400" : ""}
              />{" "}
              {tab.label}
            </button>
          ))}
        </div>

        {/* --- CONTENT AREA --- */}
        <div className="animate-fadeIn pb-20">
          {/* 1. DASHBOARD OVERVIEW */}
          {activeTab === "dashboard" && (
            <div className="space-y-10">
              {/* STATS GRID */}
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
                <div className="bg-white p-8 rounded-[2.5rem] shadow-sm border border-slate-100 group hover:shadow-xl transition-all duration-500 border-b-4 border-b-blue-500">
                  <div className="w-14 h-14 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center text-2xl mb-6 group-hover:scale-110 transition-transform">
                    <FaTools />
                  </div>
                  <p className="text-slate-400 font-black text-[10px] uppercase tracking-widest mb-1">
                    Services
                  </p>
                  <h3 className="text-3xl font-black text-slate-900">
                    {stats.totalServices}
                  </h3>
                </div>

                <div className="bg-white p-8 rounded-[2.5rem] shadow-sm border border-slate-100 group hover:shadow-xl transition-all duration-500 border-b-4 border-b-green-500">
                  <div className="w-14 h-14 bg-green-50 text-green-600 rounded-2xl flex items-center justify-center text-2xl mb-6 group-hover:scale-110 transition-transform">
                    <FaCheckCircle />
                  </div>
                  <p className="text-slate-400 font-black text-[10px] uppercase tracking-widest mb-1">
                    Missions Finies
                  </p>
                  <h3 className="text-3xl font-black text-slate-900">
                    {stats.completed}
                  </h3>
                </div>

                <div className="bg-white p-8 rounded-[2.5rem] shadow-sm border border-slate-100 group hover:shadow-xl transition-all duration-500 border-b-4 border-b-amber-500">
                  <div className="w-14 h-14 bg-amber-50 text-amber-600 rounded-2xl flex items-center justify-center text-2xl mb-6 group-hover:scale-110 transition-transform">
                    <FaHourglassHalf />
                  </div>
                  <p className="text-slate-400 font-black text-[10px] uppercase tracking-widest mb-1">
                    En Attente
                  </p>
                  <h3 className="text-3xl font-black text-slate-900">
                    {stats.pending}
                  </h3>
                </div>

                <div className="bg-white p-8 rounded-[2.5rem] shadow-sm border border-slate-100 group hover:shadow-xl transition-all duration-500 border-b-4 border-b-purple-500">
                  <div className="w-14 h-14 bg-purple-50 text-purple-600 rounded-2xl flex items-center justify-center text-2xl mb-6 group-hover:scale-110 transition-transform">
                    <FaStar />
                  </div>
                  <p className="text-slate-400 font-black text-[10px] uppercase tracking-widest mb-1">
                    Satisfaction
                  </p>
                  <h3 className="text-3xl font-black text-slate-900">
                    {stats.satisfactionRate}%
                  </h3>
                </div>
              </div>

              <div className="grid grid-cols-1 lg:grid-cols-3 gap-10">
                {/* CHART */}
                <div className="bg-white p-10 rounded-[3rem] shadow-sm border border-slate-100 lg:col-span-1 flex flex-col items-center relative overflow-hidden">
                  <div className="absolute top-0 left-0 w-full h-2 bg-gradient-to-r from-blue-500 to-indigo-500 opacity-20"></div>
                  <h3 className="text-2xl font-black text-slate-900 mb-8 w-full text-left">
                    Répartition
                  </h3>
                  <div className="w-full h-72">
                    <ResponsiveContainer width="100%" height="100%">
                      <PieChart>
                        <Pie
                          data={pieData}
                          innerRadius={70}
                          outerRadius={100}
                          paddingAngle={8}
                          dataKey="value"
                          stroke="none"
                        >
                          {pieData.map((entry, index) => (
                            <Cell
                              key={`cell-${index}`}
                              fill={COLORS[index % COLORS.length]}
                            />
                          ))}
                        </Pie>
                        <Tooltip />
                      </PieChart>
                    </ResponsiveContainer>
                  </div>
                  <div className="flex flex-wrap gap-4 text-xs font-black uppercase tracking-wider mt-8">
                    {pieData.map((d, i) => (
                      <div
                        key={i}
                        className="flex items-center gap-2 bg-slate-50 px-4 py-2 rounded-xl"
                      >
                        <div
                          className="w-2.5 h-2.5 rounded-full"
                          style={{ backgroundColor: COLORS[i] }}
                        ></div>
                        <span className="text-slate-500">{d.name}</span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* REVIEWS SHORTLIST */}
                <div className="bg-white p-10 rounded-[3rem] shadow-sm border border-slate-100 lg:col-span-2 relative overflow-hidden">
                  <div className="absolute top-0 left-0 w-full h-2 bg-gradient-to-r from-blue-500 to-indigo-500 opacity-20"></div>
                  <div className="flex justify-between items-center mb-10">
                    <h3 className="text-2xl font-black text-slate-900">
                      Derniers Avis Clients
                    </h3>
                    <div className="w-12 h-12 bg-slate-50 rounded-2xl flex items-center justify-center text-slate-400">
                      <FaStar />
                    </div>
                  </div>
                  <ReviewList reviews={reviews.slice(0, 3)} />
                </div>
              </div>
            </div>
          )}

          {/* 2. SERVICES TAB */}
          {activeTab === "compétances" && (
            <div className="animate-slideUp">
              <div className="flex flex-col md:flex-row justify-between items-center mb-10 gap-6">
                <div>
                  <h2 className="text-3xl font-black text-slate-900 mb-2">
                    Catalogue de prestations
                  </h2>
                  <p className="text-slate-500 font-bold">
                    Gérez vos services et tarifs proposés aux clients
                  </p>
                </div>
                <button
                  onClick={() => {
                    setEditingService(null);
                    setShowForm(true);
                  }}
                  className="bg-slate-900 hover:bg-blue-600 text-white px-10 py-4 rounded-[2rem] font-black shadow-xl transition-all hover:-translate-y-1 active:scale-95"
                >
                  + Ajouter un service
                </button>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-10">
                {paginatedServices.map((s) => (
                  <div
                    key={s.id}
                    className="group bg-white rounded-[2.5rem] shadow-sm border border-slate-100 p-8 hover:shadow-[0_30px_60px_rgba(15,23,42,0.1)] transition-all duration-500 relative overflow-hidden"
                  >
                    <div className="absolute top-0 right-0 w-24 h-24 bg-blue-50 rounded-bl-[4rem] group-hover:scale-110 transition-transform"></div>

                    <div className="flex justify-between items-start mb-8 relative">
                      <div className="w-16 h-16 bg-blue-600 text-white rounded-2xl flex items-center justify-center text-2xl shadow-lg shadow-blue-100">
                        <FaTools />
                      </div>
                      <div className="text-right">
                        <p className="text-[10px] text-slate-400 font-black uppercase tracking-widest mb-1">
                          Tarif
                        </p>
                        <span className="text-xl font-black text-slate-900 bg-slate-50 px-4 py-2 rounded-xl">
                          {s.price} <span className="text-xs">FCFA</span>
                        </span>
                      </div>
                    </div>

                    <h3 className="text-xl font-black text-slate-900 mb-3 group-hover:text-blue-600 transition-colors">
                      {s.title}
                    </h3>
                    <p className="text-slate-400 font-medium text-sm mb-10 line-clamp-3 leading-relaxed">
                      {s.description}
                    </p>

                    <div className="flex gap-4 pt-6 border-t border-slate-50">
                      <button
                        onClick={() => handleEdit(s)}
                        className="flex-1 flex items-center justify-center gap-2 bg-amber-50 text-amber-600 hover:bg-amber-100 py-3 rounded-2xl text-xs font-black uppercase tracking-widest transition-all"
                      >
                        <FaPen /> Éditer
                      </button>
                      <button
                        onClick={() => handleDelete(s.id)}
                        className="flex-1 flex items-center justify-center gap-2 bg-rose-50 text-rose-600 hover:bg-rose-100 py-3 rounded-2xl text-xs font-black uppercase tracking-widest transition-all"
                      >
                        <FaTrash />
                      </button>
                    </div>
                  </div>
                ))}
              </div>

              {showForm && (
                <ServiceForm
                  service={editingService}
                  onSuccess={fetchAllServices}
                  onClose={() => setShowForm(false)}
                />
              )}
            </div>
          )}

          {/* 3. RESERVATIONS TAB */}
          {activeTab === "reservations" && (
            <div className="max-w-4xl mx-auto space-y-8 animate-slideUp">
              <div className="flex items-center gap-6 mb-12">
                <div className="w-16 h-16 bg-white rounded-3xl flex items-center justify-center shadow-xl border border-slate-50">
                  <FaCalendarAlt className="text-blue-600 text-2xl" />
                </div>
                <div>
                  <h2 className="text-3xl font-black text-slate-900">
                    Demandes de réservation
                  </h2>
                  <p className="text-slate-500 font-bold">
                    Répondez aux nouveaux clients et suivez vos missions
                  </p>
                </div>
              </div>

              <div className="space-y-6">
                {reservations.length === 0 ? (
                  <div className="p-20 text-center bg-white rounded-[3rem] border-4 border-dashed border-slate-50">
                    <div className="text-6xl mb-6 opacity-30">📭</div>
                    <p className="text-slate-400 font-black text-xl">
                      Aucune mission pour le moment
                    </p>
                  </div>
                ) : (
                  reservations.map((r) => (
                    <div
                      key={r.id}
                      className="relative bg-white rounded-[2.5rem] shadow-sm border border-slate-100 p-8 flex flex-col md:flex-row items-center gap-10 hover:shadow-[0_20px_40px_rgba(15,23,42,0.05)] transition-all group overflow-hidden"
                    >
                      <div className="absolute top-0 left-0 w-2 h-full bg-blue-600 opacity-0 group-hover:opacity-100 transition-opacity"></div>

                      <div className="relative">
                        <img
                          src={
                            r.client?.photo
                              ? `http://localhost:8000/storage/profile_photos/${r.client.photo}`
                              : "/default-profile.png"
                          }
                          alt="Client"
                          className="w-24 h-24 rounded-[2rem] object-cover border-[3px] border-white shadow-xl bg-slate-50"
                        />
                        <div
                          className={`absolute -bottom-1 -right-1 w-6 h-6 rounded-full border-4 border-white ${
                            r.status === "accepted"
                              ? "bg-green-500"
                              : r.status === "pending"
                              ? "bg-amber-500"
                              : "bg-slate-300"
                          }`}
                        ></div>
                      </div>

                      <div className="flex-1 text-center md:text-left space-y-3">
                        <div className="flex flex-col md:flex-row md:items-center gap-4">
                          <h4 className="font-black text-2xl text-slate-900 group-hover:text-blue-600 transition-colors">
                            {r.client?.name}
                          </h4>
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
                            {r.status}
                          </span>
                        </div>

                        <div className="flex flex-wrap justify-center md:justify-start gap-4">
                          <p className="text-slate-500 font-bold bg-slate-50 px-4 py-1.5 rounded-xl border border-slate-100 text-sm">
                            <span className="text-[10px] text-slate-400 uppercase tracking-widest mr-2">
                              Service
                            </span>
                            {r.competance?.title || r.other_service}
                          </p>
                          <p className="text-slate-500 font-bold bg-slate-50 px-4 py-1.5 rounded-xl border border-slate-100 text-sm">
                            <FaCalendarAlt className="inline mr-2 text-blue-500" />
                            {new Date(r.requested_date).toLocaleDateString()}
                          </p>
                        </div>
                      </div>

                      <div className="flex flex-col gap-3 min-w-[180px]">
                        <button
                          onClick={() => setOpenChat(r.id)}
                          className="bg-slate-900 text-white hover:bg-blue-600 px-6 py-3.5 rounded-2xl font-black text-xs uppercase tracking-widest transition-all shadow-xl flex items-center justify-center gap-2 group/btn"
                        >
                          <FaCommentDots className="group-hover/btn:scale-125 transition-transform" />{" "}
                          Chat
                        </button>

                        {r.status === "accepted" && (
                          <button
                            onClick={() => setOpenMap(r.id)}
                            className="bg-blue-50 text-blue-600 hover:bg-blue-100 px-6 py-3.5 rounded-2xl font-black text-xs uppercase tracking-widest transition-all shadow-sm flex items-center justify-center gap-2"
                          >
                            <FaMapMarkerAlt /> GPS Client
                          </button>
                        )}

                        {r.status === "pending" && (
                          <div className="grid grid-cols-2 gap-2">
                            <button
                              onClick={() =>
                                handleStatusChange(r.id, "accepted")
                              }
                              className="bg-green-600 text-white hover:bg-green-700 p-3 rounded-2xl shadow-lg transition-all animate-pulse"
                            >
                              <FaCheckCircle className="mx-auto text-xl" />
                            </button>
                            <button
                              onClick={() =>
                                handleStatusChange(r.id, "declined")
                              }
                              className="bg-rose-50 text-rose-500 hover:bg-rose-100 p-3 rounded-2xl transition-all"
                            >
                              <FaTimesCircle className="mx-auto text-xl" />
                            </button>
                          </div>
                        )}

                        {r.status === "accepted" && (
                          <button
                            onClick={() =>
                              handleStatusChange(r.id, "completed")
                            }
                            className="bg-green-500 text-white hover:bg-green-600 px-6 py-3.5 rounded-2xl font-black text-xs uppercase tracking-widest transition-all shadow-xl"
                          >
                            Terminer Mission
                          </button>
                        )}
                      </div>

                      {/* MODALS remain similar but styled */}
                      {openChat === r.id && (
                        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/60 backdrop-blur-md p-4 animate-fadeIn">
                          <div className="bg-white w-full max-w-lg rounded-[2.5rem] shadow-2xl h-[650px] flex flex-col overflow-hidden animate-bounceIn">
                            <div className="p-8 bg-slate-50 border-b flex justify-between items-center">
                              <h3 className="text-xl font-black text-slate-800">
                                Chat avec {r.client?.name}
                              </h3>
                              <button
                                onClick={() => setOpenChat(null)}
                                className="w-10 h-10 bg-white rounded-xl flex items-center justify-center text-slate-400 hover:text-rose-500 transition-all border border-slate-100"
                              >
                                <FaTimesCircle className="text-xl" />
                              </button>
                            </div>
                            <div className="flex-1 overflow-hidden relative">
                              <ChatBox reservationId={r.id} />
                            </div>
                          </div>
                        </div>
                      )}

                      {openMap === r.id && (
                        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/60 backdrop-blur-md p-4 animate-fadeIn">
                          <div className="bg-white w-full max-w-3xl rounded-[2.5rem] shadow-2xl overflow-hidden animate-bounceIn border border-white/20">
                            <div className="p-8 bg-slate-50 border-b flex justify-between items-center">
                              <div>
                                <h3 className="text-xl font-black text-slate-800">
                                  Localisation du Client
                                </h3>
                                <p className="text-xs font-bold text-slate-400">
                                  Position relevée lors de la demande
                                </p>
                              </div>
                              <button
                                onClick={() => setOpenMap(null)}
                                className="w-10 h-10 bg-white rounded-xl flex items-center justify-center text-slate-400 hover:text-rose-500 transition-all border border-slate-100"
                              >
                                <FaTimesCircle className="text-xl" />
                              </button>
                            </div>
                            <div className="h-[450px] w-full">
                              <MapContainer
                                center={[r.client_lat || 0, r.client_lng || 0]}
                                zoom={13}
                                className="h-full w-full"
                              >
                                <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
                                <Marker
                                  position={[
                                    r.client_lat || 0,
                                    r.client_lng || 0,
                                  ]}
                                />
                              </MapContainer>
                            </div>
                          </div>
                        </div>
                      )}
                    </div>
                  ))
                )}
              </div>
            </div>
          )}

          {/* 4. PLANNING TAB */}
          {activeTab === "planning" && (
            <div className="bg-white p-10 rounded-[3rem] shadow-sm border border-slate-100 animate-slideUp">
              <Planning />
            </div>
          )}
        </div>
      </div>

      <LocationBroadcaster
        reservationId={activeTrackingMission || openChat}
        isTracking={!!activeTrackingMission || !!openChat}
      />

      <style>{`
        @keyframes slowZoom { from { transform: scale(1); } to { transform: scale(1.15); } }
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
      `}</style>
    </div>
  );
};

export default ProviderDashboard;
