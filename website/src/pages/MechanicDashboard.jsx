import { Link } from 'react-router-dom';
import { api } from '../api';
import { useAuth } from '../auth';
import { Bars, Empty, ErrorBox, Loading, Stat, StatusBadge, lastDays, money, useLoad } from '../ui';

export default function MechanicDashboard() {
  const { user } = useAuth();
  const stats = useLoad(() => api.get('mechanic_stats.php'), []);
  const jobs = useLoad(() => api.get('jobs.php'), []);
  const reports = useLoad(() => api.get('reports.php'), []);
  if (stats.loading) return <Loading />;
  if (stats.error) return <ErrorBox error={stats.error} />;
  const s = stats.data;
  const active = (jobs.data?.jobs || []).filter((j) => ['New', 'Accepted', 'In progress'].includes(j.status)).slice(0, 6);
  const mine = (reports.data?.reports || []).filter((r) => r.mechanic_id === user.mechanic_id).slice(0, 4);

  return (
    <>
      <h1>Mechanic dashboard</h1>
      <div className="quick">
        <Link className="btn" to="/jobs">Jobs ({s.jobs.New} new)</Link>
        <Link className="btn ghost" to="/reports">+ New report</Link>
        <Link className="btn ghost" to="/profile">Edit profile</Link>
      </div>
      <div className="stats">
        <Stat label="Earned today" value={money(s.today)} />
        <Stat label="Earned this week" value={money(s.week)} />
        <Stat label="Unpaid invoices" value={money(s.unpaid)} />
        <Stat label="Jobs done" value={s.jobs_done} />
        <Stat label="New requests" value={s.jobs.New} />
        <Stat label="In progress" value={s.jobs['In progress']} />
        <Stat label="Reports" value={s.reports} />
        <Stat label="Rating" value={s.rating ? Number(s.rating).toFixed(1) : '—'} />
      </div>
      <div className="panels">
        <div className="card">
          <h3>Earnings, last 7 days</h3>
          <Bars values={s.daily} labels={lastDays(s.daily.length)} />
        </div>
        <div className="card">
          <h3>Open jobs</h3>
          {active.length === 0 && <Empty>No open job.</Empty>}
          {active.map((j) => (
            <div className="list-row" key={j.id}>
              <span>{j.client_name}<div className="muted small">{j.problem}</div></span>
              <StatusBadge status={j.status} />
            </div>
          ))}
        </div>
        <div className="card">
          <h3>My latest reports</h3>
          {mine.length === 0 && <span className="muted">No report yet.</span>}
          {mine.map((r) => (
            <div className="list-row" key={r.id}><span>{r.title}<div className="muted small">{r.car}</div></span><b>{money(r.cost)}</b></div>
          ))}
        </div>
      </div>
    </>
  );
}
