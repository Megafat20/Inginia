import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { register } from "../services/AuthService";
import { getProfessions } from "../services/ProviderService";
import Logo from "../Logo";
const Register = () => {
  const navigate = useNavigate();
  const [professions, setProfessions] = useState([]);
  const [selectedType, setSelectedType] = useState("client");
  const [coords, setCoords] = useState({ lat: null, lng: null });
  const [formData, setFormData] = useState({
    nom: "",
    prenom: "",
    service: "",
    email: "",
    password: "",
    telephone: "",
    profession_ids: [],
    location: "",
    adresse: "",
    profile_photo: null,
    min_price: "",
    slogan: "",
    is_agency: false,
  });
  const [previewPhoto, setPreviewPhoto] = useState(null);
  const [error, setError] = useState("");

  useEffect(() => {
    if (selectedType === "prestataire") {
      getProfessions()
        .then((data) => setProfessions(data))
        .catch((err) => console.error("Erreur professions :", err));
    }
  }, [selectedType]);

  useEffect(() => {
    if (selectedType === "prestataire" && navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) =>
          setCoords({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
        (err) => console.warn("Géolocalisation indisponible :", err)
      );
    }
  }, [selectedType]);

  const handleChange = (e) => {
    const { name, value, type, checked, files } = e.target;
    if (type === "file") {
      const file = files[0];
      setFormData({ ...formData, profile_photo: file });
      if (file) setPreviewPhoto(URL.createObjectURL(file));
    } else if (type === "checkbox") {
      setFormData({ ...formData, [name]: checked });
    } else {
      setFormData({ ...formData, [name]: value });
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const form = new FormData();

      if (selectedType === "client") {
        form.append("name", formData.nom.trim() + " " + formData.prenom.trim());
        form.append("role", "client");
      } else {
        if (formData.is_agency) {
          form.append("service", formData.service);
        } else {
          form.append(
            "name",
            formData.nom.trim() + " " + formData.prenom.trim()
          );
        }
        form.append("role", "prestataire");
        formData.profession_ids?.forEach((id) =>
          form.append("profession_ids[]", id)
        );
        form.append("location", formData.location || "");
        form.append("adresse", formData.adresse || "");
        form.append("min_price", formData.min_price);
        form.append("slogan", formData.slogan);
        form.append("latitude", coords.lat);
        form.append("longitude", coords.lng);
        form.append("is_agency", formData.is_agency ? 1 : 0);
        if (formData.profile_photo)
          form.append("profile_photo", formData.profile_photo);
      }

      form.append("email", formData.email.trim());
      form.append("password", formData.password);
      form.append("phone", formData.telephone || "");

      await register(form, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      alert("Inscription réussie !");
      navigate("/login");
    } catch (err) {
      console.error("Erreur inscription :", err.response?.data || err);
      if (err.response?.status === 422) {
        const messages = Object.values(err.response.data.errors)
          .flat()
          .join(" ");
        setError(messages);
      } else {
        setError("Erreur serveur, réessayez plus tard.");
      }
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 via-white to-indigo-100 p-6">
      <div className="bg-white shadow-2xl rounded-3xl w-full max-w-7xl flex overflow-hidden">
        <div className="hidden md:flex w-2/6 bg-indigo-600 flex-col justify-center items-center p-10 text-white">
          <Logo />
          <h3 className="text-3xl font-bold mb-4 mt-3">Bienvenue sur Inginia</h3>
          <p className="text-lg mb-6 text-center">
            Connectez clients et prestataires facilement et rapidement.
          </p>
          <button
            // onClick={handleGoogleSignIn}
            className="flex items-center gap-3 bg-white text-indigo-600 font-semibold px-6 py-3 rounded-lg shadow hover:bg-gray-100 transition"
          >
            <img
              src="/images/google_icon.png"
              alt="Google"
              className="w-6 h-6"
            />
            Continuer avec Google
          </button>
        </div>
        <div className="w-full md:w-4/6 p-10">
          <h2 className="text-4xl font-extrabold text-center text-indigo-700 mb-4">
            Créer un compte
          </h2>
          <p className="text-center text-gray-500 mb-8">
            Rejoignez notre plateforme et commencez dès aujourd'hui 🚀
          </p>

          {error && (
            <div className="bg-red-100 text-red-700 p-3 rounded-xl mb-6 text-center font-medium">
              {error}
            </div>
          )}

          {/* Choix du type */}
          <div className="flex justify-center gap-6 mb-8">
            {["client", "prestataire"].map((type) => (
              <button
                key={type}
                onClick={() => setSelectedType(type)}
                className={`px-8 py-3 rounded-full font-semibold capitalize transition-all duration-300
                ${
                  selectedType === type
                    ? "bg-indigo-600 text-white shadow-lg scale-105"
                    : "bg-gray-100 text-gray-700 hover:bg-gray-200"
                }`}
              >
                {type}
              </button>
            ))}
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Client */}
            {selectedType === "client" && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-gray-700 font-medium mb-1">
                    Nom
                  </label>
                  <input
                    type="text"
                    name="nom"
                    placeholder="Nom"
                    value={formData.nom}
                    onChange={handleChange}
                    className="w-full border border-gray-300 rounded-lg p-3 text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 shadow-sm"
                    required
                  />
                </div>
                <div>
                  <label className="block text-gray-700 font-medium mb-1">
                    Prénom
                  </label>
                  <input
                    type="text"
                    name="prenom"
                    placeholder="Prénom"
                    value={formData.prenom}
                    onChange={handleChange}
                    className="w-full border border-gray-300 rounded-lg p-3 text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 shadow-sm"
                    required
                  />
                </div>
              </div>
            )}

            {/* Prestataire */}
            {selectedType === "prestataire" && (
              <>
                <div className="flex items-center gap-3">
                  <input
                    type="checkbox"
                    name="is_agency"
                    checked={formData.is_agency}
                    onChange={handleChange}
                    id="is_agency"
                    className="w-5 h-5 text-indigo-600"
                  />
                  <label
                    htmlFor="is_agency"
                    className="text-gray-700 font-medium"
                  >
                    Je suis une agence
                  </label>
                </div>

                {!formData.is_agency ? (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-gray-700 font-medium mb-1">
                        Nom
                      </label>
                      <input
                        type="text"
                        name="nom"
                        placeholder="Nom"
                        value={formData.nom}
                        onChange={handleChange}
                        className="w-full border border-gray-300 rounded-lg p-3 text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 shadow-sm"
                        required
                      />
                    </div>
                    <div>
                      <label className="block text-gray-700 font-medium mb-1">
                        Prénom
                      </label>
                      <input
                        type="text"
                        name="prenom"
                        placeholder="Prénom"
                        value={formData.prenom}
                        onChange={handleChange}
                        className="w-full border border-gray-300 rounded-lg p-3 text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 shadow-sm"
                        required
                      />
                    </div>
                  </div>
                ) : (
                  <div>
                    <label className="block text-gray-700 font-medium mb-1">
                      Nom du service
                    </label>
                    <input
                      type="text"
                      name="service"
                      placeholder="Nom du service"
                      value={formData.service}
                      onChange={handleChange}
                      className="w-full border border-gray-300 rounded-lg p-3 text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 shadow-sm"
                      required
                    />
                  </div>
                )}

                {/* Professions */}
                <div>
                  <label className="block mb-2 font-semibold text-gray-700">
                    Sélectionnez vos professions
                  </label>
                  <div className="flex flex-wrap gap-2">
                    {professions.map((p) => {
                      const selected = formData.profession_ids.includes(
                        p.id.toString()
                      );
                      return (
                        <button
                          type="button"
                          key={p.id}
                          onClick={() => {
                            const ids = formData.profession_ids || [];
                            if (selected) {
                              setFormData({
                                ...formData,
                                profession_ids: ids.filter(
                                  (id) => id !== p.id.toString()
                                ),
                              });
                            } else {
                              setFormData({
                                ...formData,
                                profession_ids: [...ids, p.id.toString()],
                              });
                            }
                          }}
                          className={`px-4 py-2 rounded-full border text-sm font-medium transition 
                          ${
                            selected
                              ? "bg-indigo-600 text-white border-indigo-600 shadow-md"
                              : "bg-gray-100 text-gray-700 border-gray-300 hover:bg-gray-200"
                          }`}
                        >
                          {p.name}
                        </button>
                      );
                    })}
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-gray-700 font-medium mb-1">
                      Prix minimum (XOF)
                    </label>
                    <input
                      type="number"
                      name="min_price"
                      placeholder="Prix minimum"
                      value={formData.min_price}
                      onChange={handleChange}
                      className="w-full border border-gray-300 rounded-lg p-3 text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 shadow-sm"
                      required
                    />
                  </div>
                  <div>
                    <label className="block text-gray-700 font-medium mb-1">
                      Slogan / courte description
                    </label>
                    <input
                      type="text"
                      name="slogan"
                      placeholder="Slogan"
                      value={formData.slogan}
                      onChange={handleChange}
                      className="w-full border border-gray-300 rounded-lg p-3 text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 shadow-sm"
                      required
                    />
                  </div>
                </div>
              </>
            )}

            {/* Commun */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-gray-700 font-medium mb-1">
                  Email
                </label>
                <input
                  type="email"
                  name="email"
                  placeholder="Email"
                  value={formData.email}
                  onChange={handleChange}
                  className="w-full border border-gray-300 rounded-lg p-3 text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 shadow-sm"
                  required
                />
              </div>
              <div>
                <label className="block text-gray-700 font-medium mb-1">
                  Mot de passe
                </label>
                <input
                  type="password"
                  name="password"
                  placeholder="Mot de passe"
                  value={formData.password}
                  onChange={handleChange}
                  className="w-full border border-gray-300 rounded-lg p-3 text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 shadow-sm"
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-gray-700 font-medium mb-1">
                Téléphone
              </label>
              <input
                type="tel"
                name="telephone"
                placeholder="Téléphone"
                value={formData.telephone}
                onChange={handleChange}
                className="w-full border border-gray-300 rounded-lg p-3 text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 shadow-sm"
              />
            </div>

            {/* Upload photo */}
            <div className="flex flex-col items-center border-2 border-dashed rounded-xl p-6 bg-gray-50">
              <input
                type="file"
                name="profile_photo"
                onChange={handleChange}
                className="hidden"
                id="fileUpload"
              />
              <label
                htmlFor="fileUpload"
                className="cursor-pointer text-indigo-600 font-medium"
              >
                {previewPhoto
                  ? "Changer la photo"
                  : "Uploader une photo de profil"}
              </label>
              {previewPhoto && (
                <img
                  src={previewPhoto}
                  alt="Aperçu"
                  className="mt-4 w-28 h-28 object-cover rounded-full border shadow-md"
                />
              )}
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-gray-700 font-medium mb-1">
                  Adresse principale
                </label>
                <input
                  type="text"
                  name="location"
                  placeholder="Adresse principale"
                  value={formData.location}
                  onChange={handleChange}
                  className="w-full border border-gray-300 rounded-lg p-3 text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 shadow-sm"
                  required
                />
              </div>
              <div>
                <label className="block text-gray-700 font-medium mb-1">
                  Adresse secondaire (optionnelle)
                </label>
                <input
                  type="text"
                  name="adresse"
                  placeholder="Adresse secondaire"
                  value={formData.adresse}
                  onChange={handleChange}
                  className="w-full border border-gray-300 rounded-lg p-3 text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 shadow-sm"
                />
              </div>
            </div>

            <button
              type="submit"
              className="w-full bg-indigo-600 text-white py-3 rounded-xl font-semibold text-lg shadow-lg hover:bg-indigo-700 transition transform hover:scale-[1.02]"
            >
              S'inscrire
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default Register;
