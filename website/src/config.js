export const API_BASE = (import.meta.env.VITE_API_BASE || 'http://localhost/autopieces/api').replace(/\/$/, '');
export const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || 'YOUR_SUPABASE_URL';
export const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || 'YOUR_SUPABASE_ANON_KEY';
export const REFERENCE = { lat: 36.82, lng: 5.7667 };
export const DEMO = {
  client: ['client@demo.dz', 'demo1234'],
  mechanic: ['mechanic@demo.dz', 'demo1234'],
  shop: ['shop@demo.dz', 'demo1234'],
};
