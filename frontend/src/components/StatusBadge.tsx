interface Props { status: 'open' | 'pending' | 'resolved'; }

const STYLES: Record<string, string> = {
  open:     'bg-blue-50 text-blue-700 border border-blue-200',
  pending:  'bg-amber-50 text-amber-700 border border-amber-200',
  resolved: 'bg-green-50 text-green-700 border border-green-200'
};

export default function StatusBadge({ status }: Props) {
  return <span className={`pill ${STYLES[status] || ''}`}>{status}</span>;
}
