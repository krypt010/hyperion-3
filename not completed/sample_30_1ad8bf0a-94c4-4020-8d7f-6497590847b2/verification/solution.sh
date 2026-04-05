#!/bin/bash
set -euo pipefail

# Overwrite page.tsx with the fixed version
cat > src/app/animals/page.tsx <<'EOF'
"use client";

import { motion } from "framer-motion";
import { useEffect, useState } from "react";

export default function DamageCracks() {
  const [cracks, setCracks] = useState<{ id: number; rotation: number }[]>([]);

  useEffect(() => {
    setCracks(Array.from({ length: 6 }).map((_, i) => ({
      id: i,
      rotation: (Math.random() * 10) - 5,
    })));
  }, []);

  return (
    <div className="relative w-full h-screen bg-white">
      {cracks.map((crack) => (
        <motion.div
          key={crack.id}
          className="absolute top-1/2 left-0 right-0 h-1 bg-black/80 blur-[1px]"
          style={{
            opacity: 0,
            transform: `rotate(${crack.rotation}deg) scaleX(0)`,
          }}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
        >
        </motion.div>
      ))}
      <div className="absolute top-10 left-10 text-black">
        <h1>Hydration Error Reproduction</h1>
        <p>Fixed: No hydration mismatch.</p>
      </div>
    </div>
  );
}
EOF
