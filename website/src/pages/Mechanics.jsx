import { useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api';
import { REFERENCE } from '../config';
import { Badge, Empty, ErrorBox, Loading, Stars, useLoad } from '../ui';

export default function Mechanics() {
  const [q, setQ] = useState('');
  const [sort, setSort] = useState('rating');
  const [available, setAvailable] = useState(false);
  const { data, error, loading } = useLoad(
    () =>
      api.get('mechanics.php', {
        q,
        sort,
        available: available ? 1 : '',
        ...(sort === 'nearest' ? { lat: REFERENCE.lat, lng: REFERENCE.lng } : {}),
      }),
    [q, sort, available]
  );

  return (
    <>
      <h1>Mechanics</h1>
      <div className="row card">
        <input style={{ flex: 1, minWidth: 200 }} placeholder="Name or specialty" value={q} onChange={(e) => setQ(e.target.value)} />
        <select value={sort} onChange={(e) => setSort(e.target.value)}>
          <option value="rating">Best rated</option>
          <option value="nearest">Nearest</option>
          <option value="reports">Most reports</option>
        </select>
        <label className="row">
          <input type="checkbox" checked={available} onChange={(e) => setAvailable(e.target.checked)} /> Available now
        </label>
      </div>
      <ErrorBox error={error} />
      {loading ? (
        <Loading />
      ) : data.mechanics.length === 0 ? (
        <Empty>No mechanic found.</Empty>
      ) : (
        <div className="grid">
          {data.mechanics.map((m) => (
            <div className="card stack" key={m.id}>
              <div className="row between">
                <h3><Link to={`/mechanic/${m.id}`}>{m.name}</Link></h3>
                <Stars value={m.rating} count={m.reviews_count} />
              </div>
              <div className="muted">{m.specialties}</div>
              <div className="row">
                {m.verified ? <Badge tone="good">Verified</Badge> : null}
                {m.premium ? <Badge tone="info">Premium</Badge> : null}
                <Badge tone={m.available ? 'good' : 'bad'}>{m.available ? 'Available' : 'Busy'}</Badge>
                {m.distance_km != null && <span className="muted small">{Number(m.distance_km).toFixed(1)} km</span>}
              </div>
              <div className="muted small">{m.years_experience} years · {m.reports_count} reports · {m.address}</div>
            </div>
          ))}
        </div>
      )}
    </>
  );
}
