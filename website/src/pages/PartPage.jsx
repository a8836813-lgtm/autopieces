import { Link, useParams } from 'react-router-dom';
import { api } from '../api';
import { PartArt } from '../art';
import { Badge, Empty, ErrorBox, Loading, money, useAction, useLoad } from '../ui';

export default function PartPage() {
  const { id } = useParams();
  const act = useAction();
  const part = useLoad(() => api.get('parts.php', { id }), [id]);
  const offers = useLoad(async () => {
    const p = (await api.get('parts.php', { id })).part;
    const r = await api.get('parts_search.php', { q: p.oem || p.name });
    return r.results.filter((x) => String(x.part_id) === String(id));
  }, [id]);
  const alerts = useLoad(() => api.get('price_alerts.php'), []);

  if (part.loading || offers.loading) return <Loading />;
  if (part.error) return <ErrorBox error={part.error} />;
  const p = part.data.part;
  const list = [...(offers.data || [])].sort((a, b) => a.price - b.price);
  const cheapest = list[0];
  const highest = list[list.length - 1];
  const alert = alerts.data?.alerts?.find((a) => String(a.part_id) === String(id));

  function reserve(o) {
    act.run(async () => {
      await api.post('reservations.php', { action: 'create', stock_id: o.stock_id });
      offers.reload();
    });
  }

  function toggleAlert() {
    act.run(async () => {
      if (alert) {
        await api.post('price_alerts.php', { action: 'delete', part_id: p.id });
      } else {
        const v = window.prompt('Alert me when the price is at or below (DA):', String(cheapest ? Math.max(1, cheapest.price - 500) : ''));
        if (!v) return;
        await api.post('price_alerts.php', { action: 'set', part_id: p.id, target_price: Number(v) });
      }
      alerts.reload();
    });
  }

  return (
    <>
      <div className="row between">
        <div className="item"><PartArt category={p.category} size={64} /><h1 style={{ margin: 0 }}>{p.name}</h1></div>
        <button className="btn ghost" onClick={toggleAlert}>{alert ? '🔔 Alert on' : '🔔 Price alert'}</button>
      </div>
      <div className="card stack">
        <div className="muted">Serial {p.oem || '—'} · {p.category} · {p.fits}</div>
        {cheapest && (
          <div className="row">
            <span className="price">Best price {money(cheapest.price)}</span>
            {highest && highest.price > cheapest.price && (
              <Badge tone="good">Save up to {money(highest.price - cheapest.price)}</Badge>
            )}
            <span className="muted">{list.length} shop{list.length > 1 ? 's' : ''}</span>
          </div>
        )}
      </div>
      <ErrorBox error={act.error} />
      <h2>Compare shops</h2>
      {list.length === 0 ? (
        <Empty>No shop has this part in stock right now. Set a price alert to be told when it comes back.</Empty>
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr><th>Shop</th><th>Condition</th><th>Stock</th><th>Price</th><th>Difference</th><th /></tr>
            </thead>
            <tbody>
              {list.map((o, i) => (
                <tr key={o.stock_id}>
                  <td>
                    <Link to={`/shop/${o.shop_id}`}>{o.shop_name}</Link>
                    <div className="muted small">{o.hours} · {o.open_now ? 'Open' : 'Closed'}</div>
                  </td>
                  <td>{o.part_condition}</td>
                  <td>{o.quantity}</td>
                  <td className="price">{money(o.price)}</td>
                  <td>{i === 0 ? <Badge tone="good">Cheapest</Badge> : `+${money(o.price - cheapest.price)}`}</td>
                  <td><button className="btn small" disabled={act.busy} onClick={() => reserve(o)}>Reserve</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}
