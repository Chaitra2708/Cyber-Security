import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// SecureMart frontend build configuration.
// During development the Vite dev server proxies /api to the Express backend
// on port 5500 so the React app can call a same-origin API.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:5500',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
  },
});
