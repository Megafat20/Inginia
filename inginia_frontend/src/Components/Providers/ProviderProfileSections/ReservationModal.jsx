import { useState } from "react";
import { submitReservation } from "../../services/ProviderService";

const ReservationModal = ({
  provider,
  competances,
  user,
  selectedReservation,
  closeModal,
  onReservationSuccess,
}) => {
  const [reservationData, setReservationData] = useState({
    service_id: "",
    other_service: "",
    date: "",
    time: "",
    comment: "",
  });
  const [loadingReservation, setLoadingReservation] = useState(false);
  const [reservationSent, setReservationSent] = useState(false);
  const handleChange = (e) =>
    setReservationData({ ...reservationData, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoadingReservation(true);
    const requested_date = `${reservationData.date}T${reservationData.time}:00`;
    const serviceId =
      reservationData.service_id !== "other"
        ? parseInt(reservationData.service_id)
        : null;
    // Récupérer la position GPS du client
    let latitude = null;
    let longitude = null;

    if (navigator.geolocation) {
      try {
        await new Promise((resolve, reject) => {
          navigator.geolocation.getCurrentPosition(
            (position) => {
              latitude = position.coords.latitude;
              longitude = position.coords.longitude;
              resolve();
            },
            (error) => {
              console.error("Erreur localisation :", error);
              resolve(); // continuer même si erreur
            },
            { enableHighAccuracy: true, timeout: 10000 }
          );
        });
      } catch (err) {
        console.error(err);
      }
    }
    const res = await submitReservation(provider.id, {
      ...reservationData,
      service_id: serviceId,
      requested_date,
      latitude,
      longitude,
    });
    onReservationSuccess(res.reservation);
    setReservationSent(true);
    setLoadingReservation(false);
    closeModal();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 p-4">
      <div className="bg-white p-6 rounded-2xl w-full max-w-md shadow-lg">
        <h3 className="text-xl font-bold mb-4 text-gray-800">
          {selectedReservation
            ? "Réservation envoyée !"
            : `Réserver ${provider?.name}`}
        </h3>
        {!reservationSent ?(
          <form onSubmit={handleSubmit} className="space-y-4">
            <label className="block text-gray-700">
              Service :
              <select
                name="service_id"
                value={reservationData.service_id}
                onChange={handleChange}
                className="w-full border p-2 rounded mt-1"
                required
              >
                <option value="" disabled>
                  Choisir un service
                </option>
                {competances.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.title}
                  </option>
                ))}
                <option value="other">Autre service...</option>
              </select>
            </label>
            <label className="block text-gray-700">
              Date :
              <input
                type="date"
                name="date"
                value={reservationData.date}
                onChange={handleChange}
                className="w-full border p-2 rounded mt-1"
                required
              />
            </label>
            <label className="block text-gray-700">
              Heure :
              <input
                type="time"
                name="time"
                value={reservationData.time}
                onChange={handleChange}
                className="w-full border p-2 rounded mt-1"
                required
              />
            </label>
            <label className="block text-gray-700">
              Commentaire :
              <textarea
                name="comment"
                value={reservationData.comment}
                onChange={handleChange}
                className="w-full border p-2 rounded mt-1"
                rows={3}
              />
            </label>
            <div className="flex justify-end gap-3">
              <button
                type="button"
                className="px-4 py-2 bg-gray-200 rounded-xl hover:bg-gray-300 transition"
                onClick={closeModal}
              >
                Annuler
              </button>
              <button
                type="submit"
                className="px-4 py-2 bg-indigo-600 text-white rounded-xl hover:bg-indigo-500 transition"
                disabled={loadingReservation}
              >
                {loadingReservation ? "Envoi..." : "Réserver"}
              </button>
            </div>
          </form>
        ) : (
          <div className="text-center">
            <div className="bg-green-50 text-green-800 px-4 py-3 rounded-lg mb-4">
              ✅ Votre demande a été envoyée !
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ReservationModal;
