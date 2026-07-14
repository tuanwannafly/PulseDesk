import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useParams, Link } from 'react-router-dom';
import { useState } from 'react';
import toast from 'react-hot-toast';
import api from '../lib/api';
import StatusBadge from '../components/StatusBadge';
import PriorityBadge from '../components/PriorityBadge';
import SentimentBadge from '../components/SentimentBadge';
import { useAuth } from '../lib/auth';

interface Message {
  id: number;
  sender_type: 'agent' | 'customer';
  body: string;
  created_at: string;
  user: { name: string } | null;
  customer: { name: string; email: string } | null;
}

interface Ticket {
  id: number;
  subject: string;
  status: 'open' | 'pending' | 'resolved';
  priority: 'low' | 'normal' | 'high' | 'urgent';
  ai_summary: string | null;
  ai_suggested_priority: string | null;
  sentiment_score: number | null;
  first_response_at: string | null;
  resolved_at: string | null;
  created_at: string;
  escalated_at: string | null;
  customer: { id: number; name: string; email: string };
  assigned_to: { id: number; name: string } | null;
  tags: Array<{ id: number; name: string; color: string }>;
  messages: Message[];
}

export default function TicketDetailPage() {
  const { id } = useParams();
  const qc = useQueryClient();
  const { user } = useAuth();
  const [reply, setReply] = useState('');

  const { data: ticket, isLoading } = useQuery({
    queryKey: ['ticket', id],
    queryFn: async () => (await api.get<Ticket>(`/api/tickets/${id}`)).data
  });

  const claim = useMutation({
    mutationFn: () => api.post(`/api/tickets/${id}/claim`),
    onSuccess: () => {
      toast.success('Ticket claimed.');
      qc.invalidateQueries({ queryKey: ['ticket', id] });
      qc.invalidateQueries({ queryKey: ['tickets'] });
    },
    onError: (e: any) => toast.error(e?.response?.data?.error || 'Claim failed')
  });

  const resolve = useMutation({
    mutationFn: () => api.post(`/api/tickets/${id}/resolve`),
    onSuccess: () => {
      toast.success('Ticket resolved.');
      qc.invalidateQueries({ queryKey: ['ticket', id] });
      qc.invalidateQueries({ queryKey: ['tickets'] });
    }
  });

  const reopen = useMutation({
    mutationFn: () => api.post(`/api/tickets/${id}/reopen`),
    onSuccess: () => {
      toast.success('Reopened.');
      qc.invalidateQueries({ queryKey: ['ticket', id] });
      qc.invalidateQueries({ queryKey: ['tickets'] });
    }
  });

  const sendReply = useMutation({
    mutationFn: (body: string) => api.post(`/api/tickets/${id}/messages`, { body }),
    onSuccess: () => {
      setReply('');
      toast.success('Reply sent. AI classification re-queued.');
      qc.invalidateQueries({ queryKey: ['ticket', id] });
      qc.invalidateQueries({ queryKey: ['tickets'] });
    },
    onError: (e: any) => toast.error(e?.response?.data?.error || 'Send failed')
  });

  if (isLoading || !ticket) {
    return <div className="text-slate-500">Loading…</div>;
  }

  const mine = ticket.assigned_to?.id === user?.id;
  const unassigned = !ticket.assigned_to;

  return (
    <div className="grid grid-cols-3 gap-6">
      <div className="col-span-2 space-y-4">
        <div className="card p-4">
          <div className="flex items-center justify-between">
            <div>
              <Link to="/inbox" className="text-xs text-brand-600 hover:underline">← Inbox</Link>
              <h1 className="text-xl font-semibold mt-1">{ticket.subject}</h1>
            </div>
            <div className="flex gap-2">
              {unassigned && (
                <button onClick={() => claim.mutate()} className="btn btn-primary"
                        disabled={claim.isPending}>
                  {claim.isPending ? 'Claiming…' : '🎯 Claim'}
                </button>
              )}
              {mine && ticket.status !== 'resolved' && (
                <button onClick={() => resolve.mutate()} className="btn btn-primary">
                  ✓ Resolve
                </button>
              )}
              {ticket.status === 'resolved' && (
                <button onClick={() => reopen.mutate()} className="btn">Re-open</button>
              )}
            </div>
          </div>

          <div className="flex items-center gap-3 text-sm text-slate-600 mt-3">
            <Link to={`/customers/${ticket.customer.id}`} className="text-brand-700 hover:underline">
              {ticket.customer.name}
            </Link>
            <span>·</span>
            <span>{ticket.customer.email}</span>
            <span>·</span>
            <span className="text-slate-400 text-xs">opened {new Date(ticket.created_at).toLocaleString()}</span>
          </div>

          {ticket.ai_summary && (
            <div className="mt-3 p-3 bg-brand-50 border border-brand-200 rounded text-sm">
              <span className="font-medium">🤖 AI:</span> {ticket.ai_summary}
              {ticket.ai_suggested_priority && ticket.ai_suggested_priority !== ticket.priority && (
                <div className="text-xs text-slate-600 mt-1">
                  Suggested priority: <b>{ticket.ai_suggested_priority}</b> (current: {ticket.priority})
                </div>
              )}
            </div>
          )}

          <div className="flex flex-wrap items-center gap-3 mt-3">
            <StatusBadge status={ticket.status} />
            <PriorityBadge priority={ticket.priority} />
            <SentimentBadge score={ticket.sentiment_score} />
            {ticket.assigned_to ? (
              <span className="pill bg-slate-100 text-slate-700">→ {ticket.assigned_to.name}</span>
            ) : (
              <span className="pill bg-slate-100 text-slate-400">unassigned</span>
            )}
            {ticket.tags.map((t) => (
              <span key={t.id} className="pill text-white"
                    style={{ backgroundColor: t.color }}>{t.name}</span>
            ))}
          </div>
        </div>

        <div className="card p-4 space-y-3">
          <h2 className="text-sm font-semibold text-slate-500 uppercase tracking-wide">Conversation</h2>
          {ticket.messages.map((m) => (
            <div key={m.id} className="flex gap-3">
              <div className={`h-9 w-9 rounded-full flex items-center justify-center text-white text-sm shrink-0
                              ${m.sender_type === 'agent' ? 'bg-brand-600' : 'bg-slate-500'}`}>
                {m.sender_type === 'agent' ? '🧑' : '👤'}
              </div>
              <div className="flex-1">
                <div className="text-xs text-slate-500 mb-1">
                  <span className="font-medium text-slate-700">
                    {m.user?.name || m.customer?.name || 'Unknown'}
                  </span>
                  <span className="ml-2 text-slate-400">
                    {new Date(m.created_at).toLocaleString()}
                  </span>
                </div>
                <div className={`rounded-lg p-3 ${m.sender_type === 'agent' ? 'bg-brand-50' : 'bg-slate-50'}`}>
                  <p className="text-sm whitespace-pre-wrap">{m.body}</p>
                </div>
              </div>
            </div>
          ))}

          {ticket.status !== 'resolved' && (
            <form
              onSubmit={(e) => { e.preventDefault(); if (reply.trim()) sendReply.mutate(reply); }}
              className="pt-3 border-t border-slate-200">
              <textarea
                value={reply}
                onChange={(e) => setReply(e.target.value)}
                rows={3}
                placeholder="Type your reply…"
                className="input"
              />
              <div className="flex justify-end mt-2">
                <button type="submit" className="btn btn-primary"
                        disabled={!reply.trim() || sendReply.isPending}>
                  {sendReply.isPending ? 'Sending…' : 'Send reply'}
                </button>
              </div>
            </form>
          )}
        </div>
      </div>

      <div className="space-y-4">
        <div className="card p-4 text-sm space-y-2">
          <h3 className="font-semibold text-slate-500 uppercase text-xs tracking-wide">Meta</h3>
          <Row k="First response"  v={ticket.first_response_at ? new Date(ticket.first_response_at).toLocaleString() : '—'} />
          <Row k="Resolved"        v={ticket.resolved_at ? new Date(ticket.resolved_at).toLocaleString() : '—'} />
          <Row k="Escalated"       v={ticket.escalated_at ? new Date(ticket.escalated_at).toLocaleString() : '—'} />
          <Row k="Account"         v={user?.account.company_name} />
        </div>
      </div>
    </div>
  );
}

function Row({ k, v }: { k: string; v: any }) {
  return (
    <div className="flex justify-between gap-3 text-xs">
      <span className="text-slate-500">{k}</span>
      <span className="text-slate-700 text-right">{v}</span>
    </div>
  );
}
