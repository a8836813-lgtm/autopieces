import { useEffect, useState } from 'react';
import { api } from '../api';
import { useAuth } from '../auth';
import { ErrorBox, Field, Loading, useAction, useLoad } from '../ui';

export default function MechanicProfile() {
  const { user } = useAuth();
  const { data, error, loading } = useLoad(() => api.get('mechanics.php', { id: user.mechanic_id }), []);
  const [f, setF] = useState(null);
  const [saved, setSaved] = useState(false);
  const act = useAction();

  useEffect(() => {
    if (data) {
      const m = data.mechanic || data.mechanics?.[0];
      setF({
        about: m.about || '',
        phone: m.phone || '',
        hours: m.hours || '',
        address: m.address || '',
        specialties: m.specialties || '',
        years_experience: m.years_experience,
        response_time: m.response_time || '',
        languages: m.languages || '',
        mobile_service: !!m.mobile_service,
        available: !!m.available,
        services: m.services.map((s) => ({ name: s.name, price_from: s.price_from })),
      });
    }
  }, [data]);

  if (loading || !f) return <Loading />;
  const set = (k) => (e) => setF({ ...f, [k]: e.target.value });
  const setService = (i, k, v) => setF({ ...f, services: f.services.map((s, j) => (j === i ? { ...s, [k]: v } : s)) });

  function save(e) {
    e.preventDefault();
    act.run(async () => {
      await api.post('mechanics.php', {
        ...f,
        years_experience: Number(f.years_experience),
        services: f.services.filter((s) => s.name.trim()).map((s) => ({ name: s.name.trim(), price_from: Number(s.price_from) || 0 })),
      });
      setSaved(true);
      setTimeout(() => setSaved(false), 2500);
    });
  }

  return (
    <>
      <h1>My profile</h1>
      <ErrorBox error={error || act.error} />
      {saved && <div className="ok">Saved.</div>}
      <form className="card" onSubmit={save} style={{ maxWidth: 600 }}>
        <label className="row">
          <input type="checkbox" checked={f.available} onChange={(e) => setF({ ...f, available: e.target.checked })} /> Available for new jobs
        </label>
        <label className="row">
          <input type="checkbox" checked={f.mobile_service} onChange={(e) => setF({ ...f, mobile_service: e.target.checked })} /> I come to the client (mobile service)
        </label>
        <Field label="Specialties"><input value={f.specialties} onChange={set('specialties')} /></Field>
        <Field label="About"><textarea value={f.about} onChange={set('about')} /></Field>
        <Field label="Phone"><input value={f.phone} onChange={set('phone')} /></Field>
        <Field label="Address"><input value={f.address} onChange={set('address')} /></Field>
        <Field label="Opening hours"><input value={f.hours} onChange={set('hours')} /></Field>
        <Field label="Years of experience"><input type="number" min="0" value={f.years_experience} onChange={set('years_experience')} /></Field>
        <Field label="Response time"><input value={f.response_time} onChange={set('response_time')} /></Field>
        <Field label="Languages"><input value={f.languages} onChange={set('languages')} /></Field>
        <h3>Services</h3>
        {f.services.map((s, i) => (
          <div className="row" key={i} style={{ marginBottom: 8 }}>
            <input style={{ flex: 1 }} placeholder="Service" value={s.name} onChange={(e) => setService(i, 'name', e.target.value)} />
            <input type="number" style={{ width: 120 }} placeholder="From (DA)" value={s.price_from} onChange={(e) => setService(i, 'price_from', e.target.value)} />
            <button type="button" className="btn danger small" onClick={() => setF({ ...f, services: f.services.filter((_, j) => j !== i) })}>✕</button>
          </div>
        ))}
        <button type="button" className="btn ghost small" onClick={() => setF({ ...f, services: [...f.services, { name: '', price_from: '' }] })}>Add a service</button>
        <div style={{ marginTop: 14 }}><button className="btn" disabled={act.busy}>Save</button></div>
      </form>
    </>
  );
}
