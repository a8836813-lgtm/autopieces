import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { api } from '../api';
import { useAuth } from '../auth';
import { BRANDS } from '../vehicles';
import { Badge, Stars, money, useLoad } from '../ui';

const CATEGORIES = [
  ['Brakes', '🛑'],
  ['Filters', '🧪'],
  ['Battery', '🔋'],
  ['Engine', '⚙️'],
  ['Electrical', '⚡'],
  ['Suspension', '🔩'],
  ['Cooling', '❄️'],
  ['Body', '🚗'],
];

const POPULAR = ['Brake pads', 'Oil filter', 'Battery', 'Air filter', 'Alternator', 'Shock absorber'];

const initials = (name) => name.split(/\s+/).slice(0, 2).map((w) => w[0]).join('').toUpperCase();

export default function Home() {
  const { user } = useAuth();
  const nav = useNavigate();
  const [q, setQ] = useState('');
  const shops = useLoad(() => api.get('shops.php'), []);
  const mechs = useLoad(() => api.get('mechanics.php', { sort: 'rating' }), []);
  const reports = useLoad(() => api.get('reports.php'), []);
  const parts = useLoad(() => api.get('parts.php'), []);

  const shopList = shops.data?.shops || [];
  const mechList = mechs.data?.mechanics || [];
  const reportList = reports.data?.reports || [];
  const topShops = [...shopList].sort((a, b) => (b.rating || 0) - (a.rating || 0)).slice(0, 4);
  const topMechs = mechList.slice(0, 4);

  function go(e) {
    e.preventDefault();
    nav(`/search?q=${encodeURIComponent(q)}`);
  }

  return (
    <>
      <section className="hero">
        <div>
          <Badge tone="info">Hello {user.name.split(' ')[0]} 👋</Badge>
          <h1>Find the right <em>car part</em>, the nearest shop and a trusted mechanic.</h1>
          <p className="muted">Compare prices across local shops, check what is in stock, reserve in one click and follow your repair.</p>
          <form className="hero-search" onSubmit={go}>
            <input placeholder="Part name or serial number (e.g. brake pads, 04465-02220)" value={q} onChange={(e) => setQ(e.target.value)} />
            <button className="btn orange">Search</button>
          </form>
          <div className="chips">
            {POPULAR.map((p) => (
              <Link key={p} className="chip" to={`/search?q=${encodeURIComponent(p)}`}>{p}</Link>
            ))}
          </div>
        </div>
        <div className="hero-stats">
          <div className="stat"><b>{parts.data?.parts?.length ?? '…'}</b><span className="muted small">parts listed</span></div>
          <div className="stat"><b>{shopList.length || '…'}</b><span className="muted small">local shops</span></div>
          <div className="stat"><b>{mechList.length || '…'}</b><span className="muted small">mechanics</span></div>
          <div className="stat"><b>{reportList.length || '…'}</b><span className="muted small">repair reports</span></div>
        </div>
      </section>

      <h2>Browse by category</h2>
      <div className="tiles">
        {CATEGORIES.map(([c, ico]) => (
          <Link key={c} className="tile" to={`/search?category=${c}`}>
            <span className="ico">{ico}</span>
            {c}
          </Link>
        ))}
      </div>

      <h2>Search by your car</h2>
      <div className="brand-row">
        {BRANDS.filter((b) => b.type === 'car').slice(0, 16).map((b) => (
          <Link key={b.id} className="brand-tile" to={`/search?brand=${b.id}`}>
            <i>{initials(b.name)}</i>
            {b.name}
          </Link>
        ))}
      </div>

      <div className="cols" style={{ marginTop: 6 }}>
        <section>
          <h2>Top shops <Link className="small" to="/map">See on map</Link></h2>
          {topShops.map((s) => (
            <Link key={s.id} to={`/shop/${s.id}`} className="card mini" style={{ color: 'inherit' }}>
              <div className="avatar">{initials(s.name)}</div>
              <div style={{ flex: 1 }}>
                <b>{s.name}</b>
                <div className="muted small">{s.address}</div>
                <Stars value={s.rating} count={s.reviews_count} />
              </div>
              <Badge tone={s.open_now ? 'good' : 'bad'}>{s.open_now ? 'Open' : 'Closed'}</Badge>
            </Link>
          ))}
        </section>
        <section>
          <h2>Top mechanics <Link className="small" to="/mechanics">See all</Link></h2>
          {topMechs.map((m) => (
            <Link key={m.id} to={`/mechanic/${m.id}`} className="card mini" style={{ color: 'inherit' }}>
              <div className="avatar orange">{initials(m.name)}</div>
              <div style={{ flex: 1 }}>
                <b>{m.name}</b>
                <div className="muted small">{m.specialties}</div>
                <Stars value={m.rating} count={m.reviews_count} />
              </div>
              <Badge tone={m.available ? 'good' : 'bad'}>{m.available ? 'Free' : 'Busy'}</Badge>
            </Link>
          ))}
        </section>
        <section>
          <h2>Latest repair reports <Link className="small" to="/reports">See all</Link></h2>
          {reportList.slice(0, 4).map((r) => (
            <Link key={r.id} to="/reports" className="card" style={{ color: 'inherit', display: 'block' }}>
              <b>{r.title}</b>
              <div className="muted small">{r.car} · {r.mechanic_name}</div>
              <div className="small">{money(r.cost)} · {r.warranty_months} months warranty</div>
            </Link>
          ))}
        </section>
      </div>

      <h2>How it works</h2>
      <div className="steps">
        <div className="card step"><b>1</b><b style={{ background: 'none', color: 'inherit', width: 'auto' }}>Search</b><div className="muted">Type a part or serial number, or pick your car brand and model.</div></div>
        <div className="card step"><b>2</b><b style={{ background: 'none', color: 'inherit', width: 'auto' }}>Compare and reserve</b><div className="muted">See price, stock, distance and ratings, then reserve in one click.</div></div>
        <div className="card step"><b>3</b><b style={{ background: 'none', color: 'inherit', width: 'auto' }}>Fit it</b><div className="muted">Book a verified mechanic, chat, and follow progress photos and the invoice.</div></div>
      </div>

      <div className="cta">
        <div>
          <b style={{ fontSize: 18 }}>Not sure which part you need?</b>
          <div style={{ opacity: 0.85 }}>Chat with a shop or ask a mechanic before you buy.</div>
        </div>
        <Link className="btn" to="/mechanics">Find a mechanic</Link>
      </div>
    </>
  );
}
