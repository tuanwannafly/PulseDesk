import { useQuery } from '@tanstack/react-query';
import { useParams, Link } from 'react-router-dom';
import api from '../lib/api';

interface Ticket { id: number; subject: string; status: string; priority: string; }
interface Customer {
  id: number; name: string; email: string; notes: string | null;
  tickets: Ticket[];
}

export default function CustomerDetailPage() {
  const { id } = useParams();
  const { data, isLoading } = useQuery({
    queryKey: ['customer', id],
    queryFn: async () => (await api.get<Customer>(`/api/customers/${id}`)).data
  });

  if (isLoading || !data) return <div className="text-slate-500">Loading…</div>;
  return (
    <div className="space-y-4">
      <Link to="/customers" className="text-xs text-brand-600 hover:underline">← Customers</Link>
      <div className="card p-4">
        <h1 className="text-xl font-semibold">{data.name}</h1>
        <div className="text-sm text-slate-600">{data.email}</div>
        {data.notes && <p className="text-sm text-slate-500 mt-2">{data.notes}</p>}
      </div>

      <div className="card">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left text-xs uppercase text-slate-500">
            <tr>
              <th className="px-4 py-2">Subject</th>
              <th className="px-4 py-2">Status</th>
              <th className="px-4 py-2">Priority</th>
              <th className="px-4 py-2"></th>
            </tr>
          </thead>
          <tbody>
            {data.tickets.map((t) => (
              <tr key={t.id} className="border-t border-slate-100 hover:bg-slate-50">
                <td className="px-4 py-2">{t.subject}</td>
                <td className="px-4 py-2"><span className="pill bg-slate-100">{t.status}</span></td>
                <td className="px-4 py-2"><span className="pill bg-slate-100">{t.priority}</span></td>
                <td className="px-4 py-2">
                  <Link to={`/tickets/${t.id}`} className="text-brand-700 hover:underline text-sm">Open →</Link>
                </td>
              </tr>
            ))}
            {data.tickets.length === 0 && (
              <tr><td colSpan={4} className="px-4 py-8 text-center text-slate-400">No tickets yet.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
