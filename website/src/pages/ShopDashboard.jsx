import { api } from '../api';
import { Bars, ErrorBox, Loading, Stat, lastDays, money, useLoad } from '../ui';

export default function ShopDashboard() {
  const { data, error, loading } = useLoad(() => api.get('shop_stats.php'), []);
  if (loading) return <Loading />;
  if (error) return <ErrorBox error={error} />;
  const s = data;
  return (
    <>
      <h1>Shop dashboard</h1>
      <div className="stats">
        <Stat label="Sales today" value={money(s.today)} />
        <Stat label="Sales this week" value={money(s.week)} />
        <Stat label="Last week" value={money(s.last_week)} />
        <Stat label="Pending orders" value={s.pending_orders} />
        <Stat label="Stock value" value={money(s.stock_value)} />
        <Stat label="Out of stock" value={s.out_of_stock} />
        <Stat label="Low stock" value={s.low_stock} />
        <Stat label="Rating" value={s.rating ? Number(s.rating).toFixed(1) : '—'} />
      </div>
      <div className="card">
        <h3>Last 7 days</h3>
        <Bars values={s.daily} labels={lastDays(s.daily.length)} />
      </div>
      <div className="card">
        <h3>Top parts</h3>
        {s.top_parts.length === 0 && <span className="muted">No sale yet.</span>}
        {s.top_parts.map((p, i) => (
          <div className="row between" key={i}>
            <span>{p.name}</span>
            <span className="muted">{p.sold ?? p.qty ?? p.count}</span>
          </div>
        ))}
      </div>
    </>
  );
}
