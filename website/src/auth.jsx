import { createContext, useContext, useEffect, useState } from 'react';
import { api, token } from './api';

const Ctx = createContext(null);
export const useAuth = () => useContext(Ctx);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let alive = true;
    (async () => {
      if (token.get()) {
        try {
          const r = await api.get('auth/me.php');
          if (alive) setUser(r.user);
        } catch (e) {
          if (e.status === 401) token.set(null);
        }
      }
      if (alive) setReady(true);
    })();
    return () => {
      alive = false;
    };
  }, []);

  async function login(role, email, password) {
    const r = await api.post('auth/login.php', { role, email: email.trim(), password });
    token.set(r.token);
    setUser(r.user);
    return r.user;
  }

  async function register(body) {
    const r = await api.post('auth/register.php', body);
    token.set(r.token);
    const me = await api.get('auth/me.php');
    setUser(me.user);
    return me.user;
  }

  function logout() {
    token.set(null);
    setUser(null);
  }

  return <Ctx.Provider value={{ user, ready, login, register, logout }}>{children}</Ctx.Provider>;
}
