// src/components/Providers/ChatBot.jsx
import React, { useEffect, useState, useRef } from "react";
import { FaPaperPlane } from "react-icons/fa";
import { useAuth } from "../../Context/AuthContext";
import { getMessages, sendMessage } from "../../services/chatService";
import echo from "../../../echo";

const ChatBox = ({ reservationId }) => {
  const { user } = useAuth();
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef(null);

  // Récupérer les messages initiaux
  useEffect(() => {
    fetchMessages();
  }, [reservationId]);

  const fetchMessages = async () => {
    try {
      const data = await getMessages(reservationId);
      setMessages(data.messages || []);
      scrollToBottom();
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    if (!reservationId) return;

    // S'abonner au canal privé
    const channelName = `chat.${reservationId}`;
    const channel = echo.private(channelName);

    channel.listen(".message.sent", (e) => {
      const msg = e.message;
      // Utilisation de != pour ignorer le type (string vs int)
      if (msg.sender_id != user.id) {
        setMessages((prev) => {
          // Vérification supplémentaire pour éviter les doublons par ID
          if (prev.find((m) => m.id == msg.id)) return prev;
          return [...prev, msg];
        });
        scrollToBottom();
      }
    });

    return () => {
      echo.leave(channelName);
    };
  }, [reservationId, user?.id]);

  const handleSend = async (e) => {
    e.preventDefault();
    if (!newMessage.trim()) return;

    const currentMessage = newMessage;
    setNewMessage("");

    // Optimistic UI : Ajout immédiat avec un ID temporaire unique
    const tempId = `temp-${Date.now()}`;
    const optimisticMsg = {
      id: tempId,
      reservation_id: reservationId,
      sender_id: user.id,
      message: currentMessage,
      created_at: new Date().toISOString(),
    };

    setMessages((prev) => [...prev, optimisticMsg]);
    scrollToBottom();

    try {
      const officialMsg = await sendMessage(reservationId, {
        content: currentMessage,
      });

      // Remplacer le message optimiste par le vrai
      setMessages((prev) =>
        prev.map((m) => (m.id == tempId ? officialMsg : m))
      );
    } catch (err) {
      console.error(err);
      setMessages((prev) => prev.filter((m) => m.id != tempId));
      alert("Erreur d'envoi");
    }
  };

  const scrollToBottom = () => {
    setTimeout(() => {
      messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    }, 100);
  };

  return (
    <div className="flex flex-col h-[400px] bg-gray-50 rounded-2xl border border-gray-200 shadow-inner overflow-hidden">
      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3 scrollbar-thin scrollbar-thumb-gray-300">
        {messages.map((msg) => {
          const isUser = msg.sender_id == user.id;
          return (
            <div
              key={msg.id || Math.random()}
              className={`flex ${
                isUser ? "justify-end" : "justify-start"
              } animate-fadeIn`}
            >
              <div
                className={`max-w-[75%] px-4 py-2 rounded-2xl shadow-sm text-sm ${
                  isUser
                    ? "bg-blue-600 text-white rounded-br-none"
                    : "bg-white text-gray-800 border border-gray-100 rounded-bl-none"
                }`}
              >
                {msg.message}
                <div
                  className={`text-[10px] mt-1 text-right ${
                    isUser ? "text-blue-100" : "text-gray-400"
                  }`}
                >
                  {msg.created_at
                    ? new Date(msg.created_at).toLocaleTimeString([], {
                        hour: "2-digit",
                        minute: "2-digit",
                      })
                    : "..."}
                </div>
              </div>
            </div>
          );
        })}
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <form
        onSubmit={handleSend}
        className="flex items-center p-3 border-t border-gray-200 bg-white"
      >
        <input
          type="text"
          placeholder="Écrire un message..."
          value={newMessage}
          onChange={(e) => setNewMessage(e.target.value)}
          className="flex-1 bg-gray-50 border border-gray-200 rounded-full px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-all text-sm"
        />
        <button
          type="submit"
          className="ml-2 bg-blue-600 hover:bg-blue-700 text-white rounded-full p-2.5 shadow-md flex items-center justify-center disabled:opacity-50 transition-transform transform active:scale-95"
          disabled={!newMessage.trim()}
        >
          <FaPaperPlane className="text-sm" />
        </button>
      </form>
    </div>
  );
};

export default ChatBox;
