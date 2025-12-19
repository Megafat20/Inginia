const Skeleton = ({ width, height, className }) => (
    <div
      className={`bg-gray-300 animate-pulse rounded ${className}`}
      style={{ width, height }}
    />
  );
  
  export default Skeleton;
  