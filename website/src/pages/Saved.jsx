import { Link } from 'react-router-dom';
import { api } from '../api';
import { Empty, ErrorBox, Loading, money, useAction, useLoad } from '../ui';

export default function Saved() {
  const favs = useLoad(() => api.get('favorites.php'), []);
  const alerts = useLoad(() => api.get('price_alerts.php'), []);
  const shops = useLoad(() => api.get('shops.php'), []);
  const mechs = useLoad(() => api.get('mechanics.php'), []);
  const parts = useLoad(() => api.get('parts.php'), []);
  const act = useAction();

  if (favs.loading || alerts.loading || shops.loading || mechs.loading || parts.loading) return <Loading />;
  const f = favs.data || { shops: [], parts: [], mechanics: [] };
  const shopList = (shops.data?.shops || []).filter((s) => f.shops.includes(s.id));
  const mechList = (mechs.data?.mechanics || []).filter((m) => f.mechanics.includes(m.id));
  const partList = (parts.data?.parts || []).filter((p) => f.parts.includes(p.id));

  function toggle(kind, id) {
    act.run(async () => {
      await api.post('favorites.php', { kind, target_id: id });
      favs.reload();
    });
  }

  return (
    <>
      <h1>Saved</h1>
      <ErrorBox error={favs.error || alerts.error || act.error} />
      <h2>Price alerts</h2>
      {alerts.data.alerts.length === 0 && <Empty>No price alert. Use the bell on a search result.</Empty>}
      {alerts.data.alerts.map((a) => (
        <div className="card row between" key={a.part_id}>
          <div>
            <b>{a.part_name}</b>
            <div className="muted small">
              Target {money(a.target_price)} · now {a.current_price != null ? money(a.current_price) : 'not in stock'}
            </div>
            {a.triggered ? <span className="badge good">Price reached</span> : null}
          </div>
          <button
            className="btn danger small"
            onClick={() =>
              act.run(async () => {
                await api.post('price_alerts.php', { action: 'delete', part_id: a.part_id });
                alerts.reload();
              })
            }
          >
            Remove
          </button>
        </div>
      ))}
      <h2>Shops</h2>
      {shopList.length === 0 && <Empty>No saved shop.</Empty>}
      {shopList.map((s) => (
        <div className="card row between" key={s.id}>
          <Link to={`/shop/${s.id}`}>{s.name}</Link>
          <button className="btn ghost small" onClick={() => toggle('shop', s.id)}>♥ Remove</button>
        </div>
      ))}
      <h2>Mechanics</h2>
      {mechList.length === 0 && <Empty>No saved mechanic.</Empty>}
      {mechList.map((m) => (
        <div className="card row between" key={m.id}>
          <Link to={`/mechanic/${m.id}`}>{m.name}</Link>
          <button className="btn ghost small" onClick={() => toggle('mechanic', m.id)}>♥ Remove</button>
        </div>
      ))}
      <h2>Parts</h2>
      {partList.length === 0 && <Empty>No saved part.</Empty>}
      {partList.map((p) => (
        <div className="card row between" key={p.id}>
          <span>{p.name} <span className="muted small">{p.oem}</span></span>
          <button className="btn ghost small" onClick={() => toggle('part', p.id)}>♥ Remove</button>
        </div>
      ))}
    </>
  );
}
