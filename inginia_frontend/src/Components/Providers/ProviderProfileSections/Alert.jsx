const Alert = ({ message, close }) => (
    <div className="mt-4 p-4 bg-green-50 border border-green-400 text-green-800 rounded-lg text-center">
      {message}
      <button
        className="ml-4 font-bold"
        onClick={close}
      >
        ✖
      </button>
    </div>
  );
  
  export default Alert;
  