import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api';
import { BRANDS } from '../vehicles';
import { fitsCar, indexFitments } from '../carfilter';
import { Stars, money, useAction, useLoad } from '../ui';

const CATEGORIES = ['Brakes', 'Filters', 'Battery', 'Engine', 'Electrical', 'Suspension', 'Cooling', 'Body'];
const EXAMPLES = ['Brake pads', 'Oil filter', 'Battery', 'Alternator'];

export default function Home() {
  const [brandId, setBrandId] = useState('');
  const [model, setModel] = useState('');
  const [q, setQ] = useState('');
  const [hits, setHits] = useState(null);
  const [notice, setNotice] = useState('');
  const act = useAction();
  const shops = useLoad(() => api.get('shops.php'), []);
  const mechs = useLoad(() => api.get('mechanics.php', { sort: 'rating' }), []);
  const reports = useLoad(() => api.get('reports.php'), []);
  const parts = useLoad(() => api.get('parts.php'), []);

  const brand = BRANDS.find((b) => b.id === brandId);
  const fitments = useMemo(() => indexFitments(parts.data?.parts || []), [parts.data]);

  useEffect(() => {
    if (q.trim().length < 2) {
      setHits(null);
      return undefined;
    }
    let alive = true;
    const id = setTimeout(async () => {
      try {
        const r = await api.get('parts_search.php', { q: q.trim() });
        if (alive) setHits(r.results);
      } catch {
        if (alive) setHits([]);
      }
    }, 250);
    return () => {
      alive = false;
      clearTimeout(id);
    };
  }, [q]);

  const shown = (hits || []).filter((r) => fitsCar(fitments, brand, model, r.part_id)).sort((a, b) => a.price - b.price);

  function reserve(r) {
    act.run(async () => {
      await api.post('reservations.php', { action: 'create', stock_id: r.stock_id });
      setNotice(`${r.name} reserved at ${r.shop_name}. You can follow it in Orders.`);
      const again = await api.get('parts_search.php', { q: q.trim() });
      setHits(again.results);
    });
  }

  const shopList = [...(shops.data?.shops || [])].sort((a, b) => (b.rating || 0) - (a.rating || 0)).slice(0, 5);
  const mechList = (mechs.data?.mechanics || []).slice(0, 5);
  const ticket = (reports.data?.reports || [])[0];
  const counts = {};
  (parts.data?.parts || []).forEach((p) => {
    counts[p.category] = (counts[p.category] || 0) + 1;
  });
  const carQuery = brand ? `&brand=${brand.id}` : '';

  return (
    <>
      <section className="home-hero">
        <div>
          <h1>Find the part before you drive around.</h1>
          <p>Pick your car, type the part or its serial number, and see which local shops have it in stock and at what price.</p>
        </div>
        <div className="counter">
          <span className="counter-tag">Parts counter</span>
          <div className="counter-fields">
            <label>
              <span>Car brand</span>
              <select value={brandId} onChange={(e) => { setBrandId(e.target.value); setModel(''); }}>
                <option value="">Any brand</option>
                {BRANDS.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
              </select>
            </label>
            <label>
              <span>Model</span>
              <select value={model} onChange={(e) => setModel(e.target.value)} disabled={!brand}>
                <option value="">Any model</option>
                {(brand ? brand.models : []).map((m) => <option key={m}>{m}</option>)}
              </select>
            </label>
            <label>
              <span>Part name or serial number</span>
              <input value={q} onChange={(e) => { setQ(e.target.value); setNotice(''); }} placeholder="Brake pads, 04465-02220" />
            </label>
          </div>
          <div className="counter-results">
            {notice && <div className="ok" style={{ margin: 12 }}>{notice}</div>}
            {hits === null && (
              <div className="empty" style={{ padding: '22px 18px' }}>
                Start typing, or try{' '}
                {EXAMPLES.map((x, i) => (
                  <span key={x}>
                    <a href="#/" onClick={(e) => { e.preventDefault(); setQ(x); }}>{x}</a>
                    {i < EXAMPLES.length - 1 ? ', ' : '.'}{' '}
                  </span>
                ))}
              </div>
            )}
            {hits !== null && shown.length === 0 && (
              <div className="empty" style={{ padding: '22px 18px' }}>
                No shop has this in stock{brand ? ` for a ${brand.name}${model ? ` ${model}` : ''}` : ''}. Try another spelling, the serial number, or a different model.
              </div>
            )}
            {shown.slice(0, 5).map((r) => (
              <div className="hit" key={r.stock_id}>
                <div>
                  <b>{r.name}</b> <span className="muted small">{r.oem}</span>
                  <div className="small muted">
                    <span className={`open-dot ${r.open_now ? '' : 'off'}`} />
                    <Link to={`/shop/${r.shop_id}`}>{r.shop_name}</Link>
                    {r.distance_km != null ? `, ${Number(r.distance_km).toFixed(1)} km` : ''} · {r.quantity} in stock
                  </div>
                </div>
                <span className="price">{money(r.price)}</span>
                <button className="btn orange small" disabled={act.busy || r.quantity < 1} onClick={() => reserve(r)}>Reserve</button>
              </div>
            ))}
            {shown.length > 0 && (
              <div className="hit-foot">
                <span className="muted">{shown.length} offer{shown.length > 1 ? 's' : ''}, cheapest first</span>
                <Link to={`/search?q=${encodeURIComponent(q)}${carQuery}`}>See all results and compare</Link>
              </div>
            )}
          </div>
        </div>
      </section>

      <h2>Browse by category</h2>
      <div className="index">
        {CATEGORIES.map((c) => (
          <Link key={c} to={`/search?category=${c}`}>
            {c}
            {counts[c] ? <small>{counts[c]}</small> : null}
          </Link>
        ))}
      </div>

      <div className="two">
        <section>
          <h2>Shops <Link to="/map">Show on map</Link></h2>
          <div className="ranked">
            {shopList.map((s) => (
              <Link key={s.id} to={`/shop/${s.id}`}>
                <b>{s.name}</b>
                <span><span className={`open-dot ${s.open_now ? '' : 'off'}`} />{s.open_now ? 'Open' : 'Closed'}</span>
                <span className="muted small">{s.address}</span>
                <Stars value={s.rating} count={s.reviews_count} />
              </Link>
            ))}
          </div>
        </section>
        <section>
          <h2>Mechanics <Link to="/mechanics">See all</Link></h2>
          <div className="ranked">
            {mechList.map((m) => (
              <Link key={m.id} to={`/mechanic/${m.id}`}>
                <b>{m.name}</b>
                <span><span className={`open-dot ${m.available ? '' : 'off'}`} />{m.available ? 'Available' : 'Busy'}</span>
                <span className="muted small">{m.specialties}</span>
                <Stars value={m.rating} count={m.reviews_count} />
              </Link>
            ))}
          </div>
        </section>
      </div>

      {ticket && (
        <>
          <h2>Latest repair report <Link to="/reports">All reports</Link></h2>
          <Link className="ticket" to="/reports">
            <div className="ticket-stub">
              <div>
                <div className="small" style={{ fontWeight: 600 }}>{ticket.car}</div>
                <div className="small">{ticket.mechanic_name}</div>
              </div>
              <div>
                <span className="price">{money(ticket.cost)}</span>
                <div className="small">{ticket.warranty_months} months warranty</div>
              </div>
            </div>
            <dl className="ticket-body" style={{ margin: 0 }}>
              <div><h3>{ticket.title}</h3></div>
              <div><dt>Problem</dt><dd>{ticket.problem}</dd></div>
              <div><dt>Diagnosis</dt><dd>{ticket.diagnosis}</dd></div>
              <div><dt>Work done</dt><dd>{ticket.work_done}</dd></div>
            </dl>
          </Link>
        </>
      )}
    </>
  );
}
