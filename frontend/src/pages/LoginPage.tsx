import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import toast from 'react-hot-toast';
import { useAuth, AuthProvider } from '../lib/auth';

interface Form {
  subdomain: string;
  email: string;
  password: string;
}

const PRESETS = [
  { subdomain: 'acme',    label: 'Acme Corp · pro' },
  { subdomain: 'globex',  label: 'Globex · free' },
  { subdomain: 'initech', label: 'Initech · enterprise' }
];

function Inner() {
  const { login } = useAuth();
  const nav = useNavigate();
  const { register, handleSubmit, setValue, formState: { errors, isSubmitting } } = useForm<Form>({
    defaultValues: { subdomain: 'acme', email: 'admin@acme.test', password: 'password123' }
  });
  const [err, setErr] = useState<string | null>(null);

  async function onSubmit(values: Form) {
    setErr(null);
    try {
      await login(values.subdomain.trim(), values.email.trim(), values.password);
      toast.success('Welcome back!');
      nav('/inbox');
    } catch (e: any) {
      setErr(e?.response?.data?.error || 'Login failed');
    }
  }

  function applyPreset(s: string) {
    setValue('subdomain', s);
    setValue('email', `admin@${s}.test`);
    setValue('password', 'password123');
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-100 to-brand-50 p-6">
      <div className="card w-full max-w-md overflow-hidden">
        <div className="bg-brand-600 text-white p-6">
          <h1 className="text-2xl font-bold">PulseDesk</h1>
          <p className="text-brand-100 text-sm mt-1">Multi-tenant support console</p>
        </div>
        <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-4">
          <div>
            <label className="label">Tenant subdomain</label>
            <input className="input" {...register('subdomain', { required: true })} />
            {errors.subdomain && <p className="text-red-600 text-xs mt-1">Required</p>}
            <div className="flex flex-wrap gap-1 mt-2">
              {PRESETS.map(p => (
                <button key={p.subdomain} type="button"
                  onClick={() => applyPreset(p.subdomain)}
                  className="text-xs px-2 py-1 rounded border border-slate-200 hover:border-brand-400 hover:bg-brand-50 text-slate-600">
                  {p.label}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="label">Email</label>
            <input className="input" type="email" {...register('email', { required: true })} />
          </div>

          <div>
            <label className="label">Password</label>
            <input className="input" type="password" {...register('password', { required: true })} />
          </div>

          {err && <div className="text-sm text-red-600 bg-red-50 border border-red-200 rounded p-2">{err}</div>}

          <button type="submit" disabled={isSubmitting} className="btn btn-primary w-full">
            {isSubmitting ? 'Signing in…' : 'Sign in'}
          </button>

          <p className="text-xs text-slate-500 text-center pt-2">
            Demo password is <code className="text-slate-700">password123</code>
          </p>
        </form>
      </div>
    </div>
  );
}

export default function LoginPage() {
  return (
    <AuthProvider>
      <Inner />
    </AuthProvider>
  );
}
