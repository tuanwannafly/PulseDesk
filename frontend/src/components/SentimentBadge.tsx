interface Props { score: number | null | undefined; }

export default function SentimentBadge({ score }: Props) {
  if (score == null) return <span className="pill bg-slate-100 text-slate-400">—</span>;
  const pct = Math.round((score + 1) * 50); // -1..1 -> 0..100
  const label = score > 0.2 ? 'positive' : score < -0.2 ? 'negative' : 'neutral';
  const color =
    score > 0.2 ? 'bg-green-50 text-green-700' :
    score < -0.2 ? 'bg-red-50 text-red-700' :
                   'bg-slate-100 text-slate-600';

  return (
    <div className="flex items-center gap-2">
      <div className="w-16 h-1.5 rounded-full bg-slate-200 overflow-hidden">
        <div className={`h-full ${score > 0.2 ? 'bg-green-500' : score < -0.2 ? 'bg-red-500' : 'bg-slate-400'}`}
             style={{ width: `${pct}%` }} />
      </div>
      <span className={`pill ${color} text-xs`}>{label}</span>
    </div>
  );
}
