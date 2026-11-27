import { useEffect, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { api } from '../api';
import { REFERENCE } from '../config';
import { BRANDS } from '../vehicles';
import { PartArt } from '../art';
import { Badge, Empty, ErrorBox, Loading, money, useAction, useToast } from '../ui';

const CATEGORIES = ['', 'Brakes', 'Filters', 'Battery', 'Engine', 'Electrical', 'Suspension', 'Cooling', 'Body'];

export default function Search() {
  const [params] = useSearchParams();
  const [q, setQ] = useState(params.get('q') || '');
  const [category, setCategory] = useState(params.get('category') || '');
  const [sort, setSort] = useState('price');
  const [items, setItems] = useState(undefined);
  const [brandId, setBrandId] = useState(params.get('brand') || '');
  const [model, setModel] = useState(params.get('model') || '');
  const [fitments, setFitments] = useState({});
  const [catalogue, setCatalogue] = useState([]);
  const [alerts, setAlerts] = useState([]);
  const toast = useToast();
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

  async function loadFitments() {
    try {
      const r = await api.get('parts.php');
      const map = {};
      r.parts.forEach((p) => {
        let list = [];
        try {
          list = p.fitments_json ? JSON.parse(p.fitments_json) : [];
        } catch {}
        map[p.id] = { list, fits: (p.fits || '').toLowerCase() };
      });
      setFitments(map);
      setCatalogue(r.parts);
    } catch {}
  }

  async function loadAlerts() {
    try {
      const r = await api.get('price_alerts.php');
      setAlerts(r.alerts);
    } catch {}
  }

  useEffect(() => {
    loadAlerts();
    loadFitments();
    if (q || category) search();
    // eslint-disable-next-line
  }, []);

  const brand = BRANDS.find((b) => b.id === brandId);
  function fitsCar(partId) {
    if (!brand) return true;
    const f = fitments[partId];
    if (!f) return true;
    if (f.list.length) return f.list.some((x) => x.brandId === brand.id && (!model || x.model === model));
    if (!f.fits || f.fits.includes('universal')) return true;
    return f.fits.includes(brand.name.toLowerCase()) && (!model || f.fits.includes(model.toLowerCase()));
  }
  const filtered = items ? items.filter((r) => fitsCar(r.part_id)) : items;
  const sorted = filtered && sort === 'price' ? [...filtered].sort((a, b) => a.price - b.price) : filtered;
  const alertFor = (partId) => alerts.find((a) => a.part_id === partId);

  function reserve(r) {
    run(async () => {
      await api.post('reservations.php', { action: 'create', stock_id: r.stock_id });
      toast(`${r.name} reserved at ${r.shop_name}. Follow it in Orders.`);
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
        <div className="filters" style={{ width: '100%' }}>
          <span className="muted small">My car:</span>
          <select value={brandId} onChange={(e) => { setBrandId(e.target.value); setModel(''); }}>
            <option value="">Any brand</option>
            {BRANDS.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
          </select>
          <select value={model} onChange={(e) => setModel(e.target.value)} disabled={!brand}>
            <option value="">Any model</option>
            {(brand ? brand.models : []).map((m) => <option key={m}>{m}</option>)}
          </select>
          {brand && <button type="button" className="btn ghost small" onClick={() => { setBrandId(''); setModel(''); }}>Clear</button>}
        </div>
      </form>
      <ErrorBox error={error} />
      {sorted === undefined && brand ? (
        <div className="grid">
          {catalogue.filter((p) => fitsCar(p.id)).map((p) => (
            <Link key={p.id} to={`/part/${p.id}`} className="card stack" style={{ color: 'inherit' }}>
              <div className="row between"><h3>{p.name}</h3><span className="price">{p.cheapest_price ? money(p.cheapest_price) : 'Out of stock'}</span></div>
              <div className="muted small">{p.category} · {p.fits} · {p.shops_count} shop(s)</div>
            </Link>
          ))}
        </div>
      ) : sorted === undefined ? (
        <Empty>Type a part name or serial number, or pick a category or your car.</Empty>
      ) : !sorted ? (
        <Loading />
      ) : sorted.length === 0 ? (
        <Empty>No part found. Try another name or serial number.</Empty>
      ) : (
        <div className="grid">
          {sorted.map((r) => (
            <div className="card stack" key={r.stock_id}>
              <div className="item">
                <PartArt category={r.category} size={46} />
                <div className="grow"><h3 style={{ margin: 0 }}>{r.name}</h3><div className="muted small">{r.oem}</div></div>
                <span className="price">{money(r.price)}</span>
              </div>
              <div className="muted small">{r.category} · {r.fits}</div>
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
                <Link className="btn ghost" to={`/part/${r.part_id}`}>Compare prices</Link>
                <a className="btn ghost" href={`tel:${r.phone}`}>Call</a>
              </div>
            </div>
          ))}
        </div>
      )}
    </>
  );
}
