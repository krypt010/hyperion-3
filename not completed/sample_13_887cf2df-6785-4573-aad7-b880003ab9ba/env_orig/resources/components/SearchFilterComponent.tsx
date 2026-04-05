import React from 'react';
const SearchFilterComponent: React.FC<any> = ({ onSearchChange }) => (
  <input type="text" onChange={(e) => onSearchChange(e.target.value)} />
);
export default SearchFilterComponent;