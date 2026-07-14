import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import api from './api';

export interface AuthUser {
  id: number;
  name: string;
  email: string;
  role: 'admin' | 'agent';
  account: {
    id: number;
    company_name: string;
    subdomain: string;
    plan: string;
  };
}

interface AuthState {
  user: AuthUser | null;
  loading: boolean;
  login: (subdomain: string, email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  refresh: () => Promise<void>;
}

const AuthContext = createContext<AuthState | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [loading, setLoading] = useState(true);

  async function refresh() {
    try {
      const { data } = await api.get<{ user: AuthUser }>('/api/auth/me');
      setUser(data.user);
    } catch {
      setUser(null);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { refresh(); }, []);

  async function login(subdomain: string, email: string, password: string) {
    const { data } = await api.post<{ user: AuthUser }>('/api/auth/login',
      { subdomain, email, password });
    setUser(data.user);
  }

  async function logout() {
    await api.delete('/api/auth/login');
    setUser(null);
  }

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, refresh }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be inside <AuthProvider>');
  return ctx;
}
