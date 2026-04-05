import React from 'react';

const MainLayout: React.FC<{ children: React.ReactNode; withSidebar?: boolean; title?: string; description?: string; keywords?: string }> = ({ children }) => {
  return <div className="min-h-screen bg-white">{children}</div>;
};

export default MainLayout;