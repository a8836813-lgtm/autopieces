import { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { photoUrl } from './api';

export function Stars({ value, count }) {
  const v = Number(value) || 0;
  return (
    <span className="stars">
      {'★'.repeat(Math.round(v))}
      {'☆'.repeat(5 - Math.round(v))}
      <span className="muted"> {v ? v.toFixed(1) : 'New'}{count !== undefined ? ` (${count})` : ''}</span>
    </span>
  );
}

export const money = (n) => `${Number(n || 0).toLocaleString('fr-DZ')} DA`;

export function Badge({ tone = 'neutral', children }) {
  return <span className={`badge ${tone}`}>{children}</span>;
}

const STATUS_TONE = {
  Pending: 'warn',
  Confirmed: 'info',
  'Picked up': 'good',
  Declined: 'bad',
  Cancelled: 'bad',
  New: 'warn',
  Accepted: 'info',
  'In progress': 'info',
  Done: 'good',
  Sent: 'warn',
};
export const StatusBadge = ({ status }) => <Badge tone={STATUS_TONE[status] || 'neutral'}>{status}</Badge>;

export function Empty({ children }) {
  return <div className="empty">{children}</div>;
}

export function Loading() {
  return (
    <div className="skeleton" aria-busy="true" aria-label="Loading">
      <i style={{ width: '38%', height: 30 }} />
      <i style={{ width: '100%', height: 90 }} />
      <i style={{ width: '100%', height: 90 }} />
      <i style={{ width: '70%', height: 20 }} />
    </div>
  );
}

const ToastCtx = createContext(() => {});
export const useToast = () => useContext(ToastCtx);

export function ToastProvider({ children }) {
  const [items, setItems] = useState([]);
  const push = useCallback((text, tone = 'good') => {
    const id = Math.random().toString(36).slice(2);
    setItems((l) => [...l, { id, text, tone }]);
    setTimeout(() => setItems((l) => l.filter((x) => x.id !== id)), 4200);
  }, []);
  return (
    <ToastCtx.Provider value={push}>
      {children}
      <div className="toasts" role="status" aria-live="polite">
        {items.map((i) => (
          <div key={i.id} className={`toast ${i.tone}`}>{i.text}</div>
        ))}
      </div>
    </ToastCtx.Provider>
  );
}

export function ErrorBox({ error }) {
  if (!error) return null;
  return <div className="alert">{error.message || String(error)}</div>;
}

export function useLoad(fn, deps = []) {
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);
  const run = useCallback(async () => {
    try {
      setData(await fn());
      setError(null);
    } catch (e) {
      setError(e);
    } finally {
      setLoading(false);
    }
    // eslint-disable-next-line
  }, deps);
  useEffect(() => {
    setLoading(true);
    run();
  }, [run]);
  return { data, error, loading, reload: run };
}

export function useAction() {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);
  async function run(fn) {
    setBusy(true);
    setError(null);
    try {
      return await fn();
    } catch (e) {
      setError(e);
      return undefined;
    } finally {
      setBusy(false);
    }
  }
  return { busy, error, run, setError };
}

export function Photos({ list }) {
  if (!list || !list.length) return null;
  return (
    <div className="photos">
      {list.map((p, i) => {
        const url = photoUrl(typeof p === 'string' ? p : p.url);
        return (
          <a key={i} href={url} target="_blank" rel="noreferrer">
            <img src={url} alt="" />
          </a>
        );
      })}
    </div>
  );
}

export function Modal({ title, onClose, children }) {
  return (
    <div className="modal-bg" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="row between">
          <h3>{title}</h3>
          <button className="btn ghost" onClick={onClose}>✕</button>
        </div>
        {children}
      </div>
    </div>
  );
}

export function Field({ label, children }) {
  return (
    <label className="field">
      <span>{label}</span>
      {children}
    </label>
  );
}

export function Bars({ values, labels }) {
  const max = Math.max(1, ...values);
  return (
    <div className="bars">
      {values.map((v, i) => (
        <div key={i}>
          <i style={{ height: `${Math.round((v / max) * 100)}%` }} title={money(v)} />
          {labels ? labels[i] : ''}
        </div>
      ))}
    </div>
  );
}

export function Stat({ label, value }) {
  return (
    <div className="stat">
      <b>{value}</b>
      <span className="muted small">{label}</span>
    </div>
  );
}

export const lastDays = (n = 7) =>
  Array.from({ length: n }, (_, i) => {
    const d = new Date();
    d.setDate(d.getDate() - (n - 1 - i));
    return d.toLocaleDateString('en', { weekday: 'short' });
  });
