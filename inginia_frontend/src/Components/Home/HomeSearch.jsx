import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { FaSearch, FaMapMarkerAlt } from "react-icons/fa";

const HomeSearch = () => {
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState("");

  const handleSearch = () => {
    if (!searchQuery) return;
    navigate(`/search?query=${encodeURIComponent(searchQuery)}`);
  };

  return (
    <div className="max-w-3xl mx-auto w-full px-4">
      <div className="relative group">
        {/* Subtle background glow on hover */}
        <div className="absolute -inset-1 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-[2rem] blur opacity-25 group-hover:opacity-40 transition duration-1000 group-hover:duration-200"></div>

        <div className="relative flex flex-col md:flex-row items-center bg-white rounded-2xl md:rounded-full p-2 shadow-2xl border border-slate-100 backdrop-blur-sm">
          <div className="flex-1 flex items-center px-4 w-full">
            <FaSearch className="text-slate-400 mr-3" />
            <input
              type="text"
              placeholder="Que recherchez-vous ? (ex: Plombier, Dakar...)"
              className="w-full py-4 bg-transparent text-slate-700 font-medium outline-none placeholder:text-slate-300 text-lg"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleSearch()}
            />
          </div>

          <div className="hidden md:block h-8 w-px bg-slate-100"></div>

          <div className="hidden md:flex items-center px-6 gap-2 text-slate-400">
            <FaMapMarkerAlt />
            <span className="text-sm font-bold uppercase tracking-widest whitespace-nowrap">
              Tout le Sénégal
            </span>
          </div>

          <button
            onClick={handleSearch}
            className="w-full md:w-auto px-10 py-4 bg-slate-900 hover:bg-blue-600 text-white font-black uppercase tracking-widest text-xs rounded-xl md:rounded-full transition-all duration-300 active:scale-95 shadow-lg shadow-slate-200 hover:shadow-blue-200"
          >
            Trouver
          </button>
        </div>
      </div>
    </div>
  );
};

export default HomeSearch;
