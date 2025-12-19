import { FaStar } from "react-icons/fa";
import Skeleton from "./Skeleton";

const ProfileCard = ({
  provider,
  user,
  loading,
  selectedReservation,
  openModal,
}) => {
  const averageRating = Number(provider?.rating) || 0;

  const getPhotoUrl = (p) =>
    p?.photo
      ? `http://localhost:8000/storage/profile_photos/${p.photo}`
      : "https://via.placeholder.com/150";

  if (loading) {
    return (
      <div className="flex flex-col md:flex-row gap-6 bg-white p-6 rounded-2xl shadow-lg border border-gray-100 mb-8">
        <Skeleton width="120px" height="120px" className="rounded-full" />
        <div className="flex-1 space-y-3">
          <Skeleton width="50%" height="28px" />
          <Skeleton width="70%" height="18px" />
        </div>
      </div>
    );
  }

  if (!provider)
    return <p className="text-gray-500">Prestataire introuvable</p>;

  return (
    <div className="flex flex-col md:flex-row gap-6 bg-white p-6 rounded-2xl shadow-lg border border-gray-100 mb-8">
      <img
        src={getPhotoUrl(provider)}
        alt={provider?.name}
        className="h-28 w-28 rounded-full object-cover border-4 border-blue-100"
      />
      <div className="flex-1 space-y-3">
        <h2 className="text-3xl font-bold text-gray-800">{provider.name}</h2>
        <p className="text-gray-500 flex items-center gap-1">
          📍 {provider.location || "Localisation inconnue"}
        </p>
        <div className="flex flex-wrap gap-2 mt-2">
          {Array.isArray(provider.professions) &&
            provider.professions.map((p) => (
              <span
                key={p.id}
                className="px-3 py-1 bg-blue-50 text-blue-700 border border-blue-200 rounded-full text-sm font-medium"
              >
                {p.name}
              </span>
            ))}
          {provider.service_name && (
            <span className="px-3 py-1 bg-blue-50 text-blue-700 border border-blue-200 rounded-full text-sm font-medium">
              {provider.service_name}
            </span>
          )}
        </div>

        {provider.slogan && (
          <p className="text-gray-600 italic">{provider.slogan}</p>
        )}
        {provider.min_price && (
          <p className="font-semibold text-gray-800">
            À partir de {provider.min_price} XOF
          </p>
        )}
        <div className="flex items-center mt-2">
          {[1, 2, 3, 4, 5].map((i) => (
            <FaStar
              key={i}
              className={`mr-1 ${
                i <= Math.round(averageRating)
                  ? "text-yellow-400"
                  : "text-gray-300"
              }`}
            />
          ))}
          <span className="ml-2 text-gray-700 font-medium">
            {averageRating.toFixed(1)} / 5
          </span>
        </div>
        {user && (
          <div className="flex gap-4 mt-4">
            <button
              className="flex-1 px-6 py-2 bg-green-600 text-white rounded-xl hover:bg-green-500 transition font-semibold"
              onClick={() => openModal("review")}
            >
              Laisser un avis
            </button>
            {!selectedReservation || selectedReservation.status === "completed" || selectedReservation.status === "declined" ? (
      <button
        className="flex-1 px-6 py-2 bg-indigo-600 text-white rounded-xl hover:bg-indigo-500 transition font-semibold"
        onClick={() => openModal("reservation")}
      >
        Réserver
      </button>
    ) : (
      <button
        className="flex-1 px-6 py-2 bg-indigo-600 text-white rounded-xl hover:bg-indigo-500 transition font-semibold"
        onClick={() => openModal("chat")}
      >
        Chat
      </button>
    )}
          </div>
        )}
      </div>
    </div>
  );
};

export default ProfileCard;
