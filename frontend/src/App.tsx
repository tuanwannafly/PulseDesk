import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './lib/auth';
import LoginPage from './pages/LoginPage';
import DashboardLayout from './layouts/DashboardLayout';
import InboxPage from './pages/InboxPage';
import TicketDetailPage from './pages/TicketDetailPage';
import CustomersPage from './pages/CustomersPage';
import CustomerDetailPage from './pages/CustomerDetailPage';
import TagsPage from './pages/TagsPage';
import DashboardPage from './pages/DashboardPage';
import NewTicketPage from './pages/NewTicketPage';

function Protected({ children }: { children: JSX.Element }) {
  const { user, loading } = useAuth();
  if (loading) {
    return <div className="flex h-screen items-center justify-center text-slate-500">Loading…</div>;
  }
  if (!user) return <Navigate to="/login" replace />;
  return children;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        path="/"
        element={<Protected><DashboardLayout /></Protected>}
      >
        <Route index element={<Navigate to="/inbox" replace />} />
        <Route path="inbox"         element={<InboxPage />} />
        <Route path="inbox/new"     element={<NewTicketPage />} />
        <Route path="tickets/:id"   element={<TicketDetailPage />} />
        <Route path="customers"      element={<CustomersPage />} />
        <Route path="customers/:id"  element={<CustomerDetailPage />} />
        <Route path="tags"          element={<TagsPage />} />
        <Route path="dashboard"     element={<DashboardPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/inbox" replace />} />
    </Routes>
  );
}
