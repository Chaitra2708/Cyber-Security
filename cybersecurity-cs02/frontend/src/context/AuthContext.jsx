/**
 * SecureMart - Authentication context.
 *
 * Holds the current user + JWT in React state, persisted in localStorage.
 * NOTE: route guards here are a usability feature; the backend independently
 * enforces authentication and role checks on every protected API.
 */
import { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { api, getToken, setToken } from '../services/api.js';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    if (!getToken()) {
      setUser(null);
      setLoading(false);
      return;
    }
    try {
      const data = await api.me();
      setUser(data.user);
    } catch {
      setUser(null);
      setToken(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  async function login(email, password) {
    const data = await api.login({ email, password });
    setToken(data.token);
    setUser(data.user);
    return data.user;
  }

  async function register(payload) {
    const data = await api.register(payload);
    setToken(data.token);
    setUser(data.user);
    return data.user;
  }

  async function logout() {
    try {
      await api.logout();
    } catch {
      // Network errors on logout are non-fatal; clear locally regardless.
    }
    setToken(null);
    setUser(null);
  }

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout, refresh }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
