import { useState } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import clsx from 'clsx';
import { AuthProvider, useAuth } from '../lib/auth';

const NAV = [
  { to: '/inbox',     label: 'Inbox',      icon: '📥' },
  { to: '/customers', label: 'Customers',  icon: '👥' },
  { to: '/tags',      label: 'Tags',       icon: '🏷' },
  { to: '/dashboard', label: 'Dashboard',  icon: '📊' }
];

function Inner() {
  const { user, logout } = useAuth();
  const nav = useNavigate();
  const [open, setOpen] = useState(true);

  async function handleLogout() {
    await logout();
    nav('/login');
  }

  return (
    <div className="min-h-screen flex bg-slate-50">
      <aside className={clsx(
        'border-r border-slate-200 bg-white transition-all',
        open ? 'w-56' : 'w-14'
      )}>
        <div className="flex items-center justify-between px-4 py-3 border-b border-slate-200">
          {open && (
            <div>
              <div className="font-semibold text-brand-600">PulseDesk</div>
              <div className="text-xs text-slate-500 truncate">{user?.account.company_name}</div>
            </div>
          )}
          <button className="btn-ghost btn p-1 text-lg" onClick={() => setOpen(!open)} title="Toggle">
            {open ? '◀' : '▶'}
          </button>
        </div>
        <nav className="py-2">
          {NAV.map((n) => (
            <NavLink key={n.to} to={n.to}
              className={({ isActive }) => clsx(
                'flex items-center gap-3 px-4 py-2 text-sm transition',
                isActive
                  ? 'bg-brand-50 text-brand-700 border-l-2 border-brand-600'
                  : 'text-slate-600 hover:bg-slate-50 border-l-2 border-transparent'
              )}>
              <span>{n.icon}</span>
              {open && <span>{n.label}</span>}
            </NavLink>
          ))}
        </nav>
      </aside>

      <div className="flex-1 flex flex-col min-w-0">
        <header className="h-12 px-4 border-b border-slate-200 bg-white flex items-center justify-between text-sm">
          <div className="text-slate-500">
            Signed in to <span className="font-medium text-slate-700">{user?.account.subdomain}</span>
            <span className="ml-2 pill bg-slate-100 text-slate-600">{user?.account.plan}</span>
          </div>
          <div className="flex items-center gap-3">
            <div className="text-slate-700">
              <span className="font-medium">{user?.name}</span>
              <span className="ml-2 pill bg-brand-50 text-brand-700">{user?.role}</span>
            </div>
            <button onClick={handleLogout} className="btn">Logout</button>
          </div>
        </header>

        <main className="flex-1 overflow-auto">
          <div className="p-6 max-w-7xl mx-auto">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}

export default function DashboardLayout() {
  return (
    <AuthProvider>
      <Inner />
    </AuthProvider>
  );
}
