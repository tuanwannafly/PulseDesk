import { useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import api from '../lib/api';

interface Customer { id: number; name: string; email: string; }

interface Form {
  subject: string;
  body: string;
  customer_id: number;
  priority: 'low' | 'normal' | 'high' | 'urgent';
}

export default function NewTicketPage() {
  const nav = useNavigate();
  const qc = useQueryClient();
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<Form>({
    defaultValues: { priority: 'normal', customer_id: 0 }
  });

  const { data: customers } = useQuery({
    queryKey: ['customers'],
    queryFn: async () => (await api.get<{ customers: Customer[] }>('/api/customers')).data.customers
  });

  const create = useMutation({
    mutationFn: (payload: Form) => api.post('/api/tickets', { ticket: payload }),
    onSuccess: () => {
      toast.success('Ticket created. AI classification queued.');
      qc.invalidateQueries({ queryKey: ['tickets'] });
      nav('/inbox');
    },
    onError: (e: any) => toast.error(e?.response?.data?.error || 'Create failed')
  });

  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-xl font-semibold mb-4">New ticket</h1>
      <form onSubmit={handleSubmit((v) => create.mutate(v))} className="card p-6 space-y-4">
        <div>
          <label className="label">Subject</label>
          <input className="input" {...register('subject', { required: true })} />
          {errors.subject && <p className="text-xs text-red-600 mt-1">Required</p>}
        </div>

        <div>
          <label className="label">Customer</label>
          <select className="input" {...register('customer_id', { required: true, valueAsNumber: true })}>
            <option value={0}>Select a customer…</option>
            {customers?.map((c) => (
              <option key={c.id} value={c.id}>{c.name} — {c.email}</option>
            ))}
          </select>
          {errors.customer_id && <p className="text-xs text-red-600 mt-1">Required</p>}
        </div>

        <div>
          <label className="label">Initial message</label>
          <textarea rows={6} className="input"
            {...register('body', { required: true, minLength: 5 })} />
          {errors.body && <p className="text-xs text-red-600 mt-1">Min 5 chars</p>}
        </div>

        <div>
          <label className="label">Priority</label>
          <select className="input" {...register('priority')}>
            <option value="low">low</option>
            <option value="normal">normal</option>
            <option value="high">high</option>
            <option value="urgent">urgent</option>
          </select>
        </div>

        <div className="flex justify-end gap-2 pt-2">
          <button type="button" className="btn" onClick={() => nav(-1)}>Cancel</button>
          <button type="submit" className="btn btn-primary" disabled={isSubmitting || create.isPending}>
            {create.isPending ? 'Creating…' : 'Create ticket'}
          </button>
        </div>
      </form>
    </div>
  );
}
