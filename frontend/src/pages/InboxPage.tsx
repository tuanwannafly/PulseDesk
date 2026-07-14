import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { useState } from 'react';
import clsx from 'clsx';
import api from '../lib/api';
import StatusBadge from '../components/StatusBadge';
import PriorityBadge from '../components/PriorityBadge';
import SentimentBadge from '../components/SentimentBadge';

interface Ticket {
  id: number;
  subject: string;
  status: 'open' | 'pending' | 'resolved';
  priority: 'low' | 'normal' | 'high' | 'urgent';
  ai_summary: string | null;
  ai_suggested_priority: string | null;
  sentiment_score: number | null;
  created_at: string;
  customer: { id: number; name: string; email: string };
  assigned_to: { id: number; name: string } | null;
  messages_count: number;
}

interface InboxResponse {
  tickets: Ticket[];
  stats: { open: number; pending: number; resolved: number };
}

const STATUSES = ['', 'open', 'pending', 'resolved'] as const;
const PRIORITIES = ['', 'low', 'normal', 'high', 'urgent'] as const;

export default function InboxPage() {
  const [status, setStatus] = useState<string>('');
  const [priority, setPriority] = useState<string>('');

  const { data, isLoading } = useQuery({
    queryKey: ['tickets', status, priority],
    queryFn: async () => {
      const params: Record<string,string> = {};
      if (status) params.status = status;
      if (priority) params.priority = priority;
      const { data } = await api.get<InboxResponse>('/api/tickets', { params });
      return data;
    }
  });

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-semibold">Inbox</h1>
        <Link to="/inbox/new" className="btn btn-primary">+ New ticket</Link>
      </div>

      <div className="grid grid-cols-3 gap-3">
        <div className="card p-3">
          <div className="text-xs text-slate-500">Open</div>
          <div className="text-2xl font-semibold text-blue-600">{data?.stats.open ?? '—'}</div>
        </div>
        <div className="card p-3">
          <div className="text-xs text-slate-500">Pending</div>
          <div className="text-2xl font-semibold text-amber-600">{data?.stats.pending ?? '—'}</div>
        </div>
        <div className="card p-3">
          <div className="text-xs text-slate-500">Resolved</div>
          <div className="text-2xl font-semibold text-green-600">{data?.stats.resolved ?? '—'}</div>
        </div>
      </div>

      <div className="card p-3 flex flex-wrap items-end gap-4">
        <div>
          <label className="label">Status</label>
          <select className="input" value={status} onChange={e => setStatus(e.target.value)}>
            {STATUSES.map(s => <option key={s} value={s}>{s || 'all'}</option>)}
          </select>
        </div>
        <div>
          <label className="label">Priority</label>
          <select className="input" value={priority} onChange={e => setPriority(e.target.value)}>
            {PRIORITIES.map(p => <option key={p} value={p}>{p || 'all'}</option>)}
          </select>
        </div>
        <div className="text-xs text-slate-500 ml-auto">
          {data?.tickets.length ?? 0} tickets
        </div>
      </div>

      <div className="card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left text-xs uppercase text-slate-500">
            <tr>
              <th className="px-4 py-2">ID</th>
              <th className="px-4 py-2">Subject</th>
              <th className="px-4 py-2">Customer</th>
              <th className="px-4 py-2">Status</th>
              <th className="px-4 py-2">Priority</th>
              <th className="px-4 py-2">Sentiment</th>
              <th className="px-4 py-2">Assignee</th>
              <th className="px-4 py-2">Replies</th>
            </tr>
          </thead>
          <tbody className={clsx(isLoading && 'opacity-60')}>
            {data?.tickets.map((t) => (
              <tr key={t.id} className="border-t border-slate-100 hover:bg-slate-50">
                <td className="px-4 py-2 text-slate-400">#{t.id}</td>
                <td className="px-4 py-2">
                  <Link to={`/tickets/${t.id}`} className="text-brand-700 hover:underline font-medium">
                    {t.subject}
                  </Link>
                  {t.ai_summary && (
                    <div className="text-xs text-slate-500 mt-0.5 line-clamp-1">
                      🤖 {t.ai_summary}
                    </div>
                  )}
                </td>
                <td className="px-4 py-2 text-slate-600">{t.customer.name}</td>
                <td className="px-4 py-2"><StatusBadge status={t.status} /></td>
                <td className="px-4 py-2"><PriorityBadge priority={t.priority} /></td>
                <td className="px-4 py-2"><SentimentBadge score={t.sentiment_score} /></td>
                <td className="px-4 py-2 text-slate-600">
                  {t.assigned_to ? t.assigned_to.name : <span className="text-slate-400 italic">unassigned</span>}
                </td>
                <td className="px-4 py-2 text-slate-500">{t.messages_count}</td>
              </tr>
            ))}
            {(data?.tickets.length ?? 0) === 0 && !isLoading && (
              <tr><td colSpan={8} className="px-4 py-8 text-center text-slate-400">No tickets.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
