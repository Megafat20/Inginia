import ChatBox from "./ChatBot";

const ChatModal = ({ provider, reservation, user, closeModal }) => (
  <div className="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 p-4">
    <div className="bg-white p-6 rounded-2xl w-full max-w-md shadow-lg">
      <h3 className="text-xl font-bold mb-4 text-gray-800">Chat avec {provider?.name}</h3>
      <ChatBox reservationId={reservation.id} userId={user?.id} />
      <div className="flex justify-end mt-4">
        <button type="button" className="px-4 py-2 bg-gray-200 rounded-xl hover:bg-gray-300 transition" onClick={closeModal}>Fermer</button>
      </div>
    </div>
  </div>
);

export default ChatModal;
