import React, { useEffect, useState } from "react";
import axios from "../../axios";
import { useNavigate } from "react-router-dom";
import {
  FaUsers,
  FaUserCheck,
  FaUserClock,
  FaBuilding,
  FaChartLine,
  FaCheckCircle,
  FaClipboardList,
} from "react-icons/fa";

const AdminDashboardNew = () => {
  const navigate = useNavigate();
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      const response = await axios.get("/admin/dashboard/stats");
      setStats(response.data);
    } catch (error) {
      console.error("Erreur chargement stats:", error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  const statCards = [
    {
      title: "Total Utilisateurs",
      value: stats?.total_users || 0,
      icon: FaUsers,
      color: "blue",
      bgGradient: "from-blue-500 to-blue-600",
    },
    {
      title: "Clients",
      value: stats?.total_clients || 0,
      icon: FaUsers,
      color: "green",
      bgGradient: "from-green-500 to-emerald-600",
    },
    {
      title: "Prestataires Validés",
      value: stats?.validated_providers || 0,
      icon: FaUserCheck,
      color: "purple",
      bgGradient: "from-purple-500 to-purple-600",
    },
    {
      title: "En Attente de Validation",
      value: stats?.pending_providers || 0,
      icon: FaUserClock,
      color: "orange",
      bgGradient: "from-orange-500 to-red-500",
      clickable: true,
      route: "/admin/providers/validation",
    },
    {
      title: "Total Prestataires",
      value: stats?.total_providers || 0,
      icon: FaChartLine,
      color: "indigo",
      bgGradient: "from-indigo-500 to-indigo-600",
    },
    {
      title: "Agences",
      value: stats?.total_agencies || 0,
      icon: FaBuilding,
      color: "pink",
      bgGradient: "from-pink-500 to-rose-600",
    },
  ];

  const quickActions = [
    {
      title: "Validation Prestataires",
      description: `${stats?.pending_providers || 0} demande(s) en attente`,
      icon: FaCheckCircle,
      color: "orange",
      route: "/admin/providers/validation",
      highlight: stats?.pending_providers > 0,
    },
    {
      title: "Suivi Temps Réel",
      description: "Voir les missions en cours",
      icon: FaClipboardList,
      color: "emerald",
      route: "/admin/tracking",
    },
    {
      title: "Gestion Utilisateurs",
      description: "Voir tous les utilisateurs",
      icon: FaUsers,
      color: "blue",
      route: "/admin/users",
    },
  ];

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 rounded-3xl p-8 text-white">
        <h1 className="text-4xl font-black mb-2">Tableau de Bord Admin</h1>
        <p className="text-blue-100 text-lg">
          Bienvenue sur votre panneau d'administration
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {statCards.map((stat, index) => (
          <div
            key={index}
            onClick={() => stat.clickable && navigate(stat.route)}
            className={`bg-white rounded-2xl p-6 border border-slate-100 shadow-sm hover:shadow-xl transition-all duration-300 ${
              stat.clickable ? "cursor-pointer transform hover:scale-105" : ""
            }`}
          >
            <div className="flex items-start justify-between mb-4">
              <div
                className={`w-14 h-14 rounded-xl bg-gradient-to-br ${stat.bgGradient} flex items-center justify-center text-white shadow-lg`}
              >
                <stat.icon className="text-2xl" />
              </div>
              {stat.clickable && stats?.pending_providers > 0 && (
                <span className="px-3 py-1 bg-red-500 text-white rounded-full text-xs font-bold animate-pulse">
                  Nouveau !
                </span>
              )}
            </div>
            <div>
              <p className="text-sm font-bold text-slate-500 uppercase tracking-wider mb-1">
                {stat.title}
              </p>
              <p className="text-4xl font-black text-slate-900">{stat.value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Actions */}
      <div>
        <h2 className="text-2xl font-black text-slate-900 mb-6">
          Actions Rapides
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {quickActions.map((action, index) => (
            <div
              key={index}
              onClick={() => navigate(action.route)}
              className={`bg-white rounded-2xl p-6 border-2 ${
                action.highlight
                  ? "border-orange-500 bg-orange-50"
                  : "border-slate-100"
              } hover:shadow-xl transition-all duration-300 cursor-pointer group`}
            >
              <div
                className={`w-12 h-12 rounded-xl bg-${action.color}-100 text-${action.color}-600 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform`}
              >
                <action.icon className="text-xl" />
              </div>
              <h3 className="text-lg font-bold text-slate-900 mb-2">
                {action.title}
              </h3>
              <p className="text-sm text-slate-600">{action.description}</p>
              {action.highlight && (
                <div className="mt-4 px-4 py-2 bg-orange-500 text-white rounded-lg text-sm font-bold text-center">
                  Attention requise !
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Recent Activity Placeholder */}
      <div className="bg-white rounded-2xl p-8 border border-slate-100">
        <h2 className="text-2xl font-black text-slate-900 mb-6">
          Activité Récente
        </h2>
        <div className="text-center py-12 text-slate-500">
          <FaClipboardList className="text-5xl mx-auto mb-4 opacity-20" />
          <p className="font-medium">
            Les activités récentes s'afficheront ici
          </p>
        </div>
      </div>
    </div>
  );
};

export default AdminDashboardNew;
