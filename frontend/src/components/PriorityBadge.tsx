interface Props { priority: 'low' | 'normal' | 'high' | 'urgent' | string | null | undefined; }

const STYLES: Record<string, string> = {
  low:    'bg-slate-100 text-slate-600',
  normal: 'bg-blue-50 text-blue-700',
  high:   'bg-amber-50 text-amber-700',
  urgent: 'bg-red-50 text-red-700'
};

export default function PriorityBadge({ priority }: Props) {
  const p = (priority || 'normal') as string;
  return <span className={`pill ${STYLES[p]}`}>! {p}</span>;
}
