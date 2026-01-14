import React, { useEffect, useState } from "react";
import axios from "../../axios";
import {
  FaCheckCircle,
  FaTimesCircle,
  FaBuilding,
  FaUser,
  FaClock,
  FaMapMarkerAlt,
  FaPhone,
  FaEnvelope,
  FaBriefcase,
} from "react-icons/fa";

const ProviderValidation = () => {
  const [pendingProviders, setPendingProviders] = useState([]);
  const [validatedProviders, setValidatedProviders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("pending");
  const [selectedProvider, setSelectedProvider] = useState(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      const [pendingRes, validatedRes] = await Promise.all([
        axios.get("/admin/providers/pending"),
        axios.get("/admin/providers/validated"),
      ]);
      setPendingProviders(pendingRes.data);
      setValidatedProviders(validatedRes.data);
    } catch (error) {
      console.error("Erreur chargement:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleValidate = async (providerId) => {
    if (!window.confirm("Êtes-vous sûr de vouloir valider ce prestataire ?"))
      return;

    try {
      await axios.post(`/admin/providers/${providerId}/validate`);
      await loadData();
      setSelectedProvider(null);
      alert("Prestataire validé avec succès !");
    } catch (error) {
      console.error("Erreur validation:", error);
      alert("Erreur lors de la validation");
    }
  };

  const handleReject = async (providerId) => {
    if (
      !window.confirm(
        "Êtes-vous sûr de vouloir rejeter et supprimer ce prestataire ?"
      )
    )
      return;

    try {
      await axios.delete(`/admin/providers/${providerId}/reject`);
      await loadData();
      setSelectedProvider(null);
      alert("Prestataire rejeté");
    } catch (error) {
      console.error("Erreur rejet:", error);
      alert("Erreur lors du rejet");
    }
  };

  const ProviderCard = ({ provider, showActions = false }) => (
    <div
      className="bg-white rounded-2xl p-6 border border-slate-100 hover:shadow-xl transition-all duration-300 cursor-pointer"
      onClick={() => setSelectedProvider(provider)}
    >
      {/* Header avec Avatar et Type */}
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-4">
          {provider.profile_photo ? (
            <img
              src={provider.profile_photo}
              alt={provider.name}
              className="w-16 h-16 rounded-xl object-cover"
            />
          ) : (
            <div className="w-16 h-16 rounded-xl bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white text-2xl font-bold">
              {provider.name?.charAt(0) || "?"}
            </div>
          )}
          <div>
            <h3 className="text-lg font-bold text-slate-900">
              {provider.name}
            </h3>
            {provider.service && (
              <p className="text-sm text-blue-600 font-medium">
                {provider.service}
              </p>
            )}
          </div>
        </div>

        {provider.is_agency && (
          <span className="px-3 py-1 bg-purple-100 text-purple-700 rounded-full text-xs font-bold flex items-center gap-1">
            <FaBuilding className="text-xs" />
            AGENCE
          </span>
        )}
      </div>

      {/* Infos */}
      <div className="space-y-2 mb-4">
        <div className="flex items-center gap-2 text-sm text-slate-600">
          <FaEnvelope className="text-slate-400" />
          <span>{provider.email}</span>
        </div>
        {provider.phone && (
          <div className="flex items-center gap-2 text-sm text-slate-600">
            <FaPhone className="text-slate-400" />
            <span>{provider.phone}</span>
          </div>
        )}
        {provider.location && (
          <div className="flex items-center gap-2 text-sm text-slate-600">
            <FaMapMarkerAlt className="text-slate-400" />
            <span>{provider.location}</span>
          </div>
        )}
      </div>

      {/* Professions */}
      {provider.professions && provider.professions.length > 0 && (
        <div className="flex flex-wrap gap-2 mb-4">
          {provider.professions.map((prof) => (
            <span
              key={prof.id}
              className="px-3 py-1 bg-slate-100 text-slate-700 rounded-lg text-xs font-medium"
            >
              {prof.name}
            </span>
          ))}
        </div>
      )}

      {/* Date */}
      <div className="flex items-center gap-2 text-xs text-slate-400 pt-3 border-t border-slate-100">
        <FaClock />
        <span>
          Inscrit le {new Date(provider.created_at).toLocaleDateString("fr-FR")}
        </span>
      </div>

      {/* Actions */}
      {showActions && (
        <div className="flex gap-3 mt-4 pt-4 border-t border-slate-100">
          <button
            onClick={(e) => {
              e.stopPropagation();
              handleValidate(provider.id);
            }}
            className="flex-1 flex items-center justify-center gap-2 px-4 py-3 bg-green-500 hover:bg-green-600 text-white rounded-xl font-bold transition-all"
          >
            <FaCheckCircle />
            Valider
          </button>
          <button
            onClick={(e) => {
              e.stopPropagation();
              handleReject(provider.id);
            }}
            className="px-4 py-3 bg-red-50 hover:bg-red-100 text-red-600 rounded-xl font-bold transition-all"
          >
            <FaTimesCircle />
          </button>
        </div>
      )}
    </div>
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-600 to-purple-600 rounded-3xl p-8 text-white">
        <h1 className="text-3xl font-black mb-2">
          Validation des Prestataires
        </h1>
        <p className="text-blue-100">
          Gérez les demandes d'inscription des prestataires
        </p>
      </div>

      {/* Tabs */}
      <div className="flex gap-4 bg-white p-2 rounded-2xl border border-slate-100">
        <button
          onClick={() => setActiveTab("pending")}
          className={`flex-1 px-6 py-3 rounded-xl font-bold transition-all ${
            activeTab === "pending"
              ? "bg-orange-500 text-white shadow-lg"
              : "text-slate-600 hover:bg-slate-50"
          }`}
        >
          En Attente ({pendingProviders.length})
        </button>
        <button
          onClick={() => setActiveTab("validated")}
          className={`flex-1 px-6 py-3 rounded-xl font-bold transition-all ${
            activeTab === "validated"
              ? "bg-green-500 text-white shadow-lg"
              : "text-slate-600 hover:bg-slate-50"
          }`}
        >
          Validés ({validatedProviders.length})
        </button>
      </div>

      {/* Content */}
      {activeTab === "pending" ? (
        pendingProviders.length === 0 ? (
          <div className="bg-white rounded-2xl p-12 text-center border-2 border-dashed border-slate-200">
            <div className="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <FaCheckCircle className="text-slate-400 text-3xl" />
            </div>
            <p className="text-slate-500 font-medium">
              Aucune demande en attente
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {pendingProviders.map((provider) => (
              <ProviderCard
                key={provider.id}
                provider={provider}
                showActions={true}
              />
            ))}
          </div>
        )
      ) : validatedProviders.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center border-2 border-dashed border-slate-200">
          <p className="text-slate-500 font-medium">Aucun prestataire validé</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {validatedProviders.map((provider) => (
            <ProviderCard
              key={provider.id}
              provider={provider}
              showActions={false}
            />
          ))}
        </div>
      )}

      {/* Modal détails */}
      {selectedProvider && (
        <div
          className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
          onClick={() => setSelectedProvider(null)}
        >
          <div
            className="bg-white rounded-3xl p-8 max-w-2xl w-full max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex justify-between items-start mb-6">
              <h2 className="text-2xl font-black text-slate-900">
                Détails du Prestataire
              </h2>
              <button
                onClick={() => setSelectedProvider(null)}
                className="p-2 hover:bg-slate-100 rounded-lg"
              >
                ✕
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="text-sm font-bold text-slate-500 uppercase">
                  Nom
                </label>
                <p className="text-lg font-medium">{selectedProvider.name}</p>
              </div>

              {selectedProvider.service && (
                <div>
                  <label className="text-sm font-bold text-slate-500 uppercase">
                    Nom de Service/Agence
                  </label>
                  <p className="text-lg font-medium">
                    {selectedProvider.service}
                  </p>
                </div>
              )}

              <div>
                <label className="text-sm font-bold text-slate-500 uppercase">
                  Email
                </label>
                <p className="text-lg font-medium">{selectedProvider.email}</p>
              </div>

              {selectedProvider.phone && (
                <div>
                  <label className="text-sm font-bold text-slate-500 uppercase">
                    Téléphone
                  </label>
                  <p className="text-lg font-medium">
                    {selectedProvider.phone}
                  </p>
                </div>
              )}

              {selectedProvider.slogan && (
                <div>
                  <label className="text-sm font-bold text-slate-500 uppercase">
                    Slogan
                  </label>
                  <p className="text-lg font-medium italic">
                    {selectedProvider.slogan}
                  </p>
                </div>
              )}

              {selectedProvider.adresse && (
                <div>
                  <label className="text-sm font-bold text-slate-500 uppercase">
                    Adresse
                  </label>
                  <p className="text-lg font-medium">
                    {selectedProvider.adresse}
                  </p>
                </div>
              )}

              {selectedProvider.location && (
                <div>
                  <label className="text-sm font-bold text-slate-500 uppercase">
                    Ville / Localisation
                  </label>
                  <div className="flex items-center gap-2">
                    <p className="text-lg font-medium">
                      {selectedProvider.location}
                    </p>
                    {selectedProvider.latitude &&
                      selectedProvider.longitude && (
                        <a
                          href={`https://www.google.com/maps/search/?api=1&query=${selectedProvider.latitude},${selectedProvider.longitude}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-blue-600 hover:underline text-sm flex items-center gap-1"
                        >
                          <FaMapMarkerAlt /> Voir sur la carte
                        </a>
                      )}
                  </div>
                </div>
              )}

              {selectedProvider.professions &&
                selectedProvider.professions.length > 0 && (
                  <div>
                    <label className="text-sm font-bold text-slate-500 uppercase mb-2 block">
                      Professions
                    </label>
                    <div className="flex flex-wrap gap-2">
                      {selectedProvider.professions.map((prof) => (
                        <span
                          key={prof.id}
                          className="px-3 py-1 bg-blue-100 text-blue-700 rounded-lg font-medium"
                        >
                          {prof.name}
                        </span>
                      ))}
                    </div>
                  </div>
                )}

              {selectedProvider.min_price && (
                <div>
                  <label className="text-sm font-bold text-slate-500 uppercase">
                    Prix Minimum
                  </label>
                  <p className="text-lg font-medium">
                    {selectedProvider.min_price} FCFA
                  </p>
                </div>
              )}
            </div>

            {activeTab === "pending" && (
              <div className="flex gap-4 mt-8 pt-6 border-t">
                <button
                  onClick={() => handleValidate(selectedProvider.id)}
                  className="flex-1 px-6 py-4 bg-green-500 hover:bg-green-600 text-white rounded-xl font-bold flex items-center justify-center gap-2"
                >
                  <FaCheckCircle />
                  Valider ce Prestataire
                </button>
                <button
                  onClick={() => handleReject(selectedProvider.id)}
                  className="px-6 py-4 bg-red-500 hover:bg-red-600 text-white rounded-xl font-bold"
                >
                  <FaTimesCircle />
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default ProviderValidation;
