import React, { useState, useEffect } from "react";
import axios from "../axios";
import { FaClock, FaCalendarDay, FaSave, FaCheck } from "react-icons/fa";

const daysOfWeek = [
  { key: "monday", label: "Lundi" },
  { key: "tuesday", label: "Mardi" },
  { key: "wednesday", label: "Mercredi" },
  { key: "thursday", label: "Jeudi" },
  { key: "friday", label: "Vendredi" },
  { key: "saturday", label: "Samedi" },
  { key: "sunday", label: "Dimanche" },
];

const Planning = () => {
  const [schedule, setSchedule] = useState([]);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    // Charger le planning existant
    const fetchSchedule = async () => {
      try {
        const res = await axios.get("/api/availabilities");
        if (res.data) {
          const loadedSchedule = res.data.map((item) => ({
            day: item.day,
            start_time: item.start_time?.substring(0, 5),
            end_time: item.end_time?.substring(0, 5),
          }));
          setSchedule(loadedSchedule);
        }
      } catch (error) {
        console.error(error);
      }
    };
    fetchSchedule();
  }, []);

  const handleToggleDay = (dayKey) => {
    const exists = schedule.find((s) => s.day === dayKey);
    if (exists) {
      setSchedule(schedule.filter((s) => s.day !== dayKey));
    } else {
      setSchedule([
        ...schedule,
        { day: dayKey, start_time: "09:00", end_time: "18:00" },
      ]);
    }
  };

  const updateTime = (dayKey, field, value) => {
    setSchedule(
      schedule.map((s) => (s.day === dayKey ? { ...s, [field]: value } : s))
    );
  };

  const savePlanning = () => {
    setLoading(true);
    setSuccess(false);
    axios
      .post("/api/availabilities", { schedule })
      .then(() => {
        setSuccess(true);
        setTimeout(() => setSuccess(false), 3000);
      })
      .catch(() => alert("❌ Erreur lors de la sauvegarde."))
      .finally(() => setLoading(false));
  };

  const getSlot = (dayKey) => schedule.find((s) => s.day === dayKey);

  return (
    <div className="max-w-6xl mx-auto">
      <div className="flex flex-col md:flex-row justify-between items-center mb-8 gap-4">
        <div>
          <h2 className="text-3xl font-extrabold text-gray-800 flex items-center gap-3">
            <FaCalendarDay className="text-blue-600" />
            Planning Hebdomadaire
          </h2>
          <p className="text-gray-500 mt-2 text-lg">
            Gérez vos disponibilités pour recevoir des missions.
          </p>
        </div>

        <button
          onClick={savePlanning}
          disabled={loading}
          className={`flex items-center gap-2 px-8 py-3 rounded-2xl font-bold text-white transition-all transform hover:scale-105 shadow-xl ${
            success
              ? "bg-green-500 ring-4 ring-green-200"
              : "bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700"
          }`}
        >
          {loading ? (
            <span className="animate-pulse">Sauvegarde...</span>
          ) : success ? (
            <>
              <FaCheck /> Enregistré
            </>
          ) : (
            <>
              <FaSave /> Enregistrer les changements
            </>
          )}
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {daysOfWeek.map((day) => {
          const slot = getSlot(day.key);
          const isActive = !!slot;

          return (
            <div
              key={day.key}
              className={`relative overflow-hidden rounded-3xl border transition-all duration-300 group ${
                isActive
                  ? "border-blue-200 bg-white shadow-xl transform -translate-y-1"
                  : "border-gray-100 bg-gray-50 opacity-75 hover:opacity-100"
              }`}
            >
              <div className="p-6">
                {/* Header Carte : Toggle Switch & Titre */}
                <div className="flex justify-between items-center mb-6">
                  <span
                    className={`font-bold text-xl capitalize ${
                      isActive ? "text-blue-800" : "text-gray-400"
                    }`}
                  >
                    {day.label}
                  </span>

                  {/* Switch Custom */}
                  <button
                    onClick={() => handleToggleDay(day.key)}
                    className={`relative w-14 h-8 rounded-full transition-colors duration-300 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 ${
                      isActive ? "bg-blue-600" : "bg-gray-300"
                    }`}
                  >
                    <span
                      className={`absolute top-1 left-1 bg-white w-6 h-6 rounded-full shadow-md transform transition-transform duration-300 ${
                        isActive ? "translate-x-6" : "translate-x-0"
                      }`}
                    />
                  </button>
                </div>

                {/* Contenu Horaire avec animation de hauteur */}
                <div
                  className={`transition-all duration-500 ease-in-out ${
                    isActive
                      ? "max-h-40 opacity-100"
                      : "max-h-0 opacity-0 overflow-hidden"
                  }`}
                >
                  <div className="flex items-center gap-3 bg-blue-50 p-4 rounded-xl border border-blue-100">
                    <FaClock className="text-blue-400 text-xl" />
                    <div className="flex flex-1 items-center justify-between gap-2">
                      <input
                        type="time"
                        className="bg-transparent font-bold text-gray-800 text-lg focus:outline-none w-20 text-center cursor-pointer hover:bg-white hover:rounded transition"
                        value={slot?.start_time || "09:00"}
                        onChange={(e) =>
                          updateTime(day.key, "start_time", e.target.value)
                        }
                      />
                      <span className="text-blue-300 font-bold">➜</span>
                      <input
                        type="time"
                        className="bg-transparent font-bold text-gray-800 text-lg focus:outline-none w-20 text-center cursor-pointer hover:bg-white hover:rounded transition"
                        value={slot?.end_time || "18:00"}
                        onChange={(e) =>
                          updateTime(day.key, "end_time", e.target.value)
                        }
                      />
                    </div>
                  </div>
                </div>
              </div>

              {/* Indicateur de statut bas */}
              <div
                className={`h-1.5 w-full absolute bottom-0 left-0 transition-colors duration-300 ${
                  isActive ? "bg-blue-500" : "bg-gray-200"
                }`}
              />
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default Planning;
