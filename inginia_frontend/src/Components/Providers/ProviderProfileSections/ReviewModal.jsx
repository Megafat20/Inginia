import { useState } from "react";
import { submitReview, getProviderDashboard } from "../../services/ProviderService";

const ReviewModal = ({ providerId, closeModal, refreshReviews }) => {
  const [reviewData, setReviewData] = useState({ rating: 5, comment: "" });
  const [loadingSubmit, setLoadingSubmit] = useState(false);

  const handleChange = (e) => setReviewData({ ...reviewData, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoadingSubmit(true);
    await submitReview(providerId, reviewData);
    const data = await getProviderDashboard(providerId);
    refreshReviews(data);
    setLoadingSubmit(false);
    closeModal();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 p-4">
      <div className="bg-white p-6 rounded-2xl w-full max-w-md shadow-lg">
        <h3 className="text-xl font-bold mb-4 text-gray-800">Laisser un avis</h3>
        <form onSubmit={handleSubmit} className="space-y-4">
          <label className="block text-gray-700">
            Note :
            <select name="rating" value={reviewData.rating} onChange={handleChange} className="w-full border p-2 rounded mt-1">
              {[1,2,3,4,5].map((i) => <option key={i} value={i}>{i}</option>)}
            </select>
          </label>
          <label className="block text-gray-700">
            Commentaire :
            <textarea name="comment" value={reviewData.comment} onChange={handleChange} className="w-full border p-2 rounded mt-1" rows={3}/>
          </label>
          <div className="flex justify-end gap-3">
            <button type="button" className="px-4 py-2 bg-gray-200 rounded-xl hover:bg-gray-300 transition" onClick={closeModal}>Annuler</button>
            <button type="submit" className="px-4 py-2 bg-green-600 text-white rounded-xl hover:bg-green-500 transition" disabled={loadingSubmit}>
              {loadingSubmit ? "Envoi..." : "Envoyer"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default ReviewModal;
