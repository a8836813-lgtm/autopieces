import { useEffect, useState } from 'react';
import { api } from '../api';
import { ErrorBox, Field, Loading, useAction, useLoad } from '../ui';

const PAYMENTS = ['Cash', 'CIB card', 'Edahabia', 'Bank transfer'];

export default function ShopSettings() {
  const { data, error, loading } = useLoad(() => api.get('my_shop.php'), []);
  const [f, setF] = useState(null);
  const [saved, setSaved] = useState(false);
  const act = useAction();

  useEffect(() => {
    if (data) {
      const s = data.shop;
      setF({
        name: s.name,
        address: s.address || '',
        phone: s.phone || '',
        hours: s.hours || '',
        about: s.about || '',
        open_now: !!s.open_now,
        delivers: !!s.delivers,
        low_stock_limit: s.low_stock_limit,
        payments: (s.payments || 'Cash').split(',').map((x) => x.trim()).filter(Boolean),
      });
    }
  }, [data]);

  if (loading || !f) return <Loading />;
  const set = (k) => (e) => setF({ ...f, [k]: e.target.value });
  const togglePay = (p) => {
    const has = f.payments.includes(p);
    if (has && f.payments.length === 1) return;
    setF({ ...f, payments: has ? f.payments.filter((x) => x !== p) : [...f.payments, p] });
  };

  function save(e) {
    e.preventDefault();
    act.run(async () => {
      await api.post('my_shop.php', { ...f, low_stock_limit: Number(f.low_stock_limit) });
      setSaved(true);
      setTimeout(() => setSaved(false), 2500);
    });
  }

  return (
    <>
      <h1>My shop</h1>
      <ErrorBox error={error || act.error} />
      {saved && <div className="ok">Saved.</div>}
      <form className="card" onSubmit={save} style={{ maxWidth: 560 }}>
        <Field label="Shop name"><input value={f.name} onChange={set('name')} required /></Field>
        <Field label="Address"><input value={f.address} onChange={set('address')} /></Field>
        <Field label="Phone"><input value={f.phone} onChange={set('phone')} /></Field>
        <Field label="Opening hours"><input value={f.hours} onChange={set('hours')} /></Field>
        <Field label="About"><textarea value={f.about} onChange={set('about')} /></Field>
        <Field label="Low stock alert at (quantity)"><input type="number" min="0" value={f.low_stock_limit} onChange={set('low_stock_limit')} /></Field>
        <label className="row"><input type="checkbox" checked={f.open_now} onChange={(e) => setF({ ...f, open_now: e.target.checked })} /> Open now</label>
        <label className="row"><input type="checkbox" checked={f.delivers} onChange={(e) => setF({ ...f, delivers: e.target.checked })} /> Delivery available</label>
        <h3 style={{ marginTop: 14 }}>Payment methods</h3>
        <div className="row">
          {PAYMENTS.map((p) => (
            <label className="row" key={p}>
              <input type="checkbox" checked={f.payments.includes(p)} onChange={() => togglePay(p)} /> {p}
            </label>
          ))}
        </div>
        <div style={{ marginTop: 14 }}><button className="btn" disabled={act.busy}>Save</button></div>
      </form>
    </>
  );
}
