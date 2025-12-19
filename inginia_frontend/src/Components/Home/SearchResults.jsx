import React, { useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";
import { getSearchResults, handleCategoryClick } from "../services/HomeService";
import { FaStar, FaCheckCircle, FaTimes } from "react-icons/fa";
import { MapContainer, TileLayer, Marker } from "react-leaflet";
import { useAuth } from "../Context/AuthContext";
import L from "leaflet";

// Définir l'icône pour les markers
const providerIcon = new L.Icon({
  iconUrl: "/images/provider_icon.jpg",
  iconSize: [25, 25],
  iconAnchor: [20, 40],
});

const SearchResults = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const queryParams = new URLSearchParams(location.search);
  const query = queryParams.get("query");
  const categoryId = queryParams.get("categoryId");
  const { user } = useAuth(); 
  const [providers, setProviders] = useState([]);
  const [category, setCategory] = useState(null);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({
    minPrice: 0,
    maxPrice: 100000,
    minRating: 0,
  });

  const [mapOverlay, setMapOverlay] = useState({
    show: false,
    coords: null,
    name: "",
  });

  useEffect(() => {
    if (!query && !categoryId) return;

    const fetchProviders = async () => {
      setLoading(true);
      try {
        if (categoryId) {
          const res = await handleCategoryClick(categoryId);
          setProviders(res.providers || []);
          setCategory(res.category || null);
        } else if (query) {
          const res = await getSearchResults(query);
          setProviders(res || []);
          setCategory(null);
        }
      } catch (err) {
        console.error("Erreur chargement prestataires :", err);
        setProviders([]);
      } finally {
        setLoading(false);
      }
    };
    fetchProviders();
  }, [query, categoryId]);

  const title = category
    ? `Résultats pour la catégorie ${category.name}`
    : query
    ? `Résultats pour "${query}"`
    : "Recherche invalide";

  const filteredProviders = providers.filter(
    (p) =>
      p.id !== user?.id &&
      (!filters.minPrice || p.min_price >= filters.minPrice) &&
      (!filters.maxPrice || p.min_price <= filters.maxPrice) &&
      (!filters.minRating || p.rating >= filters.minRating)
  );

  return (
    <section className="p-12 bg-gray-50 min-h-screen">
      <h2 className="text-3xl font-bold mb-6 text-center">{title}</h2>

      {/* Filtres */}
      <div className="flex gap-4 mb-8 justify-center flex-wrap">
        <input
          type="number"
          placeholder="Prix min"
          className="border rounded px-3 py-1 w-24"
          onChange={(e) => setFilters({ ...filters, minPrice: Number(e.target.value) })}
        />
        <input
          type="number"
          placeholder="Prix max"
          className="border rounded px-3 py-1 w-24"
          onChange={(e) => setFilters({ ...filters, maxPrice: Number(e.target.value) })}
        />
        <select
          className="border rounded px-3 py-1"
          onChange={(e) =>
            setFilters({ ...filters, minRating: Number(e.target.value) })
          }
        >
          <option value={0}>Toutes notes</option>
          <option value={1}>1★+</option>
          <option value={2}>2★+</option>
          <option value={3}>3★+</option>
          <option value={4}>4★+</option>
        </select>
      </div>

      {loading ? (
        <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <div
              key={i}
              className="bg-white shadow-lg rounded-xl p-6 flex flex-col items-center animate-pulse"
            >
              <Skeleton circle width={60} height={60} className="mb-4" />
              <Skeleton width={120} height={20} className="mb-2" />
              <Skeleton width={80} height={15} />
              <Skeleton width="100%" height={60} className="mt-4" />
            </div>
          ))}
        </div>
      ) : filteredProviders.length > 0 ? (
        <div className="flex flex-col gap-6">
          {filteredProviders.map((p) => (
            <div
              key={p.id}
              className="flex w-full bg-white rounded-2xl shadow-md overflow-hidden cursor-pointer hover:shadow-2xl hover:scale-105 transition-all duration-300"
            >
              {/* Image */}
              <div className="relative w-36 h-36 flex-shrink-0 m-2">
                <img
                  src={
                    p.photo
                      ? `http://localhost:8000/storage/profile_photos/${p.photo}`
                      : "/default-profile.png"
                  }
                  alt={p.nom}
                  className="w-full h-full object-cover rounded-xl"
                />
                {p.verifie && (
                  <span className="absolute top-1 left-1 bg-green-100 text-green-700 px-2 py-1 rounded text-xs flex items-center gap-1">
                    <FaCheckCircle /> Vérifié
                  </span>
                )}
              </div>

              {/* Infos */}
              <div className="w-64 flex-1 flex p-4 flex-col justify-between bg-gray-50">
                <div>
                  <div className="flex items-center justify-between mb-1">
                    <h3 className="text-lg font-bold text-gray-800">{p.name || p.service}</h3>
                    <span className="text-gray-500 text-sm">{p.location}</span>
                  </div>

                  {/* Rating */}
                  <div className="flex items-center gap-1 mb-2">
                    {[...Array(5)].map((_, i) => (
                      <FaStar
                        key={i}
                        className={i < Math.round(p.rating) ? "text-yellow-400" : "text-gray-300"}
                      />
                    ))}
                  </div>

                  {/* Description */}
                  <div className="flex gap-2 flex-wrap mb-4">
                      {p.professions?.map((prof) => (
                        <span
                          key={prof.id}
                          className="px-3 py-1 bg-blue-50 text-blue-700 rounded-full text-xs font-medium"
                        >
                          {prof.name}
                        </span>
                      ))}
                    </div>
                </div>

                <div className="flex items-center justify-between mt-2">
                  <p className="font-semibold text-blue-700">
                    {p.min_price ? `À partir de ${p.min_price.toLocaleString()} XOF` : "Tarif non renseigné"}
                  </p>
                  <button
                    className="px-3 py-1 bg-blue-600 text-white rounded-lg hover:bg-blue-500 transition"
                    onClick={() => navigate(`/provider/${p.id}`)}
                  >
                    Voir le profil
                  </button>
                </div>
              </div>

              {/* Mini-map */}
              {p.latitude != null && p.longitude != null && (
                <div
                  className="w-40 h-24 m-2 rounded-xl overflow-hidden cursor-pointer shadow-md"
                  onClick={(e) => {
                    e.stopPropagation();
                    setMapOverlay({
                      show: true,
                      coords: [p.latitude, p.longitude],
                      name: p.name,
                    });
                  }}
                >
                  <MapContainer
                    center={[p.latitude, p.longitude]}
                    zoom={13}
                    scrollWheelZoom={false}
                    dragging={false}
                    style={{ height: "100%", width: "100%" }}
                  >
                    <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
                    <Marker position={[p.latitude, p.longitude]} icon={providerIcon} />
                  </MapContainer>
                </div>
              )}
            </div>
          ))}
        </div>
      ) : (
        <p className="text-center text-gray-600">
          Aucun prestataire trouvé pour cette recherche.
        </p>
      )}

      {/* Overlay Map */}
      {mapOverlay.show && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
          onClick={() => setMapOverlay({ show: false, coords: null, name: "" })}
        >
          <div
            className="relative w-full max-w-2xl h-96 rounded-xl overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              className="absolute top-2 right-2 z-50 text-white bg-black bg-opacity-50 rounded-full p-2 hover:bg-opacity-75"
              onClick={() => setMapOverlay({ show: false, coords: null, name: "" })}
            >
              <FaTimes />
            </button>
            <MapContainer
              center={mapOverlay.coords}
              zoom={15}
              scrollWheelZoom={true}
              dragging={true}
              style={{ height: "100%", width: "100%" }}
            >
              <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
              <Marker position={mapOverlay.coords} icon={providerIcon} />
            </MapContainer>
          </div>
        </div>
      )}
    </section>
  );
};

export default SearchResults;
