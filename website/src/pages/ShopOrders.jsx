import { useState } from 'react';
import { api } from '../api';
import { Empty, ErrorBox, Loading, StatusBadge, money, useAction, useLoad } from '../ui';

const FILTERS = ['', 'Pending', 'Confirmed', 'Picked up', 'Declined', 'Cancelled'];

export default function ShopOrders() {
  const [status, setStatus] = useState('');
  const { data, error, loading, reload } = useLoad(() => api.get('reservations.php', { as: 'shop', status }), [status]);
  const act = useAction();

  function step(r, action) {
    act.run(async () => {
      await api.post('reservations.php', { action, id: r.id });
      reload();
    });
  }

  return (
    <>
      <h1>Orders</h1>
      <div className="tabs">
        {FILTERS.map((f) => (
          <button key={f} className={status === f ? 'on' : ''} onClick={() => setStatus(f)}>{f || 'All'}</button>
        ))}
      </div>
      <ErrorBox error={error || act.error} />
      {loading ? (
        <Loading />
      ) : data.reservations.length === 0 ? (
        <Empty>No order.</Empty>
      ) : (
        data.reservations.map((r) => (
          <div className="card stack" key={r.id}>
            <div className="row between">
              <h3>{r.part_name}</h3>
              <StatusBadge status={r.status} />
            </div>
            <div className="muted small">{r.client_name} · {r.client_phone} · {r.created_at}</div>
            <div className="price">{money(r.price)}</div>
            <div className="row">
              {r.status === 'Pending' && (
                <>
                  <button className="btn small" disabled={act.busy} onClick={() => step(r, 'confirm')}>Confirm</button>
                  <button className="btn danger small" disabled={act.busy} onClick={() => step(r, 'decline')}>Decline</button>
                </>
              )}
              {r.status === 'Confirmed' && (
                <button className="btn orange small" disabled={act.busy} onClick={() => step(r, 'complete')}>Picked up</button>
              )}
            </div>
          </div>
        ))
      )}
    </>
  );
}
