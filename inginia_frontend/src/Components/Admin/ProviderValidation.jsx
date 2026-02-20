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
  FaFileAlt,
  FaImage,
  FaExternalLinkAlt,
  FaInfoCircle,
} from "react-icons/fa";
import { toast } from "react-toastify";

const ProviderValidation = () => {
  const [pendingProviders, setPendingProviders] = useState([]);
  const [validatedProviders, setValidatedProviders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("pending");
  const [selectedProvider, setSelectedProvider] = useState(null);
  const [validationComment, setValidationComment] = useState("");
  const [validationExpiresAt, setValidationExpiresAt] = useState("");

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
      toast.error("Erreur chargement des prestataires");
    } finally {
      setLoading(false);
    }
  };

  const handleValidate = async (providerId) => {
    if (!window.confirm("Valider ce prestataire et lui donner accès aux missions ?")) return;

    try {
      await axios.post(`/admin/providers/${providerId}/validate`, {
        comment: validationComment,
        expires_at: validationExpiresAt
      });
      toast.success("Prestataire validé !");
      setValidationComment("");
      setValidationExpiresAt("");
      loadData();
      setSelectedProvider(null);
    } catch (error) {
      toast.error("Échec de la validation");
    }
  };

  const handleReject = async (providerId) => {
    if (!validationComment) {
      toast.warning("Un commentaire est requis pour rejeter un dossier.");
      return;
    }
    if (!window.confirm("Rejeter cette demande ?")) return;

    try {
      await axios.post(`/admin/providers/${providerId}/reject`, {
        comment: validationComment
      });
      toast.info("Demande rejetée");
      setValidationComment("");
      loadData();
      setSelectedProvider(null);
    } catch (error) {
      toast.error("Erreur lors du rejet");
    }
  };

  const ProviderTable = ({ providers, canValidate }) => (
    <div className="bg-white rounded-[2.5rem] border border-slate-100 shadow-sm overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50/50 border-b border-slate-100">
              <th className="px-6 py-5 text-xs font-black text-slate-400 uppercase tracking-widest">Prestataire</th>
              <th className="px-6 py-5 text-xs font-black text-slate-400 uppercase tracking-widest">Type</th>
              <th className="px-6 py-5 text-xs font-black text-slate-400 uppercase tracking-widest">Documents</th>
              <th className="px-6 py-5 text-xs font-black text-slate-400 uppercase tracking-widest">Inscrit le</th>
              <th className="px-6 py-5 text-xs font-black text-slate-400 uppercase tracking-widest text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {providers.map((p) => (
              <tr key={p.id} className="border-b border-slate-50 hover:bg-slate-50/50 transition-colors cursor-pointer group" onClick={() => setSelectedProvider(p)}>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-2xl bg-slate-100 flex-shrink-0">
                       {p.profile_photo ? (
                         <img src={p.profile_photo} alt="" className="w-full h-full rounded-2xl object-cover" />
                       ) : <div className="w-full h-full flex items-center justify-center text-slate-400 font-bold">{p.name?.charAt(0)}</div>}
                    </div>
                    <div>
                      <p className="font-black text-slate-800">{p.name}</p>
                      <p className="text-xs text-slate-400 font-medium">{p.email}</p>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <span className={`px-3 py-1 rounded-lg text-[10px] font-black uppercase tracking-tighter ${p.is_agency ? 'bg-purple-50 text-purple-600' : 'bg-blue-50 text-blue-600'}`}>
                    {p.is_agency ? 'AGENCE' : 'INDIVIDUEL'}
                  </span>
                </td>
                <td className="px-6 py-4">
                   <div className="flex items-center gap-1 text-slate-500 font-bold text-xs">
                      <FaFileAlt className="text-slate-300" />
                      {p.portfolios?.length || 0} pièces
                   </div>
                </td>
                <td className="px-6 py-4 text-xs text-slate-500 font-medium">
                   {new Date(p.created_at).toLocaleDateString()}
                </td>
                <td className="px-6 py-4 text-right">
                   <div className="flex justify-end gap-2" onClick={e => e.stopPropagation()}>
                      <button 
                        onClick={() => setSelectedProvider(p)}
                        className="w-10 h-10 bg-slate-100 text-slate-600 rounded-xl flex items-center justify-center hover:bg-slate-800 hover:text-white transition-all"
                      >
                         <FaInfoCircle />
                      </button>
                      {canValidate && (
                        <>
                          <button 
                            onClick={() => handleValidate(p.id)}
                            className="w-10 h-10 bg-emerald-50 text-emerald-500 rounded-xl flex items-center justify-center hover:bg-emerald-500 hover:text-white transition-all"
                          >
                             <FaCheckCircle />
                          </button>
                          <button 
                            onClick={() => handleReject(p.id)}
                            className="w-10 h-10 bg-rose-50 text-rose-500 rounded-xl flex items-center justify-center hover:bg-rose-500 hover:text-white transition-all"
                          >
                             <FaTimesCircle />
                          </button>
                        </>
                      )}
                   </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );

  if (loading && !pendingProviders.length && !validatedProviders.length) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fadeIn pb-20">
      
      {/* Header */}
      <div>
        <h1 className="text-3xl font-black text-slate-800">Validation & Certification</h1>
        <p className="text-slate-500">Vérifiez les antécédents et documents des nouveaux prestataires</p>
      </div>

      {/* Tabs */}
      <div className="flex bg-white p-2 rounded-[2rem] border border-slate-100 shadow-sm w-fit">
        <button
          onClick={() => setActiveTab("pending")}
          className={`px-8 py-3 rounded-[1.5rem] font-black text-sm transition-all flex items-center gap-2 ${
            activeTab === "pending"
              ? "bg-slate-800 text-white shadow-lg"
              : "text-slate-400 hover:text-slate-600"
          }`}
        >
          En Attente
          <span className={`px-2 py-0.5 rounded-full text-[10px] ${activeTab === 'pending' ? 'bg-white/20' : 'bg-slate-100'}`}>
            {pendingProviders.length}
          </span>
        </button>
        <button
          onClick={() => setActiveTab("validated")}
          className={`px-8 py-3 rounded-[1.5rem] font-black text-sm transition-all flex items-center gap-2 ${
            activeTab === "validated"
              ? "bg-slate-800 text-white shadow-lg"
              : "text-slate-400 hover:text-slate-600"
          }`}
        >
          Validés
          <span className={`px-2 py-0.5 rounded-full text-[10px] ${activeTab === 'validated' ? 'bg-white/20' : 'bg-slate-100'}`}>
            {validatedProviders.length}
          </span>
        </button>
      </div>

      {/* Table Content */}
      {activeTab === "pending" ? (
        pendingProviders.length === 0 ? (
          <div className="bg-white rounded-[2.5rem] p-20 text-center border-2 border-dashed border-slate-100">
             <FaCheckCircle className="mx-auto text-5xl text-emerald-100 mb-4" />
             <p className="text-xl font-black text-slate-800">Tout est à jour !</p>
             <p className="text-slate-400">Aucun prestataire ne demande de validation actuellement.</p>
          </div>
        ) : (
          <ProviderTable providers={pendingProviders} canValidate={true} />
        )
      ) : (
        <ProviderTable providers={validatedProviders} canValidate={false} />
      )}

      {/* Modern Side/Centered Modal for Details */}
      {selectedProvider && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
           <div className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm" onClick={() => setSelectedProvider(null)}></div>
           
           <div className="relative bg-white w-full max-w-4xl max-h-[90vh] overflow-hidden rounded-[3rem] shadow-2xl flex flex-col md:flex-row">
              
              {/* Left Column: Docs & Images (Scrollable) */}
              <div className="w-full md:w-1/2 bg-slate-50 p-8 overflow-y-auto border-r border-slate-100">
                 <h3 className="text-xs font-black text-slate-400 uppercase tracking-widest mb-6 flex items-center gap-2">
                    <FaFileAlt /> Documents & Portfolio ({selectedProvider.portfolios?.length || 0})
                 </h3>
                 
                 {selectedProvider.portfolios?.length > 0 ? (
                   <div className="grid grid-cols-1 gap-6">
                      {selectedProvider.portfolios.map(item => (
                        <div key={item.id} className="bg-white rounded-[2rem] p-4 shadow-sm border border-slate-100">
                           <div className="relative aspect-video rounded-2xl overflow-hidden mb-4 group">
                              <img src={item.image_url} alt={item.title} className="w-full h-full object-cover transition-transform group-hover:scale-110" />
                              <a 
                                href={item.image_url} 
                                target="_blank" 
                                rel="noreferrer"
                                className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white transition-opacity"
                              >
                                 <FaExternalLinkAlt size={24} />
                              </a>
                           </div>
                           <h4 className="font-black text-slate-800">{item.title}</h4>
                           <p className="text-sm text-slate-500">{item.description}</p>
                        </div>
                      ))}
                   </div>
                 ) : (
                   <div className="py-20 text-center">
                      <FaImage className="mx-auto text-4xl text-slate-200 mb-4" />
                      <p className="text-slate-400 font-medium">Aucun document téléchargé</p>
                   </div>
                 )}
              </div>

              {/* Right Column: Key Info */}
              <div className="w-full md:w-1/2 p-8 flex flex-col bg-white">
                 <div className="flex justify-between items-start mb-8">
                    <div className="flex items-center gap-4">
                       <div className="w-16 h-16 rounded-3xl bg-slate-100 border-4 border-white shadow-md overflow-hidden">
                          {selectedProvider.profile_photo && <img src={selectedProvider.profile_photo} alt="" className="w-full h-full object-cover" />}
                       </div>
                       <div>
                          <h2 className="text-2xl font-black text-slate-800">{selectedProvider.name}</h2>
                          <p className="text-blue-600 font-bold text-sm tracking-tight">{selectedProvider.service || 'Professionnel indépendant'}</p>
                       </div>
                    </div>
                    <button onClick={() => setSelectedProvider(null)} className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-400 hover:bg-slate-800 hover:text-white transition-all">✕</button>
                 </div>

                 <div className="space-y-6 flex-1 overflow-y-auto pr-2">
                    <div className="grid grid-cols-2 gap-4">
                       <div className="bg-slate-50 p-4 rounded-2xl">
                          <p className="text-[10px] font-black text-slate-400 uppercase mb-1 flex items-center gap-1"><FaEnvelope /> Email</p>
                          <p className="text-sm font-bold text-slate-800 truncate">{selectedProvider.email}</p>
                       </div>
                       <div className="bg-slate-50 p-4 rounded-2xl">
                          <p className="text-[10px] font-black text-slate-400 uppercase mb-1 flex items-center gap-1"><FaPhone /> Téléphone</p>
                          <p className="text-sm font-bold text-slate-800">{selectedProvider.phone || 'Non renseigné'}</p>
                       </div>
                    </div>

                    <div className="bg-slate-50 p-5 rounded-2xl">
                       <p className="text-[10px] font-black text-slate-400 uppercase mb-2 flex items-center gap-1"><FaMapMarkerAlt /> Localisation</p>
                       <p className="text-sm font-bold text-slate-800 mb-3">{selectedProvider.adresse || selectedProvider.location || 'N/A'}</p>
                       {selectedProvider.latitude && selectedProvider.longitude && (
                          <a 
                            href={`https://maps.google.com/?q=${selectedProvider.latitude},${selectedProvider.longitude}`}
                            target="_blank"
                            rel="noreferrer"
                            className="inline-flex items-center gap-2 px-4 py-2 bg-white rounded-xl text-xs font-black text-blue-600 shadow-sm border border-slate-100 hover:bg-blue-600 hover:text-white transition-all"
                          >
                            Ouvrir dans Google Maps
                          </a>
                       )}
                    </div>

                    <div>
                       <p className="text-[10px] font-black text-slate-400 uppercase mb-3 flex items-center gap-1"><FaBriefcase /> Professions</p>
                       <div className="flex flex-wrap gap-2">
                          {selectedProvider.professions?.map(prof => (
                            <span key={prof.id} className="px-4 py-2 bg-indigo-50 text-indigo-600 rounded-xl text-xs font-black">
                              {prof.name}
                            </span>
                          ))}
                       </div>
                    </div>

                     {selectedProvider.slogan && (
                       <div className="bg-blue-50/50 p-5 rounded-3xl border border-blue-100">
                          <p className="text-blue-800 font-bold italic text-sm">"{selectedProvider.slogan}"</p>
                       </div>
                     )}

                     {/* Validation History */}
                     {selectedProvider.validation_history?.length > 0 && (
                       <div className="space-y-3">
                          <p className="text-[10px] font-black text-slate-400 uppercase flex items-center gap-1"><FaClock /> Historique des validations</p>
                          <div className="space-y-2">
                             {selectedProvider.validation_history.map(h => (
                               <div key={h.id} className="p-3 bg-slate-50 rounded-2xl border border-slate-100">
                                  <div className="flex justify-between items-center mb-1">
                                     <span className={`text-[10px] font-black px-2 py-0.5 rounded-full ${h.status === 'validated' ? 'bg-emerald-100 text-emerald-600' : 'bg-rose-100 text-rose-600'}`}>
                                        {h.status === 'validated' ? 'VALIDÉ' : 'REJETÉ'}
                                     </span>
                                     <span className="text-[10px] text-slate-400 font-bold">{new Date(h.created_at).toLocaleDateString()}</span>
                                  </div>
                                  <p className="text-xs text-slate-600 italic">"{h.comment || 'Sans commentaire'}"</p>
                                  {h.admin && <p className="text-[9px] text-slate-400 mt-1 uppercase font-bold tracking-tighter">Par: {h.admin.name}</p>}
                               </div>
                             ))}
                          </div>
                       </div>
                     )}
                  </div>

                  {/* Sticky Action Footer / Approval Form */}
                  {activeTab === 'pending' && (
                    <div className="mt-8 pt-6 border-t border-slate-100 space-y-4">
                       <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                          <div>
                             <label className="text-[10px] font-black text-slate-400 uppercase mb-2 block">Date d'expiration (optionnel)</label>
                             <input 
                               type="date" 
                               value={validationExpiresAt}
                               onChange={(e) => setValidationExpiresAt(e.target.value)}
                               className="w-full px-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold focus:ring-2 focus:ring-blue-500 outline-none"
                             />
                          </div>
                          <div>
                             <label className="text-[10px] font-black text-slate-400 uppercase mb-2 block">Commentaire / Justification</label>
                             <textarea 
                               placeholder="Raison de la validation ou du rejet..."
                               value={validationComment}
                               onChange={(e) => setValidationComment(e.target.value)}
                               className="w-full px-4 py-2 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-medium focus:ring-2 focus:ring-blue-500 outline-none h-11"
                             />
                          </div>
                       </div>
                       
                       <div className="flex gap-4">
                          <button 
                           onClick={() => handleValidate(selectedProvider.id)}
                           className="flex-1 py-4 bg-emerald-500 text-white rounded-[1.5rem] font-black text-sm shadow-xl shadow-emerald-100 hover:bg-emerald-600 transition-all flex items-center justify-center gap-2"
                          >
                             <FaCheckCircle /> Valider le Dossier
                          </button>
                          <button 
                           onClick={() => handleReject(selectedProvider.id)}
                           className="px-6 py-4 bg-rose-50 text-rose-500 rounded-[1.5rem] font-black text-sm hover:bg-rose-500 hover:text-white transition-all flex items-center justify-center gap-2"
                          >
                             <FaTimesCircle /> Rejeter
                          </button>
                       </div>
                    </div>
                  )}
              </div>

           </div>
        </div>
      )}

    </div>
  );
};

export default ProviderValidation;
