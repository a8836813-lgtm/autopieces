import { Link } from 'react-router-dom';
import { api } from '../api';
import { useAuth } from '../auth';
import { Bars, Empty, ErrorBox, Loading, Stat, StatusBadge, lastDays, money, useLoad } from '../ui';

export default function ShopDashboard() {
  const { user } = useAuth();
  const stats = useLoad(() => api.get('shop_stats.php'), []);
  const orders = useLoad(() => api.get('reservations.php', { as: 'shop' }), []);
  const stock = useLoad(() => api.get('stock.php', { shop_id: user.shop_id }), []);
  if (stats.loading) return <Loading />;
  if (stats.error) return <ErrorBox error={stats.error} />;
  const s = stats.data;
  const recent = (orders.data?.reservations || []).slice(0, 6);
  const low = (stock.data?.stock || []).filter((i) => i.quantity <= 1).slice(0, 6);
  const change = s.last_week > 0 ? Math.round(((s.week - s.last_week) / s.last_week) * 100) : null;

  return (
    <>
      <h1>Shop dashboard</h1>
      <div className="quick">
        <Link className="btn" to="/stock">+ Add a part</Link>
        <Link className="btn ghost" to="/orders">Pending orders ({s.pending_orders})</Link>
        <Link className="btn ghost" to="/settings">Edit shop</Link>
      </div>
      <div className="stats">
        <Stat label="Sales today" value={money(s.today)} />
        <Stat label={change == null ? 'Sales this week' : `This week (${change >= 0 ? '+' : ''}${change}% vs last)`} value={money(s.week)} />
        <Stat label="Pending orders" value={s.pending_orders} />
        <Stat label="Stock value" value={money(s.stock_value)} />
        <Stat label="Out of stock" value={s.out_of_stock} />
        <Stat label="Low stock" value={s.low_stock} />
        <Stat label="Rating" value={s.rating ? Number(s.rating).toFixed(1) : '—'} />
      </div>
      <div className="panels">
        <div className="card">
          <h3>Sales, last 7 days</h3>
          <Bars values={s.daily} labels={lastDays(s.daily.length)} />
        </div>
        <div className="card">
          <h3>Top selling parts</h3>
          {s.top_parts.length === 0 && <span className="muted">No sale yet.</span>}
          {s.top_parts.map((p, i) => (
            <div className="list-row" key={i}><span>{p.name}</span><b>{p.sold}</b></div>
          ))}
        </div>
        <div className="card">
          <h3>Recent orders</h3>
          {recent.length === 0 && <Empty>No order yet.</Empty>}
          {recent.map((r) => (
            <div className="list-row" key={r.id}>
              <span>{r.part_name}<div className="muted small">{r.client_name}</div></span>
              <span className="row"><b>{money(r.price)}</b><StatusBadge status={r.status} /></span>
            </div>
          ))}
        </div>
        <div className="card">
          <h3>Needs restocking</h3>
          {low.length === 0 && <span className="muted">All good.</span>}
          {low.map((i) => (
            <div className="list-row" key={i.stock_id}>
              <span>{i.name}</span>
              <span className={i.quantity === 0 ? 'badge bad' : 'badge warn'}>{i.quantity === 0 ? 'Out' : `${i.quantity} left`}</span>
            </div>
          ))}
        </div>
      </div>
    </>
  );
}
