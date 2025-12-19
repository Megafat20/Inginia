import React, { useState } from "react";
import axios from "axios";

const AvisForm = ({ prestataireId, onReviewAdded }) => {
  const [rating, setRating] = useState(0);
  const [comment, setComment] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const submitReview = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const token = localStorage.getItem("token"); // si tu utilises JWT
      const res = await axios.post(
        `/api/prestataires/${prestataireId}/avis`,
        { rating, comment },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      onReviewAdded(res.data.review, res.data.new_rating); // callback vers parent
      setRating(0);
      setComment("");
    } catch (err) {
      setError("Impossible d'envoyer l'avis.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={submitReview} className="p-4 border rounded shadow">
      <h3 className="text-lg font-bold mb-2">Laisser un avis</h3>

      {/* Sélecteur de note */}
      <div className="mb-2">
        <label className="block">Note :</label>
        <select
          value={rating}
          onChange={(e) => setRating(e.target.value)}
          required
          className="border p-2 rounded w-full"
        >
          <option value="">-- Choisir une note --</option>
          {[1, 2, 3, 4, 5].map((n) => (
            <option key={n} value={n}>
              {n} étoile{n > 1 ? "s" : ""}
            </option>
          ))}
        </select>
      </div>

      {/* Champ commentaire */}
      <div className="mb-2">
        <label className="block">Commentaire :</label>
        <textarea
          value={comment}
          onChange={(e) => setComment(e.target.value)}
          className="border p-2 rounded w-full"
          rows="3"
        />
      </div>

      {error && <p className="text-red-500">{error}</p>}
      <button
        type="submit"
        disabled={loading}
        className="bg-blue-600 text-white px-4 py-2 rounded"
      >
        {loading ? "Envoi..." : "Envoyer"}
      </button>
    </form>
  );
};

export default AvisForm;
