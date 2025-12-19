import React from "react";

const Spinner = ({ size = 4, borderColor = "blue-600", className = "" }) => {
  const h = `${size}rem`; // taille en rem
  const w = `${size}rem`;
  return (
    <div className={`flex items-center justify-center ${className}`}>
      <div
        className={`animate-spin rounded-full border-t-4 border-b-4 border-${borderColor}`}
        style={{ height: h, width: w }}
      ></div>
    </div>
  );
};

export default Spinner;
