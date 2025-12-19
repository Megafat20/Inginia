import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  FaStar,
  FaCheckCircle,
  FaUsers,
  FaTools,
  FaMapMarkerAlt,
  FaRocket,
} from "react-icons/fa";
import { useAuth } from "../Context/AuthContext";
import {
  getPopularProviders,
  getPopularCategories,
  handleCategoryClick,
  recommands,
  recommands2,
} from "../services/HomeService";
import CategoriesSection from "./CategoriesSection";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";
import HomeSearch from "./HomeSearch";

const Home = () => {
  const navigate = useNavigate();
  const { user } = useAuth();

  const [popularProviders, setPopularProviders] = useState([]);
  const [categories, setCategories] = useState([]);
  const [recommendedProviders, setRecommendedProviders] = useState([]);
  const [loadingProviders, setLoadingProviders] = useState(true);
  const [loadingCategories, setLoadingCategories] = useState(true);
  const [loadingRecommended, setLoadingRecommended] = useState(true);
  const [userLocation, setUserLocation] = useState({ lat: null, lng: null });
  const [need, setNeed] = useState("");
  const [showToast, setShowToast] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      setLoadingProviders(true);
      const providers = await getPopularProviders();
      setPopularProviders(
        user ? providers.filter((p) => p.id !== user.id) : providers
      );
      setLoadingProviders(false);

      setLoadingCategories(true);
      const cats = await getPopularCategories();
      setCategories(cats);
      setLoadingCategories(false);
    };
    fetchData();
  }, [user]);

  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) =>
          setUserLocation({
            lat: pos.coords.latitude,
            lng: pos.coords.longitude,
          }),
        (err) => console.error("Erreur localisation :", err)
      );
    }
  }, []);

  useEffect(() => {
    const fetchRecommended = async () => {
      if (!userLocation.lat || !userLocation.lng) return;
      setLoadingRecommended(true);
      let providers;
      if (need) {
        providers = await recommands2(userLocation.lat, userLocation.lng, need);
      } else {
        providers = await recommands(userLocation.lat, userLocation.lng);
      }
      setRecommendedProviders(
        user ? providers.filter((p) => p.id !== user.id) : providers
      );
      setLoadingRecommended(false);
    };
    fetchRecommended();
  }, [userLocation, need, user]);

  const formatXOF = (value) => `${value.toLocaleString()} XOF`;

  const handleViewProfile = (p) => {
    if (!user) {
      setShowToast(true);
      setTimeout(() => setShowToast(false), 3000);
      return;
    }
    navigate(`/provider/${p.id}`);
  };

  return (
    <div className="overflow-x-hidden pt-4">
      {/* Toast */}
      {showToast && (
        <div className="fixed top-24 right-4 bg-indigo-600/90 backdrop-blur-md text-white px-6 py-4 rounded-2xl shadow-2xl z-[100] animate-bounceIn flex items-center gap-3 border border-white/20">
          <FaUsers className="text-xl" />
          <span className="font-semibold text-sm">
            Connectez-vous pour accéder à plus de fonctionnalités
          </span>
        </div>
      )}

      {/* Hero Section - Redesigned */}
      <section className="relative min-h-[85vh] flex items-center justify-center px-6 overflow-hidden">
        {/* Animated Background Elements */}
        <div className="absolute top-0 left-0 w-full h-full -z-10 bg-slate-50">
          <div className="absolute top-1/4 -left-12 w-64 h-64 bg-blue-400/20 rounded-full blur-[100px] animate-pulse"></div>
          <div className="absolute bottom-1/4 -right-12 w-80 h-80 bg-indigo-400/20 rounded-full blur-[100px] animate-pulse delay-1000"></div>
        </div>

        <div className="max-w-5xl mx-auto text-center relative z-10">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-blue-50 text-blue-600 text-xs font-bold tracking-widest uppercase mb-8 animate-fadeIn">
            <FaRocket className="animate-bounce" /> L'Ingénierie à votre Service
          </div>
          <h1 className="text-5xl md:text-7xl font-extrabold mb-8 leading-tight tracking-tight text-slate-900 animate-slideUp">
            Le talent local, <br />
            <span className="bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
              au bon moment.
            </span>
          </h1>
          <p className="text-xl text-slate-600 mb-12 max-w-2xl mx-auto animate-slideUp delay-200">
            Simplifiez vos besoins quotidiens avec la première plateforme de
            mise en relation de services premium au Sénégal.
          </p>

          <div className="scale-105 md:scale-110 lg:scale-125 mb-16 animate-bounceIn delay-300">
            <HomeSearch />
          </div>

          {/* Key Stats / Trust */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mt-12 animate-fadeIn delay-500">
            <div className="flex flex-col items-center">
              <span className="text-2xl font-black text-slate-800">15k+</span>
              <span className="text-xs text-slate-400 font-bold uppercase tracking-tighter">
                Experts
              </span>
            </div>
            <div className="flex flex-col items-center">
              <span className="text-2xl font-black text-slate-800">98%</span>
              <span className="text-xs text-slate-400 font-bold uppercase tracking-tighter">
                Satisfaction
              </span>
            </div>
            <div className="flex flex-col items-center">
              <span className="text-2xl font-black text-slate-800">45+</span>
              <span className="text-xs text-slate-400 font-bold uppercase tracking-tighter">
                Villes
              </span>
            </div>
            <div className="flex flex-col items-center">
              <span className="text-2xl font-black text-slate-800">24/7</span>
              <span className="text-xs text-slate-400 font-bold uppercase tracking-tighter">
                Support
              </span>
            </div>
          </div>
        </div>
      </section>

      {/* Categories Section - Now integrated as a slider/grid */}
      <section className="py-24 relative">
        <div className="max-w-full mx-auto px-6">
          <div className="flex flex-col md:flex-row items-end justify-between mb-12 gap-6">
            <div className="text-left">
              <h2 className="text-3xl font-extrabold text-slate-900 mb-2">
                Services <span className="text-blue-600">Populaires</span>
              </h2>
              <p className="text-slate-500 font-medium">
                Parcourez les catégories les plus demandées en ce moment.
              </p>
            </div>
            <button
              onClick={() => navigate("/search")}
              className="text-blue-600 font-bold text-sm hover:underline decoration-2 underline-offset-4 flex items-center gap-2"
            >
              Voir tout <FaTools />
            </button>
          </div>
          <CategoriesSection />
        </div>
      </section>

      {/* Recommended Providers - Visual Cards Overhaul */}
      <section className="py-24 bg-white">
        <div className="max-w-full mx-auto px-6">
          <div className="text-center md:text-left mb-16">
            <div className="flex items-center gap-2 text-blue-600 font-bold text-xs uppercase tracking-widest mb-3">
              <FaMapMarkerAlt /> Recommandations Locales
            </div>
            <h2 className="text-4xl font-extrabold text-slate-900">
              Basés sur <span className="text-blue-600">votre position</span>
            </h2>
          </div>

          {!user ? (
            <div className="relative overflow-hidden p-12 rounded-3xl bg-slate-900 text-white flex flex-col items-center text-center shadow-2xl">
              <div className="absolute top-0 left-0 w-full h-full -z-10 opacity-20">
                <img
                  src="https://images.unsplash.com/photo-1521737711867-e3b97375f902?auto=format&fit=crop&q=80"
                  alt=""
                  className="w-full h-full object-cover"
                />
              </div>
              <p className="text-2xl font-bold mb-6">
                🔒 Débloquez vos recommandations personnalisées
              </p>
              <button
                onClick={() => navigate("/login")}
                className="px-10 py-4 bg-blue-600 text-white font-bold rounded-full shadow-lg shadow-blue-500/30 hover:bg-blue-500 transition-all hover:scale-105"
              >
                Se connecter maintenant
              </button>
            </div>
          ) : loadingRecommended ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
              {Array.from({ length: 3 }).map((_, i) => (
                <div
                  key={i}
                  className="rounded-3xl overflow-hidden bg-slate-100 p-4 h-80"
                >
                  <Skeleton height="100%" className="rounded-2xl" />
                </div>
              ))}
            </div>
          ) : recommendedProviders.length === 0 ? (
            <div className="p-12 text-center rounded-3xl bg-slate-50 text-slate-400 font-medium border-2 border-dashed border-slate-200">
              Aucun prestataire trouvé près de vous actuellement.
            </div>
          ) : (
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-8">
              {recommendedProviders.map((p) => (
                <div
                  key={p.id}
                  onClick={() => navigate(`/provider/${p.id}`)}
                  className="group relative h-[450px] rounded-[2.5rem] overflow-hidden cursor-pointer shadow-xl transition-all duration-500 hover:shadow-2xl hover:-translate-y-2"
                >
                  <img
                    src={
                      p.photo
                        ? `http://localhost:8000/storage/profile_photos/${p.photo}`
                        : "/default-profile.png"
                    }
                    className="absolute inset-0 h-full w-full object-cover transition-transform duration-700 group-hover:scale-110"
                    alt={p.name}
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-slate-900 via-slate-900/40 to-transparent"></div>

                  <div className="absolute top-6 right-6">
                    <div className="px-4 py-2 bg-white/10 backdrop-blur-md rounded-full border border-white/20 text-white text-xs font-bold flex items-center gap-2">
                      <FaStar className="text-yellow-400" /> {p.rating}
                    </div>
                  </div>

                  <div className="absolute bottom-10 left-8 right-8 text-white">
                    <p className="text-blue-400 text-xs font-black uppercase tracking-widest mb-2">
                      {p.professions?.[0]?.name || "Expert Inginia"}
                    </p>
                    <h3 className="text-2xl font-bold mb-4">
                      {p.name || p.service}
                    </h3>
                    <div className="flex items-center gap-6">
                      <div className="text-xs font-bold opacity-80 uppercase tracking-tighter">
                        À PROXIMITÉ • {p.location}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </section>

      {/* Popular Providers - Card View */}
      <section className="py-24 bg-slate-50 relative overflow-hidden">
        <div className="absolute -top-24 -right-24 w-96 h-96 bg-blue-100 rounded-full blur-[120px] -z-10"></div>
        <div className="max-w-full mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-extrabold text-slate-900 mb-4">
              La crème de la <span className="text-blue-600">crème</span>
            </h2>
            <p className="text-slate-500 max-w-xl mx-auto">
              Nos partenaires les mieux notés, rigoureusement sélectionnés pour
              leur excellence.
            </p>
          </div>

          <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
            {loadingProviders
              ? Array.from({ length: 6 }).map((_, i) => (
                  <div
                    key={i}
                    className="bg-white rounded-[2rem] p-6 shadow-sm"
                  >
                    <Skeleton height={200} className="rounded-xl" />
                  </div>
                ))
              : popularProviders.map((p) => (
                  <div
                    key={p.id}
                    onClick={() => navigate(`/provider/${p.id}`)}
                    className="bg-white rounded-[2.5rem] p-4 shadow-sm border border-slate-100 
                             group hover:shadow-2xl transition-all duration-500 cursor-pointer"
                  >
                    <div className="relative h-64 rounded-[2rem] overflow-hidden mb-6">
                      <img
                        src={
                          p.photo
                            ? `http://localhost:8000/storage/profile_photos/${p.photo}`
                            : "/default-profile.png"
                        }
                        className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                        alt={p.name}
                      />
                      {p.verifie && (
                        <div className="absolute top-4 left-4 bg-white/90 backdrop-blur shadow-sm px-4 py-2 rounded-full flex items-center gap-2">
                          <FaCheckCircle className="text-blue-600 text-sm" />
                          <span className="text-[10px] font-black uppercase tracking-widest text-slate-800">
                            Vérifié
                          </span>
                        </div>
                      )}
                    </div>

                    <div className="px-4 pb-4">
                      <div className="flex justify-between items-start mb-4">
                        <div>
                          <h3 className="font-extrabold text-xl text-slate-900 truncate mb-1">
                            {p.name || p.service}
                          </h3>
                          <p className="text-slate-400 text-sm flex items-center gap-1 font-medium">
                            <FaMapMarkerAlt size={10} /> {p.location}
                          </p>
                        </div>
                        <div className="text-right">
                          <div className="flex items-center gap-1 text-yellow-500 font-bold mb-1">
                            <FaStar size={14} /> {p.rating}
                          </div>
                          <p className="text-[10px] text-slate-300 font-bold uppercase tracking-tighter">
                            ({p.reviews_received_count} Avis)
                          </p>
                        </div>
                      </div>

                      <div className="flex flex-wrap gap-2 mb-8 h-12 overflow-hidden">
                        {p.professions?.map((prof) => (
                          <span
                            key={prof.id}
                            className="px-3 py-1.5 bg-slate-50 text-slate-500 rounded-full text-[10px] font-black uppercase tracking-widest group-hover:bg-blue-50 group-hover:text-blue-600 transition-colors"
                          >
                            {prof.name}
                          </span>
                        ))}
                      </div>

                      <div className="flex items-center justify-between pt-6 border-t border-slate-50">
                        <div>
                          <p className="text-[10px] font-black text-slate-300 uppercase tracking-widest mb-1">
                            À partir de
                          </p>
                          <p className="text-lg font-black text-slate-900">
                            {p.min_price ? formatXOF(p.min_price) : "Sur devis"}
                          </p>
                        </div>
                        <button
                          className="w-12 h-12 rounded-2xl bg-slate-900 text-white flex items-center justify-center group-hover:bg-blue-600 group-hover:scale-110 transition-all shadow-lg shadow-slate-200 group-hover:shadow-blue-200"
                          onClick={(e) => {
                            e.stopPropagation();
                            handleViewProfile(p);
                          }}
                        >
                          <FaRocket size={18} />
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
          </div>
        </div>
      </section>

      <style>{`
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes slideUp { from { opacity: 0; transform: translateY(40px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes bounceIn { 
          0% { transform: scale(0.95); opacity: 0; } 
          60% { transform: scale(1.02); } 
          100% { transform: scale(1); opacity: 1; } 
        }
        .animate-fadeIn { animation: fadeIn 0.8s ease-out forwards; }
        .animate-slideUp { animation: slideUp 0.8s cubic-bezier(0.25, 1, 0.5, 1) forwards; }
        .animate-bounceIn { animation: bounceIn 0.7s cubic-bezier(0.34, 1.56, 0.64, 1) forwards; }
        .delay-200 { animation-delay: 0.2s; }
        .delay-300 { animation-delay: 0.35s; }
        .delay-500 { animation-delay: 0.5s; }
        .delay-1000 { animation-delay: 1s; }
      `}</style>
    </div>
  );
};

export default Home;
