import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import api from '../lib/api';

interface Customer {
  id: number;
  name: string;
  email: string;
  tickets_count: number;
}

export default function CustomersPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['customers'],
    queryFn: async () => (await api.get<{ customers: Customer[] }>('/api/customers')).data
  });
  return (
    <div className="space-y-4">
      <h1 className="text-xl font-semibold">Customers</h1>
      <div className="card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left text-xs uppercase text-slate-500">
            <tr>
              <th className="px-4 py-2">Name</th>
              <th className="px-4 py-2">Email</th>
              <th className="px-4 py-2">Tickets</th>
              <th className="px-4 py-2">Actions</th>
            </tr>
          </thead>
          <tbody className={isLoading ? 'opacity-60' : ''}>
            {data?.customers.map((c) => (
              <tr key={c.id} className="border-t border-slate-100 hover:bg-slate-50">
                <td className="px-4 py-2 font-medium">{c.name}</td>
                <td className="px-4 py-2 text-slate-600">{c.email}</td>
                <td className="px-4 py-2">{c.tickets_count}</td>
                <td className="px-4 py-2">
                  <Link to={`/customers/${c.id}`} className="text-brand-700 hover:underline text-sm">
                    View →
                  </Link>
                </td>
              </tr>
            ))}
            {(data?.customers.length ?? 0) === 0 && !isLoading && (
              <tr><td colSpan={4} className="px-4 py-8 text-center text-slate-400">No customers yet.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
