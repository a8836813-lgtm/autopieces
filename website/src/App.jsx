import { useEffect, useState } from 'react';
import { NavLink, Navigate, Route, Routes } from 'react-router-dom';
import { useAuth } from './auth';
import { api } from './api';
import { Loading } from './ui';
import Login from './pages/Login';
import Search from './pages/Search';
import ShopPage from './pages/ShopPage';
import Mechanics from './pages/Mechanics';
import MechanicPage from './pages/MechanicPage';
import Orders from './pages/Orders';
import Appointments from './pages/Appointments';
import Saved from './pages/Saved';
import Reports from './pages/Reports';
import Messages from './pages/Messages';
import ShopDashboard from './pages/ShopDashboard';
import ShopStock from './pages/ShopStock';
import ShopOrders from './pages/ShopOrders';
import ShopSettings from './pages/ShopSettings';
import MechanicDashboard from './pages/MechanicDashboard';
import MechanicJobs from './pages/MechanicJobs';
import MechanicReports from './pages/MechanicReports';
import MechanicProfile from './pages/MechanicProfile';
import Reviews from './pages/Reviews';
import MapPage from './pages/MapPage';
import PartPage from './pages/PartPage';
import Notifications from './notifications';

const MENUS = {
  client: [
    ['/', 'Search'],
    ['/map', 'Map'],
    ['/mechanics', 'Mechanics'],
    ['/reports', 'Reports'],
    ['/orders', 'Orders'],
    ['/appointments', 'Appointments'],
    ['/saved', 'Saved'],
    ['/messages', 'Messages'],
  ],
  shop: [
    ['/', 'Dashboard'],
    ['/stock', 'Stock'],
    ['/orders', 'Orders'],
    ['/reviews', 'Reviews'],
    ['/messages', 'Messages'],
    ['/settings', 'My shop'],
  ],
  mechanic: [
    ['/', 'Dashboard'],
    ['/jobs', 'Jobs'],
    ['/reports', 'My reports'],
    ['/reviews', 'Reviews'],
    ['/messages', 'Messages'],
    ['/profile', 'Profile'],
  ],
};

function useUnread(user) {
  const [n, setN] = useState(0);
  useEffect(() => {
    if (!user) return undefined;
    let alive = true;
    const params =
      user.role === 'client'
        ? { as: 'client', client_ref: user.email.toLowerCase() }
        : { as: 'peer', peer_kind: user.role, peer_id: String(user.role === 'shop' ? user.shop_id : user.mechanic_id) };
    const tick = async () => {
      try {
        const r = await api.get('chat/inbox.php', params);
        if (alive) setN(r.threads.reduce((s, t) => s + t.unread, 0));
      } catch {}
    };
    tick();
    const id = setInterval(tick, 8000);
    return () => {
      alive = false;
      clearInterval(id);
    };
  }, [user]);
  return n;
}

function Shell() {
  const { user, logout } = useAuth();
  const unread = useUnread(user);
  const menu = MENUS[user.role];
  return (
    <>
      <header className="topbar">
        <div className="topbar-in">
          <div className="brand">Auto<span>Pièces</span></div>
          <nav className="nav">
            {menu.map(([to, label]) => (
              <NavLink key={to} to={to} end={to === '/'} className={({ isActive }) => (isActive ? 'active' : '')}>
                {label}
                {label === 'Messages' && unread > 0 && <span className="dot">{unread}</span>}
              </NavLink>
            ))}
          </nav>
          <Notifications user={user} />
          <span className="muted small">{user.name}</span>
          <button className="btn ghost small" onClick={logout}>Log out</button>
        </div>
      </header>
      <main className="page">
        {user.role === 'client' && (
          <Routes>
            <Route path="/" element={<Search />} />
            <Route path="/shop/:id" element={<ShopPage />} />
            <Route path="/map" element={<MapPage />} />
            <Route path="/part/:id" element={<PartPage />} />
            <Route path="/mechanics" element={<Mechanics />} />
            <Route path="/mechanic/:id" element={<MechanicPage />} />
            <Route path="/reports" element={<Reports />} />
            <Route path="/orders" element={<Orders />} />
            <Route path="/appointments" element={<Appointments />} />
            <Route path="/saved" element={<Saved />} />
            <Route path="/messages" element={<Messages />} />
            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        )}
        {user.role === 'shop' && (
          <Routes>
            <Route path="/" element={<ShopDashboard />} />
            <Route path="/stock" element={<ShopStock />} />
            <Route path="/orders" element={<ShopOrders />} />
            <Route path="/reviews" element={<Reviews kind="shop" />} />
            <Route path="/messages" element={<Messages />} />
            <Route path="/settings" element={<ShopSettings />} />
            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        )}
        {user.role === 'mechanic' && (
          <Routes>
            <Route path="/" element={<MechanicDashboard />} />
            <Route path="/jobs" element={<MechanicJobs />} />
            <Route path="/reports" element={<MechanicReports />} />
            <Route path="/reviews" element={<Reviews kind="mechanic" />} />
            <Route path="/messages" element={<Messages />} />
            <Route path="/profile" element={<MechanicProfile />} />
            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        )}
      </main>
    </>
  );
}

export default function App() {
  const { user, ready } = useAuth();
  if (!ready) return <Loading />;
  return user ? <Shell /> : <Login />;
}
