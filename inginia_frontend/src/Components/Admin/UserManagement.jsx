import React, { useEffect, useState } from "react";
import axios from "../../axios";
import {
  FaUser,
  FaEnvelope,
  FaPhone,
  FaMapMarkerAlt,
  FaTools,
  FaBuilding,
  FaCalendarAlt,
  FaSearch,
  FaFilter,
  FaUsers,
} from "react-icons/fa";

const UserManagement = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [filterRole, setFilterRole] = useState("all"); // 'all', 'client', 'prestataire'

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    try {
      setLoading(true);
      const response = await axios.get("/admin/users");
      setUsers(response.data);
    } catch (error) {
      console.error("Erreur chargement utilisateurs:", error);
    } finally {
      setLoading(false);
    }
  };

  const filteredUsers = users.filter((user) => {
    const matchesSearch =
      user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (user.phone && user.phone.includes(searchTerm));

    const matchesRole =
      filterRole === "all" ||
      (filterRole === "prestataire" && user.role === "prestataire") ||
      (filterRole === "client" &&
        user.role !== "prestataire" &&
        user.role !== "admin");

    return matchesSearch && matchesRole;
  });

  const UserCard = ({ user }) => (
    <div className="bg-white rounded-2xl p-6 border border-slate-100 hover:shadow-lg transition-all duration-300">
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-4">
          {user.profile_photo ? (
            <img
              src={user.profile_photo}
              alt={user.name}
              className="w-16 h-16 rounded-xl object-cover"
            />
          ) : (
            <div className="w-16 h-16 rounded-xl bg-gradient-to-br from-slate-200 to-slate-300 flex items-center justify-center text-slate-500 text-2xl font-bold">
              {user.name?.charAt(0) || <FaUser />}
            </div>
          )}
          <div>
            <h3 className="text-lg font-bold text-slate-900">{user.name}</h3>
            <div className="flex items-center gap-2">
              {user.role === "prestataire" ? (
                <span
                  className={`px-2 py-0.5 rounded text-xs font-bold ${
                    user.is_validated
                      ? "bg-green-100 text-green-700"
                      : "bg-orange-100 text-orange-700"
                  }`}
                >
                  {user.is_agency ? "AGENCE" : "PRESTATAIRE"}{" "}
                  {user.is_validated ? "VALIDÉ" : "(EN ATTENTE)"}
                </span>
              ) : (
                <span className="px-2 py-0.5 bg-blue-100 text-blue-700 rounded text-xs font-bold">
                  CLIENT
                </span>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="space-y-3 text-sm text-slate-600">
        {user.service && (
          <div className="flex items-center gap-2 text-purple-600 font-semibold">
            <FaTools /> {user.service}
          </div>
        )}
        <div className="flex items-center gap-3">
          <FaEnvelope className="text-slate-400" />
          <span className="truncate">{user.email}</span>
        </div>
        {user.phone && (
          <div className="flex items-center gap-3">
            <FaPhone className="text-slate-400" />
            <span>{user.phone}</span>
          </div>
        )}
        {user.location && (
          <div className="flex items-center gap-3">
            <FaMapMarkerAlt className="text-slate-400" />
            <span>{user.location}</span>
          </div>
        )}
        <div className="flex items-center gap-3 pt-3 border-t border-slate-50">
          <FaCalendarAlt className="text-slate-400" />
          <span>
            Inscrit le {new Date(user.created_at).toLocaleDateString()}
          </span>
        </div>
      </div>
    </div>
  );

  return (
    <div className="space-y-6">
      <div className="bg-gradient-to-r from-slate-800 to-slate-900 rounded-3xl p-8 text-white relative overflow-hidden">
        <div className="relative z-10">
          <h1 className="text-3xl font-black mb-2">Gestion des Utilisateurs</h1>
          <p className="text-slate-300">
            Consultez et gérez la base d'utilisateurs de la plateforme.
          </p>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-2xl p-4 border border-slate-100 flex flex-col md:flex-row gap-4 justify-between items-center shadow-sm">
        <div className="relative w-full md:w-96">
          <FaSearch className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Rechercher par nom, email, téléphone..."
            className="w-full pl-12 pr-4 py-3 bg-slate-50 border-none rounded-xl focus:ring-2 focus:ring-blue-500 transition-all font-medium"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        <div className="flex gap-2 w-full md:w-auto">
          <button
            onClick={() => setFilterRole("all")}
            className={`px-4 py-2 rounded-xl font-bold transition-all ${
              filterRole === "all"
                ? "bg-slate-800 text-white"
                : "bg-slate-100 text-slate-600 hover:bg-slate-200"
            }`}
          >
            Tous
          </button>
          <button
            onClick={() => setFilterRole("client")}
            className={`px-4 py-2 rounded-xl font-bold transition-all ${
              filterRole === "client"
                ? "bg-blue-500 text-white"
                : "bg-blue-50 text-blue-600 hover:bg-blue-100"
            }`}
          >
            Clients
          </button>
          <button
            onClick={() => setFilterRole("prestataire")}
            className={`px-4 py-2 rounded-xl font-bold transition-all ${
              filterRole === "prestataire"
                ? "bg-purple-500 text-white"
                : "bg-purple-50 text-purple-600 hover:bg-purple-100"
            }`}
          >
            Prestataires
          </button>
        </div>
      </div>

      {loading ? (
        <div className="flex justify-center py-20">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-slate-800"></div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {filteredUsers.length > 0 ? (
            filteredUsers.map((user) => <UserCard key={user.id} user={user} />)
          ) : (
            <div className="col-span-full py-20 text-center text-slate-500">
              <FaUsers className="mx-auto text-5xl mb-4 opacity-20" />
              <p className="text-xl font-bold">Aucun utilisateur trouvé</p>
              <p>Essayez de modifier votre recherche</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default UserManagement;
