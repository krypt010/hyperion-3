import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import KeywordsPage from './pages/keywords/KeywordsPage';

const App = () => (
  <Router>
    <Routes>
      <Route path="/keywords" element={<KeywordsPage />} />
      <Route path="/" element={<Navigate to="/keywords" />} />
    </Routes>
  </Router>
);
export default App;
