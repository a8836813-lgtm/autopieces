import { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { api } from '../api';
import { Badge, Empty, ErrorBox, Field, Loading, Modal, Photos, Stars, money, useAction, useLoad } from '../ui';
import { REFERENCE } from '../config';
import ReviewForm from './ReviewForm';

export default function MechanicPage() {
  const { id } = useParams();
  const nav = useNavigate();
  const mech = useLoad(() => api.get('mechanics.php', { id }), [id]);
  const reports = useLoad(() => api.get('reports.php'), []);
  const reviews = useLoad(() => api.get('reviews.php', { target_kind: 'mechanic', target_id: id }), [id]);
  const favs = useLoad(() => api.get('favorites.php'), []);
  const [booking, setBooking] = useState(false);
  const [form, setForm] = useState({ service: '', when: '', note: '' });
  const [notice, setNotice] = useState('');
  const { busy, error, run } = useAction();

  if (mech.loading) return <Loading />;
  if (mech.error) return <ErrorBox error={mech.error} />;
  const m = mech.data.mechanic || mech.data.mechanics?.[0];
  const mine = (reports.data?.reports || []).filter((r) => r.mechanic_id === m.id);
  const isFav = favs.data?.mechanics?.includes(m.id);

  function book(e) {
    e.preventDefault();
    run(async () => {
      let pos = {};
      try {
        pos = await new Promise((res) =>
          navigator.geolocation
            ? navigator.geolocation.getCurrentPosition(
                (p) => res({ lat: p.coords.latitude, lng: p.coords.longitude }),
                () => res({}),
                { timeout: 4000 }
              )
            : res({})
        );
      } catch {}
      await api.post('appointments.php', {
        action: 'create',
        mechanic_id: m.id,
        service: form.service,
        when: new Date(form.when).toISOString(),
        note: form.note,
        ...pos,
      });
      setBooking(false);
      setNotice('Appointment request sent. Follow it in Appointments.');
    });
  }

  return (
    <>
      <div className="row between">
        <h1>{m.name}</h1>
        <div className="row">
          <button
            className="btn ghost"
            onClick={() =>
              run(async () => {
                await api.post('favorites.php', { kind: 'mechanic', target_id: m.id });
                favs.reload();
              })
            }
          >
            {isFav ? '♥ Saved' : '♡ Save'}
          </button>
          <button className="btn ghost" onClick={() => nav(`/messages?kind=mechanic&id=${m.id}&name=${encodeURIComponent(m.name)}`)}>Chat</button>
          <button className="btn orange" onClick={() => setBooking(true)}>Book</button>
        </div>
      </div>
      {notice && <div className="ok">{notice}</div>}
      <div className="card stack">
        <div className="row">
          <Stars value={m.rating} count={m.reviews_count} />
          {m.verified ? <Badge tone="good">Verified</Badge> : null}
          <Badge tone={m.available ? 'good' : 'bad'}>{m.available ? 'Available' : 'Busy'}</Badge>
        </div>
        <div>{m.specialties}</div>
        <div className="muted">{m.about}</div>
        <div className="muted small">{m.years_experience} years · {m.address} · {m.hours} · {m.response_time} · {m.languages}</div>
        <a href={`tel:${m.phone}`}>{m.phone}</a>
      </div>
      <h2>Services</h2>
      <div className="card">
        {m.services.length === 0 && <span className="muted">No services listed.</span>}
        {m.services.map((s) => (
          <div className="row between" key={s.name}><span>{s.name}</span><span className="price">from {money(s.price_from)}</span></div>
        ))}
      </div>
      <h2>Repair reports</h2>
      {mine.length === 0 && <Empty>No reports yet.</Empty>}
      {mine.map((r) => (
        <div className="card" key={r.id}>
          <b>{r.title}</b> <span className="muted">· {r.car}</span>
          <div className="muted">{r.diagnosis}</div>
          <div className="small">{r.work_done} · {money(r.cost)} · {r.warranty_months} months warranty</div>
        </div>
      ))}
      <h2>Reviews</h2>
      <ReviewForm kind="mechanic" targetId={m.id} onDone={reviews.reload} />
      {(reviews.data?.reviews || []).map((r) => (
        <div className="card" key={r.id}>
          <div className="row between"><b>{r.author_name}</b><Stars value={r.stars} /></div>
          <div>{r.comment}</div>
          <Photos list={r.photos} />
          {r.reply && <div className="muted small" style={{ marginTop: 8 }}>Reply: {r.reply}</div>}
        </div>
      ))}
      {booking && (
        <Modal title={`Book ${m.name}`} onClose={() => setBooking(false)}>
          <form onSubmit={book}>
            <Field label="Service">
              <input list="svc" value={form.service} onChange={(e) => setForm({ ...form, service: e.target.value })} required />
              <datalist id="svc">{m.services.map((s) => <option key={s.name} value={s.name} />)}</datalist>
            </Field>
            <Field label="Date and time">
              <input type="datetime-local" value={form.when} onChange={(e) => setForm({ ...form, when: e.target.value })} required />
            </Field>
            <Field label="Note">
              <textarea value={form.note} onChange={(e) => setForm({ ...form, note: e.target.value })} />
            </Field>
            <ErrorBox error={error} />
            <button className="btn orange" disabled={busy}>Send request</button>
          </form>
        </Modal>
      )}
    </>
  );
}
