import { useState } from 'react';
import { useAuth } from '../auth';
import { DEMO } from '../config';
import { ErrorBox, Field, useAction } from '../ui';

const ROLES = [
  ['client', 'Client'],
  ['mechanic', 'Mechanic'],
  ['shop', 'Shop owner'],
];

export default function Login() {
  const { login, register } = useAuth();
  const [role, setRole] = useState('client');
  const [mode, setMode] = useState('login');
  const [f, setF] = useState({ name: '', email: '', phone: '', password: '', place: '', wilaya: 'Jijel' });
  const { busy, error, run } = useAction();
  const set = (k) => (e) => setF({ ...f, [k]: e.target.value });

  function submit(e) {
    e.preventDefault();
    run(async () => {
      if (mode === 'login') {
        await login(role, f.email, f.password);
        return;
      }
      const profile = { wilaya: f.wilaya };
      if (role === 'shop') {
        profile.shopName = f.place;
        profile.address = f.place;
      }
      if (role === 'mechanic') profile.garage = f.place;
      await register({
        role,
        name: f.name.trim(),
        email: f.email.trim(),
        phone: f.phone.trim(),
        password: f.password,
        profile,
      });
    });
  }

  function demo() {
    const [email, password] = DEMO[role];
    setF({ ...f, email, password });
  }

  return (
    <div className="auth-split">
      <aside className="auth-promo">
        <div className="brand" style={{ color: '#fff' }}>Auto<span style={{ color: '#fbbf91' }}>Pièces</span></div>
        <h1>Car parts, shops and mechanics. One place.</h1>
        <ul>
          <li>🔎 Search parts by name, serial number or your car</li>
          <li>💸 Compare prices between local shops</li>
          <li>🔧 Book verified mechanics and follow the repair with photos</li>
          <li>💬 Chat with shops and mechanics, no phone call needed</li>
        </ul>
        <div className="promo-stats">
          <div><b>3</b><span>roles</span></div>
          <div><b>100%</b><span>local</span></div>
          <div><b>24/7</b><span>online</span></div>
        </div>
      </aside>
      <div className="auth-wrap">
      <h2 style={{ margin: '0 0 4px', display: 'block' }}>Welcome back</h2>
      <p className="muted" style={{ marginTop: 0 }}>Choose your role to continue.</p>
      <div className="tabs">
        {ROLES.map(([k, l]) => (
          <button key={k} className={role === k ? 'on' : ''} onClick={() => setRole(k)} type="button">{l}</button>
        ))}
      </div>
      <form className="card" onSubmit={submit}>
        <div className="tabs">
          <button type="button" className={mode === 'login' ? 'on' : ''} onClick={() => setMode('login')}>Log in</button>
          <button type="button" className={mode === 'register' ? 'on' : ''} onClick={() => setMode('register')}>Sign up</button>
        </div>
        {mode === 'register' && (
          <>
            <Field label="Full name"><input value={f.name} onChange={set('name')} required /></Field>
            <Field label="Phone"><input value={f.phone} onChange={set('phone')} /></Field>
            {role !== 'client' && (
              <Field label={role === 'shop' ? 'Shop name' : 'Garage name'}>
                <input value={f.place} onChange={set('place')} required />
              </Field>
            )}
            <Field label="Wilaya"><input value={f.wilaya} onChange={set('wilaya')} /></Field>
          </>
        )}
        <Field label="Email"><input type="email" value={f.email} onChange={set('email')} required /></Field>
        <Field label="Password"><input type="password" value={f.password} onChange={set('password')} required minLength={6} /></Field>
        <ErrorBox error={error} />
        <div className="row">
          <button className="btn" disabled={busy}>{busy ? 'Please wait…' : mode === 'login' ? 'Log in' : 'Create account'}</button>
          <button type="button" className="btn ghost" onClick={demo}>Use demo account</button>
        </div>
      </form>
      </div>
    </div>
  );
}
