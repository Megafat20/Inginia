import React, { useEffect, useState, useContext } from "react";
import { fetchUsers, deleteUser } from "./services/UserService";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { AuthContext } from "./Context/AuthContext";
import {
  FaUserPlus,
  FaSignOutAlt,
  FaUserShield,
  FaUsers,
  FaUserEdit,
  FaTrashAlt,
  FaSearch,
  FaFilter,
  FaEllipsisV,
} from "react-icons/fa";

const AdminDashboard = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { logoutUser } = useContext(AuthContext);
  const [users, setUsers] = useState([]);
  const [filter, setFilter] = useState("");

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    try {
      const res = await fetchUsers();
      setUsers(res.data);
    } catch (err) {
      console.error("Erreur lors du chargement", err);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm(t("confirm_delete"))) {
      try {
        await deleteUser(id);
        loadUsers();
      } catch (err) {
        console.error("Erreur suppression", err);
      }
    }
  };

  const filteredUsers = users.filter(
    (u) =>
      u.name?.toLowerCase().includes(filter.toLowerCase()) ||
      u.email?.toLowerCase().includes(filter.toLowerCase())
  );

  return (
    <div className="w-full space-y-8 animate-fadeIn">
      {/* Upper Section / Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-3xl border border-slate-100 shadow-sm flex items-center gap-6">
          <div className="w-16 h-16 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center text-2xl shadow-inner">
            <FaUsers />
          </div>
          <div>
            <p className="text-xs font-black text-slate-400 uppercase tracking-widest mb-1">
              Total Utilisateurs
            </p>
            <h4 className="text-3xl font-black text-slate-900">
              {users.length}
            </h4>
          </div>
        </div>
        <div className="bg-white p-6 rounded-3xl border border-slate-100 shadow-sm flex items-center gap-6">
          <div className="w-16 h-16 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center text-2xl shadow-inner">
            <FaUserShield />
          </div>
          <div>
            <p className="text-xs font-black text-slate-400 uppercase tracking-widest mb-1">
              Administrateurs
            </p>
            <h4 className="text-3xl font-black text-slate-900">
              {users.filter((u) => u.role === "admin").length}
            </h4>
          </div>
        </div>
        <div className="bg-indigo-600 p-6 rounded-3xl shadow-xl shadow-indigo-100 flex items-center justify-between text-white">
          <div>
            <p className="text-xs font-black opacity-80 uppercase tracking-widest mb-1">
              Actions Rapides
            </p>
            <h4 className="text-xl font-bold">Nouveau Compte</h4>
          </div>
          <button
            onClick={() => navigate("/create")}
            className="w-12 h-12 rounded-2xl bg-white/20 hover:bg-white/30 backdrop-blur-md flex items-center justify-center transition-all active:scale-90"
          >
            <FaUserPlus size={20} />
          </button>
        </div>
      </div>

      {/* Control Bar */}
      <div className="flex flex-col md:flex-row items-center justify-between gap-6 bg-white p-4 rounded-[2rem] border border-slate-100 shadow-sm">
        <h2 className="text-2xl font-black text-slate-900 px-4">
          Console <span className="text-blue-600">Admin</span>
        </h2>

        <div className="flex items-center gap-4 w-full md:w-auto">
          <div className="relative flex-1 md:w-80">
            <FaSearch className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300" />
            <input
              type="text"
              placeholder="Rechercher un utilisateur..."
              className="w-full pl-12 pr-4 py-3 bg-slate-50 border-none rounded-2xl text-sm font-medium focus:ring-2 focus:ring-blue-500/20 transition-all text-slate-700"
              value={filter}
              onChange={(e) => setFilter(e.target.value)}
            />
          </div>
          <button className="p-4 bg-slate-50 text-slate-400 rounded-2xl hover:bg-slate-100 transition-colors">
            <FaFilter />
          </button>
          <button
            onClick={logoutUser}
            className="flex items-center gap-3 px-6 py-3 bg-rose-50 text-rose-600 rounded-2xl font-bold text-sm hover:bg-rose-100 transition-all active:scale-95"
          >
            <FaSignOutAlt />
            {t("logout")}
          </button>
        </div>
      </div>

      {/* Users Grid */}
      {filteredUsers.length === 0 ? (
        <div className="py-20 text-center bg-white rounded-[3rem] border-2 border-dashed border-slate-100">
          <div className="w-20 h-20 bg-slate-50 rounded-full flex items-center justify-center mx-auto mb-6 text-slate-300 text-3xl">
            <FaUsers />
          </div>
          <p className="text-slate-400 font-bold uppercase tracking-widest text-sm">
            {t("no_users_found")}
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredUsers.map((u) => (
            <div
              key={u.id}
              className="group bg-white rounded-[2.5rem] p-6 border border-slate-50 hover:border-blue-100 hover:shadow-2xl hover:shadow-blue-500/5 transition-all duration-500 relative overflow-hidden"
            >
              {/* Card Header */}
              <div className="flex items-center justify-between mb-6">
                <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-slate-100 to-slate-200 flex items-center justify-center text-slate-500 font-black text-xl">
                  {u.name?.charAt(0).toUpperCase()}
                </div>
                <div
                  className={`px-4 py-1.5 rounded-full text-[10px] font-black uppercase tracking-widest ${
                    u.role === "admin"
                      ? "bg-indigo-50 text-indigo-600"
                      : "bg-emerald-50 text-emerald-600"
                  }`}
                >
                  {u.role}
                </div>
              </div>

              {/* User Info */}
              <div className="space-y-1 mb-8">
                <h3 className="text-xl font-black text-slate-800 truncate">
                  {u.name}
                </h3>
                <p className="text-sm text-slate-400 font-medium truncate">
                  {u.email}
                </p>
              </div>

              {/* Card Actions */}
              <div className="flex gap-3 pt-6 border-t border-slate-50">
                <button
                  onClick={() => navigate(`/edit/${u.id}`)}
                  className="flex-1 flex items-center justify-center gap-2 py-3 bg-white border border-slate-100 text-slate-600 rounded-xl font-bold text-xs hover:bg-slate-50 transition-all group/btn"
                >
                  <FaUserEdit className="text-blue-500 group-hover/btn:scale-110 transition-transform" />
                  Modifier
                </button>
                <button
                  onClick={() => handleDelete(u.id)}
                  className="w-12 flex items-center justify-center bg-rose-50 text-rose-500 rounded-xl hover:bg-rose-500 hover:text-white transition-all active:scale-90"
                >
                  <FaTrashAlt size={14} />
                </button>
              </div>

              {/* Decorative detail */}
              <div className="absolute top-0 right-0 w-16 h-16 bg-gradient-to-br from-blue-500/5 to-transparent rounded-bl-[3rem] -z-10 group-hover:scale-150 transition-transform duration-700"></div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default AdminDashboard;
