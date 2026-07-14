import { useQuery } from '@tanstack/react-query';
import api from '../lib/api';

interface AgentRow { agent_name: string; avg_response_hours: number | null; tickets_handled: number; }
interface SentRow   { week: string; avg_sentiment: number; ticket_count: number; moving_avg_4w: number | null; }
interface TagRow    { tag_name: string; usage_count: number; tag_color: string; }

interface Response {
  avg_response_time_per_agent: { rows: AgentRow[] };
  sentiment_trend_by_week:     { rows: SentRow[] };
  top_tags:                    { rows: TagRow[] };
}

export default function DashboardPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['dashboard'],
    queryFn: async () => (await api.get<Response>('/api/dashboard')).data
  });

  if (isLoading || !data) return <div className="text-slate-500">Loading analytics…</div>;

  const agents = data.avg_response_time_per_agent.rows;
  const trend  = data.sentiment_trend_by_week.rows;
  const tags   = data.top_tags.rows;

  // Build min-max for chart normalisation
  const trendMin = Math.min(...trend.map((r) => r.avg_sentiment || 0));
  const trendMax = Math.max(...trend.map((r) => r.avg_sentiment || 0));
  const range    = Math.max(0.01, trendMax - trendMin);

  return (
    <div className="space-y-6">
      <h1 className="text-xl font-semibold">Analytics</h1>

      <div className="card p-4">
        <h2 className="font-semibold mb-3">Average response time per agent (hours)</h2>
        {agents.length === 0 && <p className="text-sm text-slate-400">No data yet.</p>}
        {agents.map((a) => (
          <div key={a.agent_name} className="mb-2">
            <div className="flex justify-between text-sm">
              <span>{a.agent_name}</span>
              <span className="text-slate-500">
                {a.avg_response_hours != null ? a.avg_response_hours.toFixed(2) + 'h' : '—'}
                <span className="ml-2 text-xs">({a.tickets_handled} tickets)</span>
              </span>
            </div>
            <div className="h-2 rounded-full bg-slate-100 mt-1 overflow-hidden">
              <div className="h-full bg-brand-500"
                   style={{ width: `${Math.min(100, ((a.avg_response_hours || 0) / 24) * 100)}%` }} />
            </div>
          </div>
        ))}
      </div>

      <div className="card p-4">
        <h2 className="font-semibold mb-3">Sentiment trend (weekly)</h2>
        {trend.length === 0 && <p className="text-sm text-slate-400">No data yet.</p>}
        <div className="flex items-end gap-1 h-32">
          {trend.map((r) => {
            const v = ((r.avg_sentiment || 0) - trendMin) / range;
            return (
              <div key={r.week} className="flex-1 flex flex-col items-center justify-end group">
                <div className={`w-full rounded-t ${r.avg_sentiment > 0 ? 'bg-green-400' : r.avg_sentiment < 0 ? 'bg-red-400' : 'bg-slate-400'}`}
                     style={{ height: `${Math.max(4, v * 100)}%` }}
                     title={`${r.week}: ${(r.avg_sentiment || 0).toFixed(2)} (${r.ticket_count} tickets)`} />
                <div className="text-[10px] text-slate-400 mt-1 -rotate-45 origin-left whitespace-nowrap">{r.week.slice(5)}</div>
              </div>
            );
          })}
        </div>
        <p className="text-xs text-slate-500 mt-2">
          Hover bars for details. Range {trendMin.toFixed(2)} … {trendMax.toFixed(2)}.
        </p>
      </div>

      <div className="card p-4">
        <h2 className="font-semibold mb-3">Top tags by usage</h2>
        {tags.length === 0 && <p className="text-sm text-slate-400">No data yet.</p>}
        {tags.map((t) => (
          <div key={t.tag_name} className="flex items-center gap-2 py-1">
            <span className="w-3 h-3 rounded" style={{ backgroundColor: t.tag_color }} />
            <span className="w-32 text-sm">{t.tag_name}</span>
            <div className="flex-1 h-2 rounded-full bg-slate-100 overflow-hidden">
              <div className="h-full" style={{
                backgroundColor: t.tag_color,
                width: `${Math.min(100, t.usage_count * 10)}%`
              }} />
            </div>
            <span className="text-xs text-slate-500 w-10 text-right">{t.usage_count}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
