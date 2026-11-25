import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from './api';

const SEEN = 'autopieces_seen_notifications';

function readSeen() {
  try {
    return new Set(JSON.parse(localStorage.getItem(SEEN) || '[]'));
  } catch {
    return new Set();
  }
}

function writeSeen(set) {
  try {
    localStorage.setItem(SEEN, JSON.stringify([...set].slice(-300)));
  } catch {}
}

async function safe(fn, fallback) {
  try {
    return await fn();
  } catch {
    return fallback;
  }
}

async function collect(user) {
  const out = [];
  const inboxParams =
    user.role === 'client'
      ? { as: 'client', client_ref: user.email.toLowerCase() }
      : { as: 'peer', peer_kind: user.role, peer_id: String(user.role === 'shop' ? user.shop_id : user.mechanic_id) };
  const inbox = await safe(() => api.get('chat/inbox.php', inboxParams), { threads: [] });
  inbox.threads
    .filter((t) => t.unread > 0)
    .forEach((t) =>
      out.push({
        key: `msg-${t.client_ref}-${t.peer_kind}-${t.peer_id}-${t.last.id}`,
        icon: '💬',
        text: `${t.unread} new message${t.unread > 1 ? 's' : ''} from ${user.role === 'client' ? t.peer_name || 'a seller' : t.client_name || t.client_ref}`,
        to: '/messages',
      })
    );

  if (user.role === 'client') {
    const alerts = await safe(() => api.get('price_alerts.php'), { alerts: [] });
    alerts.alerts
      .filter((a) => a.triggered)
      .forEach((a) =>
        out.push({ key: `alert-${a.part_id}-${a.current_price}`, icon: '🔔', text: `${a.part_name} reached your price (${a.current_price} DA)`, to: `/part/${a.part_id}` })
      );
    const res = await safe(() => api.get('reservations.php'), { reservations: [] });
    res.reservations
      .filter((r) => ['Confirmed', 'Declined', 'Picked up'].includes(r.status))
      .forEach((r) =>
        out.push({
          key: `res-${r.id}-${r.status}`,
          icon: '🧾',
          text: r.status === 'Confirmed' ? `${r.part_name} is ready at ${r.shop_name}` : `Your order of ${r.part_name} was ${r.status.toLowerCase()}`,
          to: '/orders',
        })
      );
    const ap = await safe(() => api.get('appointments.php'), { appointments: [] });
    ap.appointments
      .filter((a) => ['Accepted', 'In progress', 'Done', 'Declined'].includes(a.job_status))
      .forEach((a) =>
        out.push({ key: `app-${a.id}-${a.job_status}`, icon: '🔧', text: `${a.mechanic_name}: ${a.service} is ${a.job_status.toLowerCase()}`, to: '/appointments' })
      );
  }

  if (user.role === 'shop') {
    const res = await safe(() => api.get('reservations.php', { as: 'shop', status: 'Pending' }), { reservations: [] });
    res.reservations.forEach((r) =>
      out.push({ key: `order-${r.id}`, icon: '🧾', text: `New order: ${r.part_name} for ${r.client_name}`, to: '/orders' })
    );
    const st = await safe(() => api.get('shop_stats.php'), null);
    if (st && st.out_of_stock > 0) out.push({ key: `oos-${st.out_of_stock}`, icon: '📦', text: `${st.out_of_stock} part(s) out of stock`, to: '/stock' });
    if (st && st.low_stock > 0) out.push({ key: `low-${st.low_stock}`, icon: '📉', text: `${st.low_stock} part(s) running low`, to: '/stock' });
  }

  if (user.role === 'mechanic') {
    const jobs = await safe(() => api.get('jobs.php'), { jobs: [] });
    jobs.jobs
      .filter((j) => j.status === 'New')
      .forEach((j) => out.push({ key: `job-${j.id}`, icon: '🔧', text: `New request from ${j.client_name}: ${j.problem}`, to: '/jobs' }));
    jobs.jobs
      .filter((j) => j.status === 'Done' && !j.paid)
      .forEach((j) => out.push({ key: `unpaid-${j.id}`, icon: '💰', text: `Invoice ${j.invoice_no} is unpaid`, to: '/jobs' }));
  }
  return out;
}

export default function Notifications({ user }) {
  const [items, setItems] = useState([]);
  const [seen, setSeen] = useState(readSeen);
  const [open, setOpen] = useState(false);
  const box = useRef(null);
  const nav = useNavigate();

  useEffect(() => {
    let alive = true;
    const tick = async () => {
      const list = await collect(user);
      if (alive) setItems(list);
    };
    tick();
    const id = setInterval(tick, 15000);
    return () => {
      alive = false;
      clearInterval(id);
    };
  }, [user]);

  useEffect(() => {
    const close = (e) => {
      if (box.current && !box.current.contains(e.target)) setOpen(false);
    };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, []);

  const unseen = items.filter((i) => !seen.has(i.key));

  function toggle() {
    if (open) {
      const next = new Set(seen);
      items.forEach((i) => next.add(i.key));
      setSeen(next);
      writeSeen(next);
    }
    setOpen(!open);
  }

  function go(item) {
    const next = new Set(seen);
    items.forEach((i) => next.add(i.key));
    setSeen(next);
    writeSeen(next);
    setOpen(false);
    nav(item.to);
  }

  return (
    <div className="bell" ref={box}>
      <button className="btn ghost small" onClick={toggle} aria-label="Notifications">
        🔔{unseen.length > 0 && <span className="dot">{unseen.length}</span>}
      </button>
      {open && (
        <div className="bell-menu">
          {items.length === 0 && <div className="empty">Nothing new.</div>}
          {items.map((i) => (
            <div key={i.key} className={`bell-item ${seen.has(i.key) ? '' : 'new'}`} onClick={() => go(i)}>
              <span>{i.icon}</span> {i.text}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
