import React, { useState, useEffect } from "react";
import { useAuth } from "../Context/AuthContext";
import axios from "axios";
import {
  FaUserCircle,
  FaChevronDown,
  FaChevronUp,
  FaTimes,
} from "react-icons/fa";

const ProfileSettings = () => {
  const { user, loading, setUser } = useAuth();
  const [formData, setFormData] = useState({
    nom: "",
    prenom: "",
    email: "",
    telephone: "",
    location: "",
    adresse: "",
    profile_photo: null,
    slogan: "",
    profession_ids: [],
    competances: [],
    min_price: "",
  });
  const [previewPhoto, setPreviewPhoto] = useState(null);
  const [professions, setProfessions] = useState([]);
  const [competanceInput, setCompetanceInput] = useState("");
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState("");
  const [sections, setSections] = useState({
    perso: true,
    pro: false,
    competences: false,
  });

  useEffect(() => {
    const fetchProfessions = async () => {
      try {
        const res = await axios.get("http://localhost:8000/api/professions");
        setProfessions(res.data);
      } catch (err) {
        console.error(err);
      }
    };
    fetchProfessions();
  }, []);

  useEffect(() => {
    const fetchUser = async () => {
      if (!user) return;
      const token = localStorage.getItem("token");
      try {
        const res = await axios.get("http://localhost:8000/api/me", {
          headers: { Authorization: `Bearer ${token}` },
        });
        const data = res.data;
        console.log("Data", data);
        setFormData({
          nom: data.name?.split(" ")[0] || "",
          prenom: data.name?.split(" ").slice(1).join(" ") || "",
          email: data.email || "",
          telephone: data.telephone || "",
          location: data.location || "",
          adresse: data.adresse || "",
          profile_photo: data.photo || null,
          slogan: data.slogan || "",
          profession_ids: data.professions?.map((p) => p.id.toString()) || [],
          competances: data.competances || [],
          min_price: data.min_price || "",
        });
        if (data.photo)
          setPreviewPhoto(
            `http://localhost:8000/storage/profile_photos/${data.photo}`
          );
      } catch (err) {
        console.error(err);
      }
    };
    fetchUser();
  }, [user]);

  if (loading) return <div>Loading...</div>;

  const handleChange = (e) => {
    const { name, value, type, files } = e.target;
    if (type === "file") {
      setFormData({ ...formData, profile_photo: files[0] });
      setPreviewPhoto(URL.createObjectURL(files[0]));
    } else {
      setFormData({ ...formData, [name]: value });
    }
  };

  const handleCompetanceKey = (e) => {
    if (e.key === "Enter" && competanceInput.trim()) {
      e.preventDefault();
      if (!formData.competances.includes(competanceInput.trim())) {
        setFormData({
          ...formData,
          competances: [...formData.competances, competanceInput.trim()],
        });
      }
      setCompetanceInput("");
    }
  };

  const removeCompetance = (c) => {
    setFormData({
      ...formData,
      competances: formData.competances.filter((comp) => comp !== c),
    });
  };

  const toggleSection = (section) => {
    setSections({ ...sections, [section]: !sections[section] });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setSuccess("");
    try {
      const dataToSend = new FormData();
      Object.entries(formData).forEach(([key, value]) => {
        if (Array.isArray(value)) dataToSend.append(key, JSON.stringify(value));
        else dataToSend.append(key, value);
      });

      const res = await axios.put("http://localhost:8000/api/me", dataToSend, {
        headers: {
          Authorization: `Bearer ${user.token}`,
          "Content-Type": "multipart/form-data",
        },
      });
      setSuccess("Profil mis à jour !");
      setUser(res.data);
    } catch (err) {
      setSuccess("Erreur lors de la mise à jour.");
      console.error(err);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="p-6 max-w-7xl mx-auto flex flex-col md:flex-row gap-8">
      {/* Colonne gauche: photo + résumé */}
      <div className="md:w-1/3 flex flex-col items-center md:items-start">
        <div className="relative w-40 h-40 mb-4">
          {previewPhoto ? (
            <img
              src={previewPhoto}
              alt="Photo de profil"
              className="w-full h-full object-cover rounded-full border-4 border-indigo-600 shadow"
            />
          ) : (
            <FaUserCircle className="w-full h-full text-gray-300" />
          )}
          <label
            htmlFor="fileUpload"
            className="absolute inset-0 flex items-center justify-center bg-black/30 opacity-0 hover:opacity-100 text-white rounded-full cursor-pointer transition"
          >
            Changer
          </label>
          <input
            type="file"
            name="profile_photo"
            onChange={handleChange}
            className="hidden"
            id="fileUpload"
          />
        </div>
        <h1 className="text-2xl font-bold">
          {formData.nom} {formData.prenom}
        </h1>
        <p className="text-gray-600">
          {formData.slogan || "Ajouter un slogan"}
        </p>
        <p className="text-gray-500">{formData.location}</p>
      </div>

      {/* Colonne droite: formulaire */}
      <form
        onSubmit={handleSubmit}
        className="md:w-2/3 space-y-6 bg-white shadow rounded-xl p-6"
      >
        {/* Infos personnelles */}
        <div className="border-b pb-2">
          <div
            className="flex justify-between items-center cursor-pointer"
            onClick={() => toggleSection("perso")}
          >
            <h2 className="text-xl font-semibold">Informations personnelles</h2>
            {sections.perso ? <FaChevronUp /> : <FaChevronDown />}
          </div>
          {sections.perso && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
              <input
                type="text"
                name="nom"
                placeholder="Nom"
                value={formData.nom}
                onChange={handleChange}
                className="border rounded p-2"
              />
              <input
                type="text"
                name="prenom"
                placeholder="Prénom"
                value={formData.prenom}
                onChange={handleChange}
                className="border rounded p-2"
              />
              <input
                type="email"
                name="email"
                placeholder="Email"
                value={formData.email}
                onChange={handleChange}
                className="border rounded p-2"
              />
              <input
                type="text"
                name="telephone"
                placeholder="Téléphone"
                value={formData.telephone}
                onChange={handleChange}
                className="border rounded p-2"
              />
              <input
                type="text"
                name="adresse"
                placeholder="Adresse"
                value={formData.adresse}
                onChange={handleChange}
                className="border rounded p-2"
              />
              <input
                type="text"
                name="location"
                placeholder="Localisation"
                value={formData.location}
                onChange={handleChange}
                className="border rounded p-2"
              />
            </div>
          )}
        </div>

        {/* Infos professionnelles */}
        {user?.role === "prestataire" && (
          <div className="border-b pb-2">
            <div
              className="flex justify-between items-center cursor-pointer"
              onClick={() => toggleSection("pro")}
            >
              <h2 className="text-xl font-semibold">
                Informations professionnelles
              </h2>
              {sections.pro ? <FaChevronUp /> : <FaChevronDown />}
            </div>
            {sections.pro && (
              <>
                <div className="flex flex-wrap gap-2 mt-4 mb-4">
                  {professions.map((p) => {
                    const selected = formData.profession_ids.includes(
                      p.id.toString()
                    );
                    return (
                      <button
                        type="button"
                        key={p.id}
                        onClick={() => {
                          const ids = formData.profession_ids;
                          if (ids.includes(p.id.toString())) {
                            setFormData({
                              ...formData,
                              profession_ids: ids.filter(
                                (i) => i !== p.id.toString()
                              ),
                            });
                          } else {
                            setFormData({
                              ...formData,
                              profession_ids: [...ids, p.id.toString()],
                            });
                          }
                        }}
                        className={`px-4 py-2 rounded-full text-sm font-medium ${
                          selected
                            ? "bg-indigo-600 text-white"
                            : "bg-gray-100 text-gray-700"
                        }`}
                      >
                        {p.name}
                      </button>
                    );
                  })}
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <input
                    type="number"
                    name="min_price"
                    placeholder="Prix minimum"
                    value={formData.min_price}
                    onChange={handleChange}
                    className="border rounded p-2"
                  />
                  <input
                    type="text"
                    name="slogan"
                    placeholder="Slogan"
                    value={formData.slogan}
                    onChange={handleChange}
                    className="border rounded p-2"
                  />
                </div>
              </>
            )}
          </div>
        )}

        {/* Compétences */}
        <div className="border-b pb-2">
          <div
            className="flex justify-between items-center cursor-pointer"
            onClick={() => toggleSection("competences")}
          >
            <h2 className="text-xl font-semibold">Compétences</h2>
            {sections.competences ? <FaChevronUp /> : <FaChevronDown />}
          </div>

          {sections.competences && (
            <div className="flex flex-wrap gap-2 mt-4 items-center">
              {formData.competances.map((c, index) => (
                <span
                  key={c.id || index}
                  className="bg-indigo-100 text-indigo-700 px-3 py-1 rounded-full text-sm font-medium flex items-center gap-1"
                >
                  {c.title} {/* affiche le titre */}
                  <button
                    type="button"
                    onClick={() => removeCompetance(c.id)}
                    className="text-red-500 font-bold hover:text-red-700"
                  >
                    ×
                  </button>
                </span>
              ))}

              <input
                type="text"
                placeholder="Ajouter une compétence et appuyer sur Entrée"
                value={competanceInput}
                onChange={(e) => setCompetanceInput(e.target.value)}
                onKeyDown={handleCompetanceKey}
                className="border border-gray-300 rounded-xl p-2 focus:ring-2 focus:ring-indigo-500 flex-1 min-w-[150px]"
              />
            </div>
          )}
        </div>

        <button
          type="submit"
          disabled={saving}
          className="w-full bg-indigo-600 text-white py-3 rounded font-semibold hover:bg-indigo-700 transition"
        >
          {saving ? "Enregistrement..." : "Enregistrer"}
        </button>
        {success && (
          <div className="text-green-600 font-medium text-center mt-2">
            {success}
          </div>
        )}
      </form>
    </div>
  );
};

export default ProfileSettings;
