import React, { useEffect, useState } from "react";
import axios from "axios";
import AvisForm from "./AvisForm";

const PrestataireAvis = ({ prestataireId }) => {
  const [avis, setAvis] = useState([]);
  const [average, setAverage] = useState(null);

  useEffect(() => {
    fetchAvis();
  }, [prestataireId]);

  const fetchAvis = async () => {
    const res = await axios.get(`/api/prestataires/${prestataireId}/avis`);
    setAvis(res.data.avis);
    setAverage(res.data.average);
  };

  const handleReviewAdded = (newReview, newRating) => {
    setAvis([newReview, ...avis]); // ajouter au début
    setAverage(newRating); // mettre à jour la moyenne
  };

  return (
    <div className="mt-4">
      <h2 className="text-xl font-bold mb-2">
        Avis ({avis.length}) - Note moyenne :{" "}
        {average ? `${average} ⭐` : "Pas encore d'avis"}
      </h2>

      <AvisForm prestataireId={prestataireId} onReviewAdded={handleReviewAdded} />

      <div className="mt-4">
        {avis.length > 0 ? (
          avis.map((a) => (
            <div key={a.id} className="border-b py-2">
              <p className="font-semibold">
                {a.rating} ⭐ - {a.client_id}
              </p>
              <p>{a.comment}</p>
            </div>
          ))
        ) : (
          <p>Aucun avis pour ce prestataire.</p>
        )}
      </div>
    </div>
  );
};

export default PrestataireAvis;
