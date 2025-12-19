import { FaStar } from "react-icons/fa";
import Skeleton from "./Skeleton";

const ReviewList = ({ reviews }) => {
  // if (loading) {
  //   return (
  //     <div className="space-y-4 mb-8">
  //       <Skeleton width="100%" height="60px" />
  //       <Skeleton width="100%" height="60px" />
  //     </div>
  //   );
  // }

  if (reviews.length === 0) return <p className="text-gray-500 mb-8">Aucun avis pour le moment.</p>;

  return (
    <div className="space-y-4 mb-8">
      {reviews.map((r) => (
        <div key={r.id} className="border p-4 rounded-xl shadow-sm hover:shadow-md transition bg-white">
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center">
              <img
                src={r.client?.photo ? `http://localhost:8000/storage/profile_photos/${r.client.photo}` : "https://via.placeholder.com/40"}
                alt={r.client?.name || "Utilisateur"}
                className="h-10 w-10 rounded-full object-cover mr-3 border"
              />
              <span className="font-semibold text-gray-800">{r.client?.name || "Utilisateur"}</span>
            </div>
            <span className="text-sm text-gray-400">{new Date(r.created_at).toLocaleDateString("fr-FR")}</span>
          </div>
          <div className="flex items-center mb-2">
            {[1,2,3,4,5].map((i) => (
              <FaStar key={i} className={`mr-1 ${i <= r.note ? "text-yellow-400" : "text-gray-300"}`} />
            ))}
          </div>
          {r.commentaire && <p className="text-gray-700">{r.commentaire}</p>}
        </div>
      ))}
    </div>
  );
};

export default ReviewList;
