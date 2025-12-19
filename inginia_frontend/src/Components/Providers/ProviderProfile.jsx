import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { useAuth } from "../Context/AuthContext";
import {
  getProviderDashboard,
  getReservationForProvider,
  getClientReservationsForProvider,
} from "../services/ProviderService";

import ReviewList from "./ProviderProfileSections/ReviewList";
import ReviewModal from "./ProviderProfileSections/ReviewModal";
import ReservationModal from "./ProviderProfileSections/ReservationModal";
import ChatModal from "./ProviderProfileSections/ChatModal";
import Alert from "./ProviderProfileSections/Alert";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";
import {
  FaStar,
  FaMapMarkerAlt,
  FaCheckCircle,
  FaShieldAlt,
  FaTrophy,
  FaClock,
  FaUserFriends,
  FaCamera,
  FaHeart,
  FaShareAlt,
  FaFlag,
} from "react-icons/fa";

const ProviderProfile = () => {
  const { id } = useParams();
  const { user } = useAuth();

  const [provider, setProvider] = useState(null);
  const [reviews, setReviews] = useState([]);
  const [reservation, setReservation] = useState(null);
  const [selectedReservation, setSelectedReservation] = useState(null);
  const [competances, setCompetances] = useState([]);

  const [loadingProvider, setLoadingProvider] = useState(true);
  const [loadingReviews, setLoadingReviews] = useState(true);

  const [clientHistory, setClientHistory] = useState([]);
  const [loadingHistory, setLoadingHistory] = useState(true);

  // Modals
  const [modal, setModal] = useState({
    review: false,
    reservation: false,
    chat: false,
  });
  // Alert
  const [showAlert, setShowAlert] = useState(false);

  // --- Fetch provider & reviews ---
  useEffect(() => {
    const fetchData = async () => {
      setLoadingProvider(true);
      const data = await getProviderDashboard(id);
      setProvider(data.provider);
      setCompetances(data.competances || []);
      setReviews(data.reviews || []);
      setLoadingProvider(false);
      setLoadingReviews(false);
    };
    fetchData();
  }, [id]);

  // --- Fetch reservation ---
  useEffect(() => {
    const fetchReservation = async () => {
      if (!id) return;
      const res = await getReservationForProvider(id);
      setReservation(res);
      setSelectedReservation(res);
    };
    fetchReservation();
  }, [id]);

  // --- Fetch client history for this provider ---
  useEffect(() => {
    const fetchHistory = async () => {
      if (!id || !user) return;
      setLoadingHistory(true);
      try {
        const history = await getClientReservationsForProvider(user.id, id);
        setClientHistory(history);
      } catch (err) {
        console.error(err);
      }
      setLoadingHistory(false);
    };
    fetchHistory();
  }, [id, user]);

  const getPhotoUrl = (p) =>
    p?.photo
      ? `http://localhost:8000/storage/profile_photos/${p.photo}`
      : "https://via.placeholder.com/150";

  // Mock Portfolio Images
  const portfolio = [
    "https://images.unsplash.com/photo-1581092921461-eab62e97a783?w=800&q=80",
    "https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=800&q=80",
    "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800&q=80",
    "https://images.unsplash.com/photo-1517048676732-d65bc937f952?w=800&q=80",
  ];

  if (loadingProvider) {
    return (
      <div className="max-w-7xl mx-auto p-8 space-y-8">
        <Skeleton height={300} borderRadius={20} />
        <div className="grid grid-cols-3 gap-8">
          <div className="col-span-2 space-y-4">
            <Skeleton count={5} />
          </div>
          <div className="col-span-1">
            <Skeleton height={400} />
          </div>
        </div>
      </div>
    );
  }

  if (!provider)
    return (
      <div className="text-center p-20 text-xl font-bold text-gray-400">
        Prestataire introuvable 🕵️‍♂️
      </div>
    );

  return (
    <div className="bg-white min-h-screen text-gray-800 font-sans pb-20">
      {/* --- HEADER SECTION : PHOTOS --- */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 pt-6">
        <div className="flex justify-between items-start mb-4">
          <h1 className="text-3xl sm:text-4xl font-extrabold text-gray-900">
            {provider.name}
          </h1>
          <div className="flex gap-4">
            <button className="flex items-center gap-2 text-sm font-semibold hover:bg-gray-100 px-4 py-2 rounded-full transition">
              <FaShareAlt /> Partager
            </button>
            <button className="flex items-center gap-2 text-sm font-semibold hover:bg-gray-100 px-4 py-2 rounded-full transition">
              <FaHeart className="text-gray-400 hover:text-red-500" />{" "}
              Sauvegarder
            </button>
          </div>
        </div>

        <div className="flex items-center gap-2 text-sm text-gray-500 mb-6 font-medium">
          <FaStar className="text-yellow-500" />
          <span className="text-black font-bold">
            {Number(provider.rating || 0).toFixed(2)}
          </span>
          <span className="underline cursor-pointer hover:text-black">
            ({reviews.length} avis)
          </span>
          <span>•</span>
          <span className="flex items-center gap-1 text-gray-700 underline cursor-pointer hover:text-black font-semibold">
            <FaMapMarkerAlt /> {provider.location || "Abidjan, Côte d'Ivoire"}
          </span>
          {provider.verified_at && (
            <span className="flex items-center gap-1 text-green-700 bg-green-50 px-2 py-0.5 rounded-full text-xs font-bold ml-2">
              <FaShieldAlt /> Identité vérifiée
            </span>
          )}
        </div>

        {/* Photo Gallery Grid (Airbnb Style) */}
        <div className="grid grid-cols-4 grid-rows-2 gap-2 h-[400px] rounded-3xl overflow-hidden shadow-sm relative group cursor-pointer">
          {/* Main Photo (Profile or Portfolio 1) */}
          <div className="col-span-2 row-span-2 overflow-hidden">
            <img
              src={getPhotoUrl(provider)}
              className="w-full h-full object-cover transition duration-500 group-hover:scale-105"
              alt="Main"
            />
          </div>
          {/* Secondary Photos */}
          {portfolio.map((img, i) => (
            <div key={i} className="overflow-hidden bg-gray-100">
              <img
                src={img}
                className="w-full h-full object-cover transition duration-500 group-hover:scale-105"
                alt={`Portfolio ${i}`}
              />
            </div>
          ))}
          <button className="absolute bottom-4 right-4 bg-white/90 backdrop-blur-sm px-4 py-2 rounded-lg text-sm font-bold shadow-md flex items-center gap-2 hover:bg-white transition">
            <FaCamera /> Afficher toutes les photos
          </button>
        </div>
      </div>

      {/* --- CONTENT GRID --- */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 grid grid-cols-1 lg:grid-cols-3 gap-16 mt-12 relative">
        {/* LEFT COL: DETAILS */}
        <div className="lg:col-span-2 space-y-12">
          {/* Bio & Badges */}
          <div className="pb-8 border-b border-gray-200">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-2xl font-bold mb-1">
                  Prestataire chez Inginia
                </h2>
                <p className="text-gray-500">
                  Membre depuis{" "}
                  {new Date(provider.created_at || Date.now()).getFullYear()}
                </p>
              </div>
              <img
                src={getPhotoUrl(provider)}
                className="w-16 h-16 rounded-full object-cover shadow-md"
                alt="Avatar"
              />
            </div>

            {/* Highlights */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-6">
              <div className="flex gap-4 items-start">
                <FaTrophy className="text-2xl text-yellow-500 mt-1" />
                <div>
                  <h3 className="font-bold text-gray-900">
                    Expertise Confirmée
                  </h3>
                  <p className="text-sm text-gray-500">
                    Un des experts les mieux notés de sa catégorie.
                  </p>
                </div>
              </div>
              <div className="flex gap-4 items-start">
                <FaClock className="text-2xl text-blue-500 mt-1" />
                <div>
                  <h3 className="font-bold text-gray-900">Réponse Rapide</h3>
                  <p className="text-sm text-gray-500">
                    Répond généralement en moins d'une heure.
                  </p>
                </div>
              </div>
            </div>

            <div className="bg-gray-50 p-6 rounded-2xl border border-gray-100">
              <p className="text-gray-700 leading-relaxed text-lg">
                {provider.slogan ? `"${provider.slogan}"` : ""} <br />
                {provider.description ||
                  "Aucune description détaillée n'a été fournie pour le moment. Contactez le prestataire pour en savoir plus sur ses services et disponibilités."}
              </p>
            </div>
          </div>

          {/* Services List */}
          <div className="pb-8 border-b border-gray-200">
            <h2 className="text-2xl font-bold mb-6">Services proposés</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {competances.map((c) => (
                <div
                  key={c.id}
                  className="border border-gray-200 p-4 rounded-xl hover:shadow-md transition flex justify-between items-center"
                >
                  <div>
                    <h4 className="font-bold text-lg">{c.title}</h4>
                    <p className="text-sm text-gray-500 line-clamp-1">
                      {c.description}
                    </p>
                  </div>
                  <span className="bg-gray-900 text-white px-3 py-1 rounded-lg text-sm font-bold">
                    {c.price} F
                  </span>
                </div>
              ))}
              {competances.length === 0 && (
                <p className="text-gray-400 italic">
                  Aucun service spécifique listé.
                </p>
              )}
            </div>
          </div>

          {/* History */}
          {clientHistory.length > 0 && (
            <div className="pb-8 border-b border-gray-200">
              <h2 className="text-2xl font-bold mb-6">
                Vos réservations passées
              </h2>
              <div className="bg-gray-50 p-6 rounded-2xl">
                <div className="space-y-4">
                  {clientHistory.slice(0, 3).map((h) => (
                    <div
                      key={h.id}
                      className="flex justify-between items-center bg-white p-3 rounded-xl border border-gray-200"
                    >
                      <div className="flex items-center gap-3">
                        <div
                          className={`w-2 h-12 rounded-full ${
                            h.status === "completed"
                              ? "bg-green-500"
                              : "bg-gray-300"
                          }`}
                        ></div>
                        <div>
                          <p className="font-bold text-sm">
                            {new Date(h.requested_date).toLocaleDateString()}
                          </p>
                          <p className="text-xs text-gray-500">
                            {h.other_service || "Service"}
                          </p>
                        </div>
                      </div>
                      <span className="text-xs font-bold uppercase tracking-wider text-gray-400">
                        {h.status}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Reviews */}
          <div>
            <h2 className="text-2xl font-bold mb-6 flex items-center gap-2">
              ★ {Number(provider.rating || 0).toFixed(2)} · {reviews.length}{" "}
              avis
            </h2>
            <ReviewList reviews={reviews} loading={loadingReviews} />
            <button
              onClick={() => setModal({ ...modal, review: true })}
              className="mt-8 border border-black px-6 py-3 rounded-xl font-bold hover:bg-gray-50 transition w-full md:w-auto"
            >
              Écrire un avis
            </button>
          </div>
        </div>

        {/* RIGHT COL: STICKY SIDEBAR */}
        <div>
          <div className="sticky top-28 bg-white border border-gray-200 shadow-xl rounded-2xl p-6 lg:ml-8">
            <div className="flex justify-between items-end mb-6">
              <div>
                <span className="text-3xl font-bold text-gray-900">
                  {provider.min_price ? `${provider.min_price} F` : "Tarif"}
                </span>
                <span className="text-gray-500 text-lg"> / service</span>
              </div>
              <div className="flex items-center gap-1 text-sm font-semibold">
                <FaStar className="text-yellow-500" />{" "}
                {Number(provider.rating || 0).toFixed(1)}
              </div>
            </div>

            <div className="border border-gray-300 rounded-xl mb-6 overflow-hidden">
              <div className="p-3 border-b border-gray-300 bg-gray-50">
                <label className="text-[10px] uppercase font-bold text-gray-500 tracking-wider">
                  PRESTATAIRE
                </label>
                <div className="font-semibold text-gray-700 truncate">
                  {provider.name}
                </div>
              </div>
              <div className="p-3">
                <label className="text-[10px] uppercase font-bold text-gray-500 tracking-wider">
                  DISPONIBILITÉ
                </label>
                <div className="font-semibold text-green-600 flex items-center gap-1">
                  <FaCheckCircle /> Disponible aujourd'hui
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            {!selectedReservation ||
            ["completed", "declined"].includes(selectedReservation.status) ? (
              <button
                onClick={() => setModal({ ...modal, reservation: true })}
                className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-bold py-4 rounded-xl text-lg shadow-lg hover:shadow-xl transition transform active:scale-95 mb-3"
              >
                Réserver maintenant
              </button>
            ) : (
              <button
                onClick={() => setModal({ ...modal, chat: true })}
                className="w-full bg-black text-white hover:bg-gray-800 font-bold py-4 rounded-xl text-lg shadow-lg transition transform active:scale-95 mb-3 flex items-center justify-center gap-2"
              >
                <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>{" "}
                Ouvrir le Chat
              </button>
            )}

            <p className="text-center text-xs text-gray-400 mt-2">
              Aucun débit avant la validation du devis.
            </p>

            <div className="mt-6 pt-6 border-t border-gray-100 flex justify-between text-gray-500 text-sm">
              <span
                className="flex items-center gap-2"
                title="Signaler ce profil"
              >
                <FaFlag /> Signaler
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Modals */}
      {modal.review && (
        <ReviewModal
          providerId={id}
          closeModal={() => setModal({ ...modal, review: false })}
          refreshReviews={(data) => setReviews(data.reviews)}
        />
      )}

      {modal.reservation && (
        <ReservationModal
          provider={provider}
          competances={competances}
          user={user}
          selectedReservation={selectedReservation}
          closeModal={() => setModal({ ...modal, reservation: false })}
          onReservationSuccess={(res) => {
            setSelectedReservation(res);
            setShowAlert(true);
          }}
        />
      )}

      {modal.chat && selectedReservation && (
        <ChatModal
          provider={provider}
          reservation={selectedReservation}
          user={user}
          closeModal={() => setModal({ ...modal, chat: false })}
        />
      )}

      {/* Alert */}
      {showAlert && (
        <Alert
          message={`✅ Demande envoyée ! ${provider.name} a été notifié.`}
          close={() => setShowAlert(false)}
        />
      )}
    </div>
  );
};

export default ProviderProfile;
