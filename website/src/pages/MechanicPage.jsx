import { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { api } from '../api';
import { Monogram } from '../art';
import { Badge, Empty, ErrorBox, Field, Loading, Modal, Photos, Stars, money, useAction, useLoad, useToast } from '../ui';
import ReviewForm from './ReviewForm';

export default function MechanicPage() {
  const { id } = useParams();
  const nav = useNavigate();
  const toast = useToast();
  const mech = useLoad(() => api.get('mechanics.php', { id }), [id]);
  const reports = useLoad(() => api.get('reports.php'), []);
  const reviews = useLoad(() => api.get('reviews.php', { target_kind: 'mechanic', target_id: id }), [id]);
  const favs = useLoad(() => api.get('favorites.php'), []);
  const [booking, setBooking] = useState(false);
  const [form, setForm] = useState({ service: '', when: '', note: '' });
  const { busy, error, run } = useAction();

  if (mech.loading) return <Loading />;
  if (mech.error) return <ErrorBox error={mech.error} />;
  const m = mech.data.mechanic || mech.data.mechanics?.[0];
  const mine = (reports.data?.reports || []).filter((r) => r.mechanic_id === m.id);
  const isFav = favs.data?.mechanics?.includes(m.id);

  function openBooking(service = '') {
    setForm({ service, when: '', note: '' });
    setBooking(true);
  }

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
      toast('Request sent. Follow it in Appointments.');
    });
  }

  return (
    <>
      <div className="profile-head">
        <Monogram name={m.name} size={72} />
        <div className="grow">
          <h1>{m.name}</h1>
          <div className="row">
            <Stars value={m.rating} count={m.reviews_count} />
            {m.verified ? <Badge tone="good">Verified</Badge> : null}
            {m.premium ? <Badge tone="info">Premium</Badge> : null}
            <Badge tone={m.available ? 'good' : 'bad'}>{m.available ? 'Available' : 'Busy'}</Badge>
          </div>
          <div className="muted" style={{ marginTop: 4 }}>{m.specialties}</div>
        </div>
        <div className="row">
          <button
            className="btn ghost"
            onClick={() =>
              run(async () => {
                await api.post('favorites.php', { kind: 'mechanic', target_id: m.id });
                toast(isFav ? 'Removed from saved' : 'Mechanic saved');
                favs.reload();
              })
            }
          >
            {isFav ? '♥ Saved' : '♡ Save'}
          </button>
          <button className="btn ghost" onClick={() => nav(`/messages?kind=mechanic&id=${m.id}&name=${encodeURIComponent(m.name)}`)}>Chat</button>
          <button className="btn orange" onClick={() => openBooking()}>Book an appointment</button>
        </div>
      </div>
      <ErrorBox error={error} />
      <div className="split">
        <div>
          <h2 style={{ marginTop: 0 }}>Services</h2>
          <div className="card">
            {m.services.length === 0 && <span className="muted">No service listed.</span>}
            {m.services.map((s) => (
              <div className="service" key={s.name}>
                <span>{s.name}</span>
                <span className="row">
                  <span className="price">from {money(s.price_from)}</span>
                  <button className="btn ghost small" onClick={() => openBooking(s.name)}>Book</button>
                </span>
              </div>
            ))}
          </div>
          <h2>Repair reports</h2>
          {mine.length === 0 && <Empty>No report yet.</Empty>}
          {mine.map((r) => (
            <div className="card" key={r.id}>
              <div className="row between"><h3>{r.title}</h3><span className="price">{money(r.cost)}</span></div>
              <div className="muted small">{r.car} · {r.warranty_months} months warranty</div>
              <div style={{ marginTop: 6 }}><b>Diagnosis:</b> {r.diagnosis}</div>
              <div><b>Work done:</b> {r.work_done}</div>
            </div>
          ))}
          <h2>Reviews <ReviewForm kind="mechanic" targetId={m.id} onDone={() => { toast('Review sent'); reviews.reload(); }} /></h2>
          {(reviews.data?.reviews || []).length === 0 && <Empty>No review yet. Reviews open after a finished job.</Empty>}
          {(reviews.data?.reviews || []).map((r) => (
            <div className="card" key={r.id}>
              <div className="row between"><b>{r.author_name}</b><Stars value={r.stars} /></div>
              <div>{r.comment}</div>
              <Photos list={r.photos} />
              {r.reply && <div className="muted small" style={{ marginTop: 8 }}><b>Reply:</b> {r.reply}</div>}
            </div>
          ))}
        </div>
        <aside className="aside">
          <div className="card">
            <dl className="facts">
              {m.about && <div><dt>About</dt><dd>{m.about}</dd></div>}
              <div><dt>Experience</dt><dd>{m.years_experience} years</dd></div>
              <div><dt>Address</dt><dd>{m.address}</dd></div>
              <div><dt>Opening hours</dt><dd>{m.hours}</dd></div>
              <div><dt>Replies</dt><dd>{m.response_time}</dd></div>
              <div><dt>Languages</dt><dd>{m.languages}</dd></div>
              {m.mobile_service ? <div><dt>Mobile service</dt><dd>Comes to you</dd></div> : null}
            </dl>
          </div>
          <a className="btn ghost" style={{ display: 'block' }} href={`tel:${m.phone}`}>Call {m.phone}</a>
        </aside>
      </div>
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
            <Field label="What is wrong? (optional)">
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
