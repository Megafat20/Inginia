import React, { useState } from "react";

const faqData = [
  { id: 1, question: "Comment créer un compte ?", answer: "Cliquez sur 'S'inscrire' en haut à droite et remplissez le formulaire." },
  { id: 2, question: "Comment contacter le support ?", answer: "Utilisez le formulaire de contact ou envoyez-nous un email à support@example.com." },
  { id: 3, question: "Puis-je modifier mes informations ?", answer: "Oui, allez dans votre profil et cliquez sur 'Modifier'." },
];

const FAQ = () => {
  const [openId, setOpenId] = useState(null);

  const toggle = (id) => {
    setOpenId(openId === id ? null : id);
  };

  return (
    <div className="min-h-screen p-6 bg-gray-50">
      <h1 className="text-3xl font-bold text-center mb-8">FAQ</h1>
      <div className="max-w-3xl mx-auto space-y-4">
        {faqData.map((item) => (
          <div
            key={item.id}
            className="bg-white p-4 rounded-2xl shadow hover:shadow-md transition cursor-pointer"
            onClick={() => toggle(item.id)}
          >
            <div className="flex justify-between items-center">
              <h2 className="font-semibold">{item.question}</h2>
              <span>{openId === item.id ? "−" : "+"}</span>
            </div>
            {openId === item.id && (
              <p className="mt-2 text-gray-600">{item.answer}</p>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

export default FAQ;
