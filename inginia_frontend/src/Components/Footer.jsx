// Footer.jsx
import React from "react";
import { FaFacebookF, FaTwitter, FaInstagram, FaLinkedinIn } from "react-icons/fa";

const Footer = () => {
  return (
    <footer className="bg-gray-800 text-gray-200 py-8">
      <div className="max-w-7xl mx-auto px-6 md:px-12">
        <div className="flex flex-col md:flex-row justify-between items-center md:items-start gap-6 md:gap-0">
          {/* Logo / Branding */}
          <div>
            <h1 className="text-2xl font-bold text-white mb-2">Inginia</h1>
            <p className="text-gray-400 text-sm">
              Connectez clients et prestataires de services facilement.
            </p>
          </div>

          {/* Liens rapides */}
          <div className="flex flex-col md:flex-row gap-12">
            <div>
              <h2 className="font-semibold mb-2">À propos</h2>
              <ul className="space-y-1 text-gray-400 text-sm">
                <li><a href="/equipe" className="hover:text-white transition">Notre équipe</a></li>
                <li><a href="/contact" className="hover:text-white transition">Contact</a></li>
                <li><a href="/faq" className="hover:text-white transition">FAQ</a></li>
              </ul>
            </div>

          
          </div>

          {/* Réseaux sociaux */}
          <div>
            <h2 className="font-semibold mb-2">Suivez-nous</h2>
            <div className="flex gap-4 mt-2">
              <a href="#" className="hover:text-blue-500 transition"><FaFacebookF /></a>
              <a href="#" className="hover:text-blue-400 transition"><FaTwitter /></a>
              <a href="#" className="hover:text-pink-500 transition"><FaInstagram /></a>
              <a href="#" className="hover:text-blue-600 transition"><FaLinkedinIn /></a>
            </div>
          </div>
        </div>

        {/* Bas de page */}
        <div className="border-t border-gray-700 mt-6 pt-4 text-center text-gray-500 text-sm">
          &copy; {new Date().getFullYear()} Inginia. Tous droits réservés.
        </div>
      </div>
    </footer>
  );
};

export default Footer;
