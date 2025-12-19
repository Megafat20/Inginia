import React, { useEffect, useState } from "react";
import { fetchUsers, deleteUser } from "./services/UserService";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";

const Users = () => {
  const [users, setUsers] = useState([]);
  const navigate = useNavigate();
  const { t } = useTranslation();

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
    if (window.confirm("Confirmer la suppression ?")) {
      try {
        await deleteUser(id);
        loadUsers();
      } catch (err) {
        console.error("Erreur suppression", err);
      }
    }
  };

  return (
    <div className="max-w-5xl mx-auto p-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-gray-800">{t("users_list")}</h2>
        <button
          onClick={() => navigate("/create")}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
        >
          ➕ {t("add_user")}
        </button>
      </div>

      {/* Liste des utilisateurs */}
      {users.length === 0 ? (
        <p className="text-gray-500 text-center">{t("no_users_found")}</p>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {users.map((u) => (
            <div
              key={u.id}
              className="bg-white shadow-md rounded-2xl p-5 flex flex-col justify-between hover:shadow-lg transition"
            >
              <div>
                <h3 className="text-lg font-semibold text-gray-800">{u.name}</h3>
                <p className="text-gray-500">{u.email}</p>
                <span className="inline-block mt-2 px-3 py-1 text-sm rounded-full bg-gray-100 text-gray-700">
                  {u.role}
                </span>
              </div>

              <div className="mt-4 flex gap-3">
                <button
                  onClick={() => navigate(`/edit/${u.id}`)}
                  className="flex-1 px-3 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition"
                >
                  ✏️ {t("edit_user")}
                </button>
                <button
                  onClick={() => handleDelete(u.id)}
                  className="flex-1 px-3 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition"
                >
                  🗑️ {t("delete_user")}
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default Users;
