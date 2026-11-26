import { useState } from 'react';
import { api } from '../api';
import { useAuth } from '../auth';
import { PartArt } from '../art';
import { Badge, Empty, ErrorBox, Field, Loading, Modal, money, useAction, useLoad } from '../ui';

const CATEGORIES = ['Brakes', 'Filters', 'Battery', 'Engine', 'Electrical', 'Suspension', 'Cooling', 'Body', 'Other'];
const blank = { name: '', oem: '', category: 'Brakes', fits: '', price: '', quantity: '1', condition: 'New' };

export default function ShopStock() {
  const { user } = useAuth();
  const { data, error, loading, reload } = useLoad(() => api.get('stock.php', { shop_id: user.shop_id }), []);
  const [form, setForm] = useState(null);
  const [edit, setEdit] = useState(null);
  const [percent, setPercent] = useState('');
  const [bulkCat, setBulkCat] = useState('');
  const [q, setQ] = useState('');
  const act = useAction();

  if (loading) return <Loading />;
  const list = (data?.stock || []).filter((i) => `${i.name} ${i.oem} ${i.category}`.toLowerCase().includes(q.toLowerCase()));

  function go(fn) {
    return act.run(async () => {
      await fn();
      reload();
    });
  }

  function addPart(e) {
    e.preventDefault();
    go(async () => {
      await api.post('parts.php', {
        name: form.name,
        oem: form.oem,
        category: form.category,
        fits: form.fits,
        price: Number(form.price),
        quantity: Number(form.quantity),
        condition: form.condition,
      });
      setForm(null);
    });
  }

  function saveEdit(e) {
    e.preventDefault();
    go(async () => {
      await api.post('stock.php', {
        action: 'upsert',
        part_id: edit.part_id,
        price: Number(edit.price),
        quantity: Number(edit.quantity),
        condition: edit.part_condition,
      });
      setEdit(null);
    });
  }

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  return (
    <>
      <div className="row between">
        <h1>Stock</h1>
        <button className="btn" onClick={() => setForm(blank)}>Add a part</button>
      </div>
      <ErrorBox error={error || act.error} />
      <div className="row card">
        <input style={{ flex: 1, minWidth: 180 }} placeholder="Search your stock" value={q} onChange={(e) => setQ(e.target.value)} />
        <select value={bulkCat} onChange={(e) => setBulkCat(e.target.value)}>
          <option value="">All categories</option>
          {CATEGORIES.map((c) => <option key={c}>{c}</option>)}
        </select>
        <input type="number" style={{ width: 110 }} placeholder="± %" value={percent} onChange={(e) => setPercent(e.target.value)} />
        <button
          className="btn ghost"
          disabled={!percent}
          onClick={() =>
            go(async () => {
              await api.post('stock.php', { action: 'bulk_price', percent: Number(percent), ...(bulkCat ? { category: bulkCat } : {}) });
              setPercent('');
            })
          }
        >
          Change prices
        </button>
      </div>
      {list.length === 0 ? (
        <Empty>No part in stock.</Empty>
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr><th>Part</th><th>Serial</th><th>Condition</th><th>Quantity</th><th>Price</th><th /></tr>
            </thead>
            <tbody>
              {list.map((i) => (
                <tr key={i.stock_id}>
                  <td>
                    <div className="item">
                      <PartArt category={i.category} size={40} />
                      <div className="grow">{i.name}<div className="muted small">{i.category}</div></div>
                    </div>
                  </td>
                  <td>{i.oem}</td>
                  <td>{i.part_condition}</td>
                  <td>
                    <div className="row">
                      <button className="btn ghost small" onClick={() => go(() => api.post('stock.php', { action: 'adjust', part_id: i.part_id, delta: -1 }))}>−</button>
                      {i.quantity === 0 ? <Badge tone="bad">0</Badge> : i.quantity}
                      <button className="btn ghost small" onClick={() => go(() => api.post('stock.php', { action: 'adjust', part_id: i.part_id, delta: 1 }))}>+</button>
                    </div>
                  </td>
                  <td className="price">{money(i.price)}</td>
                  <td>
                    <div className="row">
                      <button className="btn ghost small" onClick={() => setEdit({ ...i })}>Edit</button>
                      <button
                        className="btn danger small"
                        onClick={() => window.confirm(`Remove ${i.name}?`) && go(() => api.post('stock.php', { action: 'delete', part_id: i.part_id }))}
                      >
                        Remove
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {form && (
        <Modal title="Add a part" onClose={() => setForm(null)}>
          <form onSubmit={addPart}>
            <Field label="Part name"><input value={form.name} onChange={set('name')} required /></Field>
            <Field label="Serial number (OEM)"><input value={form.oem} onChange={set('oem')} /></Field>
            <Field label="Category">
              <select value={form.category} onChange={set('category')}>{CATEGORIES.map((c) => <option key={c}>{c}</option>)}</select>
            </Field>
            <Field label="Fits (cars)"><input value={form.fits} onChange={set('fits')} /></Field>
            <div className="row">
              <Field label="Price (DA)"><input type="number" min="1" value={form.price} onChange={set('price')} required /></Field>
              <Field label="Quantity"><input type="number" min="0" value={form.quantity} onChange={set('quantity')} required /></Field>
              <Field label="Condition">
                <select value={form.condition} onChange={set('condition')}><option>New</option><option>Used</option></select>
              </Field>
            </div>
            <ErrorBox error={act.error} />
            <button className="btn" disabled={act.busy}>Save</button>
          </form>
        </Modal>
      )}
      {edit && (
        <Modal title={edit.name} onClose={() => setEdit(null)}>
          <form onSubmit={saveEdit}>
            <Field label="Price (DA)"><input type="number" min="1" value={edit.price} onChange={(e) => setEdit({ ...edit, price: e.target.value })} required /></Field>
            <Field label="Quantity"><input type="number" min="0" value={edit.quantity} onChange={(e) => setEdit({ ...edit, quantity: e.target.value })} required /></Field>
            <Field label="Condition">
              <select value={edit.part_condition} onChange={(e) => setEdit({ ...edit, part_condition: e.target.value })}><option>New</option><option>Used</option></select>
            </Field>
            <button className="btn" disabled={act.busy}>Save</button>
          </form>
        </Modal>
      )}
    </>
  );
}
