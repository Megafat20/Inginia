import React, { useState, useEffect } from "react";
import axios from "axios";
import Select from "react-select";
import { createService, updateService } from "../services/ProviderService";
import {
  FaTimes,
  FaTools,
  FaTag,
  FaAlignLeft,
  FaMoneyBillWave,
} from "react-icons/fa";

const ServiceForm = ({ service, onSuccess, onClose }) => {
  const [title, setTitle] = useState(service?.title || "");
  const [description, setDescription] = useState(service?.description || "");
  const [price, setPrice] = useState(service?.price || "");
  const [professions, setProfessions] = useState([]);
  const [selectedProfession, setSelectedProfession] = useState(
    service?.profession_id || null
  );
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    // Bloquer le scroll du body quand la modal est ouverte
    document.body.style.overflow = "hidden";

    const fetchProfessions = async () => {
      try {
        const token = localStorage.getItem("token");
        const response = await axios.get(
          "http://localhost:8000/api/provider/myprofessions",
          { headers: { Authorization: `Bearer ${token}` } }
        );
        // data.professions ou data directement ? ça dépend de l'API
        // Checkons : ProviderController::myProfessions renvoie response()->json(['professions' => ...])
        setProfessions(response.data.professions || []);
      } catch (error) {
        console.error("Erreur fetching professions :", error);
      }
    };
    fetchProfessions();

    return () => {
      document.body.style.overflow = "unset";
    };
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    if (!selectedProfession) {
      setError("Veuillez sélectionner une profession liée à ce service.");
      setLoading(false);
      return;
    }

    const payload = {
      title,
      description,
      price: price ? parseFloat(price) : null,
      profession_id: selectedProfession,
    };

    try {
      if (service) {
        await updateService(service.id, payload);
      } else {
        await createService(payload);
      }
      onSuccess();
      onClose();
    } catch (err) {
      console.error(err);
      setError("Erreur lors de l'enregistrement. Vérifiez les champs.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-fadeIn">
      {/* Modal Card */}
      <div className="bg-white w-full max-w-md rounded-2xl shadow-2xl overflow-hidden transform transition-all animate-bounceIn border border-gray-100">
        {/* Header */}
        <div className="bg-gray-50 px-6 py-4 border-b border-gray-100 flex justify-between items-center">
          <h3 className="text-xl font-bold text-gray-800 flex items-center gap-2">
            {service ? (
              <FaTools className="text-blue-600" />
            ) : (
              <FaTools className="text-green-600" />
            )}
            {service ? "Modifier le Service" : "Nouveau Service"}
          </h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-red-500 transition p-1 bg-white rounded-full shadow-sm"
          >
            <FaTimes />
          </button>
        </div>

        {/* Body */}
        <div className="p-6">
          {error && (
            <div className="bg-red-50 text-red-600 p-3 rounded-lg mb-4 text-sm font-medium border border-red-100 flex items-center gap-2">
              <FaTimes className="flex-shrink-0" /> {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Profession Select */}
            <div>
              <label className="block text-sm font-semibold text-gray-600 mb-1">
                Profession associée
              </label>
              <Select
                options={professions.map((p) => ({
                  value: p.id,
                  label: p.name,
                }))}
                value={
                  professions.find((p) => p.id === selectedProfession)
                    ? {
                        value: selectedProfession,
                        label: professions.find(
                          (p) => p.id === selectedProfession
                        ).name,
                      }
                    : null
                }
                onChange={(selected) =>
                  setSelectedProfession(selected?.value || null)
                }
                placeholder="Sélectionnez..."
                className="text-sm"
                styles={{
                  control: (base) => ({
                    ...base,
                    borderColor: "#e2e8f0",
                    borderRadius: "0.5rem",
                    padding: "2px",
                    boxShadow: "none",
                    "&:hover": { borderColor: "#cbd5e1" },
                  }),
                }}
              />
            </div>

            {/* Titre */}
            <div>
              <label className="block text-sm font-semibold text-gray-600 mb-1">
                Titre du service
              </label>
              <div className="relative">
                <i className="absolute left-3 top-3.5 text-gray-400">
                  <FaTag />
                </i>
                <input
                  type="text"
                  placeholder="ex: Réparation Pneu Crevé"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-100 focus:border-blue-400 transition"
                  required
                />
              </div>
            </div>

            {/* Description */}
            <div>
              <label className="block text-sm font-semibold text-gray-600 mb-1">
                Description
              </label>
              <div className="relative">
                <i className="absolute left-3 top-3.5 text-gray-400">
                  <FaAlignLeft />
                </i>
                <textarea
                  placeholder="Détaillez ce que comprend ce service..."
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-100 focus:border-blue-400 transition min-h-[100px]"
                />
              </div>
            </div>

            {/* Prix */}
            <div>
              <label className="block text-sm font-semibold text-gray-600 mb-1">
                Prix (FCFA)
              </label>
              <div className="relative">
                <i className="absolute left-3 top-3.5 text-gray-400">
                  <FaMoneyBillWave />
                </i>
                <input
                  type="number"
                  placeholder="0"
                  value={price}
                  onChange={(e) => setPrice(e.target.value)}
                  className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-100 focus:border-blue-400 transition"
                />
              </div>
            </div>

            {/* Footer Actions */}
            <div className="flex gap-3 pt-4">
              <button
                type="button"
                onClick={onClose}
                className="flex-1 py-3 bg-gray-100 text-gray-600 rounded-xl font-bold hover:bg-gray-200 transition"
              >
                Annuler
              </button>
              <button
                type="submit"
                disabled={loading}
                className="flex-1 py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 transition shadow-lg flex justify-center items-center"
              >
                {loading ? <span className="loader mr-2"></span> : null}
                {service ? "Sauvegarder" : "Créer le Service"}
              </button>
            </div>
          </form>
        </div>
      </div>

      <style>{`
            .loader {
                border: 2px solid #f3f3f3;
                border-top: 2px solid white;
                border-radius: 50%;
                width: 14px;
                height: 14px;
                animation: spin 1s linear infinite;
                display: inline-block;
            }
            @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        `}</style>
    </div>
  );
};

export default ServiceForm;
