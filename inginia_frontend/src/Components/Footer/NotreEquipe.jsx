import React from "react";

const teamMembers = [
  { id: 1, name: "Abdoul Malick Hama Ide", role: "CEO" },
  { id: 2, name: "Abdoul Fataou Hama Ide", role: "CTO" },
];

const NotreEquipe = () => {
  return (
    <div className="min-h-screen p-6 bg-gray-50">
      <h1 className="text-3xl font-bold text-center mb-8">Notre Équipe</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-6xl mx-auto">
        {teamMembers.map((member) => (
          <div
            key={member.id}
            className="bg-white p-6 rounded-2xl shadow hover:shadow-lg transition flex flex-col items-center"
          >
            <img
              src={member.photo || "/Images/Default_pfp.jpg"}
              alt={member.name}
              className="w-32 h-32 rounded-full object-cover mb-4 border-2 border-blue-600"
            />
            <h2 className="text-xl font-semibold">{member.name}</h2>
            <p className="text-gray-500">{member.role}</p>
          </div>
        ))}
      </div>
    </div>
  );
};

export default NotreEquipe;
