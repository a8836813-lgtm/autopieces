import { API_BASE } from './config';

const KEY = 'autopieces_token';

export class ApiError extends Error {
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}

export const token = {
  get() {
    try {
      return localStorage.getItem(KEY);
    } catch {
      return null;
    }
  },
  set(v) {
    try {
      if (v) localStorage.setItem(KEY, v);
      else localStorage.removeItem(KEY);
    } catch {}
  },
};

async function send(path, options = {}) {
  const headers = { ...(options.headers || {}) };
  const t = token.get();
  if (t) headers.Authorization = `Bearer ${t}`;
  let res;
  try {
    res = await fetch(`${API_BASE}/${path}`, { ...options, headers });
  } catch {
    throw new ApiError('Cannot reach the server. Check that XAMPP is running and the API address is right.', 0);
  }
  let data = null;
  try {
    data = await res.json();
  } catch {
    throw new ApiError('The server sent an unreadable answer.', res.status);
  }
  if (!res.ok || data.ok === false) throw new ApiError(data.error || 'Request failed', res.status);
  return data;
}

function query(params) {
  const q = new URLSearchParams();
  Object.entries(params || {}).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') q.set(k, v);
  });
  const s = q.toString();
  return s ? `?${s}` : '';
}

export const api = {
  get: (path, params) => send(path + query(params)),
  post: (path, body) =>
    send(path, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body || {}),
    }),
  form: (path, fields, files = []) => {
    const f = new FormData();
    Object.entries(fields || {}).forEach(([k, v]) => {
      if (v !== undefined && v !== null) f.append(k, v);
    });
    files.forEach(([name, file]) => f.append(name, file));
    return send(path, { method: 'POST', body: f });
  },
};

export function photoUrl(path) {
  if (!path) return '';
  if (/^https?:/.test(path)) return path;
  return `${API_BASE}/${path.replace(/^\//, '')}`;
}
