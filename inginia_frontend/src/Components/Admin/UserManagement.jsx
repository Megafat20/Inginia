import React, { useEffect, useState } from "react";
import axios from "../../axios";
import {
  FaUser,
  FaEnvelope,
  FaPhone,
  FaSearch,
  FaFilter,
  FaUsers,
  FaTrashAlt,
  FaUserEdit,
  FaBan,
  FaCheckCircle,
  FaEllipsisV,
  FaSortAmountDown,
  FaSortAmountUp,
  FaDownload,
} from "react-icons/fa";
import { toast } from "react-toastify";
import { useNavigate } from "react-router-dom";

const UserManagement = () => {
  const navigate = useNavigate();
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [filterRole, setFilterRole] = useState("all");
  const [filterStatus, setFilterStatus] = useState("all"); // all, active, inactive
  const [sortBy, setSortBy] = useState("created_at");
  const [sortOrder, setSortOrder] = useState("desc");
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(10);

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    try {
      setLoading(true);
      const response = await axios.get("/admin/users");
      setUsers(response.data);
    } catch (error) {
      toast.error("Erreur chargement utilisateurs");
    } finally {
      setLoading(false);
    }
  };

  const toggleStatus = async (id) => {
    try {
      const res = await axios.patch(`/admin/users/${id}/toggle-active`);
      setUsers(users.map(u => u.id === id ? { ...u, is_active: res.data.is_active } : u));
      toast.success(res.data.message);
    } catch (error) {
       toast.error("Impossible de modifier le statut");
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm("Supprimer définitivement cet utilisateur ?")) {
      try {
        await axios.delete(`/admin/users/${id}`);
        setUsers(users.filter(u => u.id !== id));
        toast.success("Utilisateur supprimé");
      } catch (error) {
        toast.error("Erreur suppression");
      }
    }
  };

  const exportCSV = () => {
    const headers = ["Nom", "Email", "Rôle", "Statut", "Date"];
    const rows = filteredUsers.map(u => [
      u.name,
      u.email,
      u.role,
      u.is_active ? "Actif" : "Banni",
      new Date(u.created_at).toLocaleDateString()
    ]);

    let csvContent = "data:text/csv;charset=utf-8," 
      + [headers, ...rows].map(e => e.join(",")).join("\n");
    
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", "users_export.csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const filteredUsers = users
    .filter((user) => {
      const matchesSearch =
        user.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        user.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (user.phone && user.phone.includes(searchTerm));

      const matchesRole = filterRole === "all" || user.role === filterRole;
      const matchesStatus = filterStatus === "all" || 
        (filterStatus === "active" ? user.is_active : !user.is_active);

      return matchesSearch && matchesRole && matchesStatus;
    })
    .sort((a, b) => {
      const valA = a[sortBy];
      const valB = b[sortBy];
      if (sortOrder === "asc") return valA > valB ? 1 : -1;
      return valA < valB ? 1 : -1;
    });

  // Pagination
  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = filteredUsers.slice(indexOfFirstItem, indexOfLastItem);
  const totalPages = Math.ceil(filteredUsers.length / itemsPerPage);

  return (
    <div className="space-y-6 animate-fadeIn">
      
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-black text-slate-800">Gestion Utilisateurs</h1>
          <p className="text-slate-500">Listing complet et contrôle des accès</p>
        </div>
        <button 
          onClick={exportCSV}
          className="flex items-center gap-2 px-6 py-3 bg-slate-800 text-white rounded-2xl font-bold hover:bg-slate-700 transition-all shadow-lg shadow-slate-200"
        >
          <FaDownload /> Exporter CSV
        </button>
      </div>

      {/* Controls Bar */}
      <div className="bg-white p-6 rounded-[2.5rem] border border-slate-100 shadow-sm space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          
          {/* Search */}
          <div className="md:col-span-2 relative">
            <FaSearch className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300" />
            <input
              type="text"
              placeholder="Rechercher par nom, email, téléphone..."
              className="w-full pl-12 pr-4 py-3 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-blue-500/20 transition-all font-medium"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          {/* Role Filter */}
          <div className="relative">
            <FaUsers className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300" />
            <select
              className="w-full pl-12 pr-4 py-3 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-blue-500/20 appearance-none font-bold text-slate-600"
              value={filterRole}
              onChange={(e) => setFilterRole(e.target.value)}
            >
              <option value="all">Tous les rôles</option>
              <option value="client">Clients</option>
              <option value="prestataire">Prestataires</option>
              <option value="admin">Admins</option>
            </select>
          </div>

          {/* Status Filter */}
          <div className="relative">
            <FaFilter className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300" />
            <select
              className="w-full pl-12 pr-4 py-3 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-blue-500/20 appearance-none font-bold text-slate-600"
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
            >
              <option value="all">Tous statuts</option>
              <option value="active">Actifs</option>
              <option value="inactive">Bannis</option>
            </select>
          </div>
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-white rounded-[2.5rem] border border-slate-100 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50/50 border-b border-slate-100">
                <th className="px-6 py-5 text-xs font-black text-slate-400 uppercase tracking-widest cursor-pointer" onClick={() => {setSortBy('name'); setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc')}}>
                  Utilisateur {sortBy === 'name' && (sortOrder === 'asc' ? <FaSortAmountUp className="inline ml-1" /> : <FaSortAmountDown className="inline ml-1" />)}
                </th>
                <th className="px-6 py-5 text-xs font-black text-slate-400 uppercase tracking-widest">Rôle</th>
                <th className="px-6 py-5 text-xs font-black text-slate-400 uppercase tracking-widest">Statut</th>
                <th className="px-6 py-5 text-xs font-black text-slate-400 uppercase tracking-widest cursor-pointer" onClick={() => {setSortBy('created_at'); setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc')}}>
                  Date {sortBy === 'created_at' && (sortOrder === 'asc' ? <FaSortAmountUp className="inline ml-1" /> : <FaSortAmountDown className="inline ml-1" />)}
                </th>
                <th className="px-6 py-5 text-xs font-black text-slate-400 uppercase tracking-widest text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                   <td colSpan="5" className="py-20 text-center">
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
                   </td>
                </tr>
              ) : currentItems.length === 0 ? (
                <tr>
                   <td colSpan="5" className="py-20 text-center text-slate-400 font-bold">
                      Aucun utilisateur ne correspond aux critères
                   </td>
                </tr>
              ) : (
                currentItems.map((user) => (
                  <tr key={user.id} className="border-b border-slate-50 hover:bg-slate-50/50 transition-colors group">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-4">
                        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-slate-100 to-slate-200 flex items-center justify-center text-slate-500 font-bold">
                           {user.profile_photo ? (
                             <img src={user.profile_photo} alt="" className="w-full h-full rounded-xl object-cover" />
                           ) : user.name?.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <p className="font-black text-slate-800">{user.name}</p>
                          <p className="text-xs text-slate-400 font-medium">{user.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                       <span className={`px-3 py-1 rounded-lg text-[10px] font-black uppercase tracking-tighter ${
                         user.role === 'admin' ? 'bg-indigo-50 text-indigo-600' : 
                         user.role === 'prestataire' ? 'bg-purple-50 text-purple-600' : 'bg-blue-50 text-blue-600'
                       }`}>
                         {user.role}
                       </span>
                    </td>
                    <td className="px-6 py-4">
                       <div className="flex items-center gap-2">
                          <div className={`w-2 h-2 rounded-full ${user.is_active ? 'bg-emerald-500' : 'bg-rose-500'}`}></div>
                          <span className={`text-xs font-bold ${user.is_active ? 'text-emerald-600' : 'text-rose-600'}`}>
                            {user.is_active ? 'Actif' : 'Désactivé'}
                          </span>
                       </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-500 font-medium">
                       {new Date(user.created_at).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4 text-right">
                       <div className="flex justify-end gap-2">
                          <button 
                            onClick={() => toggleStatus(user.id)}
                            title={user.is_active ? "Désactiver" : "Activer"}
                            className={`w-9 h-9 rounded-xl flex items-center justify-center transition-all ${
                              user.is_active ? 'bg-rose-50 text-rose-500 hover:bg-rose-500 hover:text-white' : 'bg-emerald-50 text-emerald-500 hover:bg-emerald-500 hover:text-white'
                            }`}
                          >
                            {user.is_active ? <FaBan size={14} /> : <FaCheckCircle size={14} />}
                          </button>
                          <button 
                            onClick={() => navigate(`/admin/users/edit/${user.id}`)}
                            className="w-9 h-9 bg-blue-50 text-blue-500 rounded-xl flex items-center justify-center hover:bg-blue-500 hover:text-white transition-all"
                          >
                             <FaUserEdit size={14} />
                          </button>
                          <button 
                            onClick={() => handleDelete(user.id)}
                            className="w-9 h-9 bg-slate-50 text-slate-400 rounded-xl flex items-center justify-center hover:bg-rose-500 hover:text-white transition-all"
                          >
                             <FaTrashAlt size={14} />
                          </button>
                       </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="px-6 py-6 border-t border-slate-100 flex items-center justify-between bg-slate-50/30">
            <p className="text-sm text-slate-400 font-medium">
              Affichage de {indexOfFirstItem + 1} à {Math.min(indexOfLastItem, filteredUsers.length)} sur {filteredUsers.length}
            </p>
            <div className="flex gap-2">
               {[...Array(totalPages)].map((_, i) => (
                 <button
                  key={i}
                  onClick={() => setCurrentPage(i + 1)}
                  className={`w-10 h-10 rounded-xl font-bold transition-all ${
                    currentPage === i + 1 
                      ? 'bg-blue-600 text-white shadow-lg shadow-blue-200' 
                      : 'bg-white text-slate-500 border border-slate-100 hover:border-blue-300'
                  }`}
                 >
                   {i + 1}
                 </button>
               ))}
            </div>
          </div>
        )}
      </div>

    </div>
  );
};

export default UserManagement;
