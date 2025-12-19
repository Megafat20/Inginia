import React from "react";

const Logo = ({ toggleSidebar }) => (
  <div
    onClick={toggleSidebar}
    className="flex items-center gap-2 cursor-pointer group relative"
  >
    {/* Cercle avec initiale */}
    <div
      className="h-12 w-12 rounded-full flex items-center justify-center
                 bg-gradient-to-br from-indigo-500 to-purple-500
                 text-white text-2xl font-bold shadow-lg
                 transition-transform duration-300 transform group-hover:scale-110"
    >
      I
    </div>

    {/* Nom */}
    <span className="text-2xl font-extrabold text-white tracking-wide">
      Inginia
    </span>

    {/* Hamburger animé */}
    <div className="ml-2 flex flex-col justify-between h-4 w-5">
      <span className="block h-[2px] w-full bg-white rounded transform transition-all duration-300 group-hover:translate-y-0.5"></span>
      <span className="block h-[2px] w-full bg-white rounded transform transition-all duration-300 group-hover:translate-y-1"></span>
      <span className="block h-[2px] w-full bg-white rounded transform transition-all duration-300 group-hover:translate-y-1.5"></span>
    </div>

    {/* Tooltip */}
    <span
      className="absolute -bottom-6 left-1/2 transform -translate-x-1/2
                 bg-gray-800 text-white text-xs rounded px-2 py-1
                 opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none"
    >
      Ouvrir le menu
    </span>
  </div>
);

export default Logo;
