import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api';
import { REFERENCE } from '../config';
import { Badge, Empty, ErrorBox, Loading, money, useAction } from '../ui';

const CATEGORIES = ['', 'Brakes', 'Filters', 'Battery', 'Engine', 'Electrical', 'Suspension', 'Cooling', 'Body'];

export default function Search() {
  const [q, setQ] = useState('');
  const [category, setCategory] = useState('');
  const [sort, setSort] = useState('price');
  const [items, setItems] = useState(undefined);
  const [alerts, setAlerts] = useState([]);
  const [notice, setNotice] = useState('');
  const { busy, error, run, setError } = useAction();

  async function search() {
    setError(null);
    if (!q.trim() && !category) {
      setItems(undefined);
      return;
    }
    try {
      const params = { q, category };
      if (sort === 'nearest') Object.assign(params, { sort, lat: REFERENCE.lat, lng: REFERENCE.lng });
      const r = await api.get('parts_search.php', params);
      setItems(r.results);
    } catch (e) {
      setError(e);
    }
  }

  async function loadAlerts() {
    try {
      const r = await api.get('price_alerts.php');
      setAlerts(r.alerts);
    } catch {}
  }

  useEffect(() => {
    loadAlerts();
    // eslint-disable-next-line
  }, []);

  const sorted = items && sort === 'price' ? [...items].sort((a, b) => a.price - b.price) : items;
  const alertFor = (partId) => alerts.find((a) => a.part_id === partId);

  function reserve(r) {
    run(async () => {
      await api.post('reservations.php', { action: 'create', stock_id: r.stock_id });
      setNotice(`Reserved ${r.name} at ${r.shop_name}. Follow it in Orders.`);
      search();
    });
  }

  function toggleAlert(r) {
    run(async () => {
      if (alertFor(r.part_id)) {
        await api.post('price_alerts.php', { action: 'delete', part_id: r.part_id });
      } else {
        const v = window.prompt(`Alert me when ${r.name} is at or below (DA):`, String(Math.max(1, r.price - 500)));
        if (!v) return;
        await api.post('price_alerts.php', { action: 'set', part_id: r.part_id, target_price: Number(v) });
      }
      loadAlerts();
    });
  }

  return (
    <>
      <h1>Find a car part</h1>
      <form
        className="row card"
        onSubmit={(e) => {
          e.preventDefault();
          search();
        }}
      >
        <input style={{ flex: 1, minWidth: 200 }} placeholder="Part name or serial number" value={q} onChange={(e) => setQ(e.target.value)} />
        <select value={category} onChange={(e) => setCategory(e.target.value)}>
          {CATEGORIES.map((c) => (
            <option key={c} value={c}>{c || 'All categories'}</option>
          ))}
        </select>
        <select value={sort} onChange={(e) => setSort(e.target.value)}>
          <option value="price">Cheapest first</option>
          <option value="nearest">Nearest first</option>
        </select>
        <button className="btn">Search</button>
      </form>
      <ErrorBox error={error} />
      {notice && <div className="ok">{notice}</div>}
      {sorted === undefined ? (
        <Empty>Type a part name or serial number, or pick a category.</Empty>
      ) : !sorted ? (
        <Loading />
      ) : sorted.length === 0 ? (
        <Empty>No part found. Try another name or serial number.</Empty>
      ) : (
        <div className="grid">
          {sorted.map((r) => (
            <div className="card stack" key={r.stock_id}>
              <div className="row between">
                <h3>{r.name}</h3>
                <span className="price">{money(r.price)}</span>
              </div>
              <div className="muted small">Serial {r.oem || '—'} · {r.category} · {r.fits}</div>
              <div className="row">
                <Link to={`/shop/${r.shop_id}`}>{r.shop_name}</Link>
                <Badge tone={r.open_now ? 'good' : 'bad'}>{r.open_now ? 'Open' : 'Closed'}</Badge>
                <Badge>{r.part_condition}</Badge>
                {r.distance_km != null && <span className="muted small">{Number(r.distance_km).toFixed(1)} km</span>}
              </div>
              <div className="muted small">{r.quantity} in stock · {r.hours}</div>
              <div className="row">
                <button className="btn" disabled={busy || r.quantity < 1} onClick={() => reserve(r)}>Reserve</button>
                <button className="btn ghost" disabled={busy} onClick={() => toggleAlert(r)}>
                  {alertFor(r.part_id) ? '🔔 Alert on' : '🔔 Price alert'}
                </button>
                <a className="btn ghost" href={`tel:${r.phone}`}>Call</a>
              </div>
            </div>
          ))}
        </div>
      )}
    </>
  );
}
