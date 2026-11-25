import { api } from '../api';
import { Bars, ErrorBox, Loading, Stat, lastDays, money, useLoad } from '../ui';

export default function MechanicDashboard() {
  const { data, error, loading } = useLoad(() => api.get('mechanic_stats.php'), []);
  if (loading) return <Loading />;
  if (error) return <ErrorBox error={error} />;
  const s = data;
  return (
    <>
      <h1>Mechanic dashboard</h1>
      <div className="stats">
        <Stat label="Earned today" value={money(s.today)} />
        <Stat label="Earned this week" value={money(s.week)} />
        <Stat label="Last week" value={money(s.last_week)} />
        <Stat label="Unpaid" value={money(s.unpaid)} />
        <Stat label="Jobs done" value={s.jobs_done} />
        <Stat label="New requests" value={s.jobs.New} />
        <Stat label="In progress" value={s.jobs['In progress']} />
        <Stat label="Reports" value={s.reports} />
        <Stat label="Rating" value={s.rating ? Number(s.rating).toFixed(1) : '—'} />
      </div>
      <div className="card">
        <h3>Last 7 days</h3>
        <Bars values={s.daily} labels={lastDays(s.daily.length)} />
      </div>
    </>
  );
}
