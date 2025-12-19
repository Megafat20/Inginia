import React, { useEffect, useState } from "react";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";
import { getPopularCategories } from "../services/HomeService";
import { useNavigate } from "react-router-dom";

const CategoriesSection = () => {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [visibleCount, setVisibleCount] = useState(5); // nombre visible
  const navigate = useNavigate();

  useEffect(() => {
    const fetchCategories = async () => {
      setLoading(true);
      const cats = await getPopularCategories();
      
      setCategories(cats);
      setLoading(false);
    };
    fetchCategories();
  }, []);

  const handleToggle = () => {
    if (visibleCount < categories.length) {
      setVisibleCount((prev) => prev + 10);
    } else {
      setVisibleCount(5); // retour à l'état initial
    }
  };

  return (
    <section className="relative py-5 px-6 lg:px-15 bg-gradient-to-b from-gray-50 to-gray-100">
      {/* Grid */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-8">
        {loading
          ? Array.from({ length: 10 }).map((_, i) => (
              <div
                key={i}
                className="p-6 rounded-2xl shadow-md flex flex-col items-center text-center backdrop-blur-md bg-white/70"
              >
                <Skeleton height={50} width={50} circle className="mb-3" />
                <Skeleton height={18} width={100} className="mb-2" />

              </div>
            ))
          : categories
              .slice(0, visibleCount)
              .map((cat, index) => (
                <div
                  key={cat.id || `cat-${index}`}
                  onClick={() => navigate(`/search?categoryId=${cat.id}`)}
                  className="relative p-6 rounded-2xl bg-white/80 backdrop-blur-lg border border-gray-200 
                           shadow-md cursor-pointer flex flex-col items-center text-center 
                           transform transition-all duration-300 hover:scale-105 hover:rotate-1 hover:shadow-2xl hover:border-gray-300"
                >
                  {/* Icon */}
                  <div className="text-5xl mb-4 drop-shadow-sm">{cat.icon}</div>

                  {/* Title */}
                  <h3 className="font-semibold text-gray-800 text-lg mb-1">
                    {cat.name}
                  </h3>

                  {/* Sub info */}
                  <p className="text-gray-500 text-sm">
                    {cat.total} prestataires
                  </p>

                  {/* Halo effect */}
                  <div className="absolute inset-0 rounded-2xl bg-gradient-to-tr from-indigo-500/10 to-pink-500/10 opacity-0 hover:opacity-100 transition"></div>
                </div>
              ))}
      </div>

      {/* Bouton Plus/Moins */}
      {!loading && categories.length > 10 && (
        <div className="flex justify-center mt-6">
          <button
            onClick={handleToggle}
            className="px-6 py-2 bg-indigo-600 text-white font-medium rounded-lg shadow hover:bg-indigo-700 transition"
          >
            {visibleCount < categories.length ? "Plus" : "Moins"}
          </button>
        </div>
      )}
    </section>
  );
};

export default CategoriesSection;
