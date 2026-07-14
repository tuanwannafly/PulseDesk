import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import toast from 'react-hot-toast';
import api from '../lib/api';

interface Tag { id: number; name: string; color: string; tickets_count: number; }

export default function TagsPage() {
  const qc = useQueryClient();
  const { data, isLoading } = useQuery({
    queryKey: ['tags'],
    queryFn: async () => (await api.get<{ tags: Tag[] }>('/api/tags')).data
  });
  const [name, setName] = useState('');
  const [color, setColor] = useState('#6366f1');

  const create = useMutation({
    mutationFn: () => api.post('/api/tags', { tag: { name, color } }),
    onSuccess: () => {
      setName('');
      toast.success('Tag created.');
      qc.invalidateQueries({ queryKey: ['tags'] });
    },
    onError: (e: any) => toast.error(e?.response?.data?.error || 'Failed')
  });

  const remove = useMutation({
    mutationFn: (id: number) => api.delete(`/api/tags/${id}`),
    onSuccess: () => {
      toast.success('Deleted.');
      qc.invalidateQueries({ queryKey: ['tags'] });
    }
  });

  return (
    <div className="space-y-4 max-w-xl">
      <h1 className="text-xl font-semibold">Tags</h1>

      <form onSubmit={(e) => { e.preventDefault(); if (name.trim()) create.mutate(); }}
            className="card p-4 flex items-end gap-2">
        <div className="flex-1">
          <label className="label">New tag name</label>
          <input className="input" value={name} onChange={(e) => setName(e.target.value)} />
        </div>
        <div>
          <label className="label">Color</label>
          <input type="color" value={color} onChange={(e) => setColor(e.target.value)}
                 className="h-9 w-12 rounded border border-slate-300" />
        </div>
        <button className="btn btn-primary" disabled={!name.trim() || create.isPending}>Add</button>
      </form>

      <div className="card p-2">
        {(data?.tags ?? []).map((t) => (
          <div key={t.id}
               className="flex items-center justify-between px-3 py-2 hover:bg-slate-50 rounded">
            <div className="flex items-center gap-2">
              <span className="w-4 h-4 rounded" style={{ backgroundColor: t.color }} />
              <span className="font-medium">{t.name}</span>
              <span className="text-xs text-slate-400">{t.tickets_count} ticket{t.tickets_count !== 1 ? 's' : ''}</span>
            </div>
            <button onClick={() => remove.mutate(t.id)} className="btn btn-ghost text-red-500"
                    title="Delete">
              ✕
            </button>
          </div>
        ))}
        {(!data || data.tags.length === 0) && !isLoading && (
          <div className="p-6 text-center text-slate-400">No tags yet.</div>
        )}
      </div>
    </div>
  );
}
