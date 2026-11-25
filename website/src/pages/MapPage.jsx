import { useState } from 'react';
import { Link } from 'react-router-dom';
import { CircleMarker, MapContainer, Popup, TileLayer } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import { api } from '../api';
import { REFERENCE } from '../config';
import { Badge, ErrorBox, Loading, Stars, useLoad } from '../ui';

export default function MapPage() {
  const shops = useLoad(() => api.get('shops.php'), []);
  const mechs = useLoad(() => api.get('mechanics.php'), []);
  const [showShops, setShowShops] = useState(true);
  const [showMechs, setShowMechs] = useState(true);
  const [onlyOpen, setOnlyOpen] = useState(false);

  if (shops.loading || mechs.loading) return <Loading />;
  const shopList = (shops.data?.shops || []).filter((s) => s.lat && s.lng && (!onlyOpen || s.open_now));
  const mechList = (mechs.data?.mechanics || []).filter((m) => m.lat && m.lng && (!onlyOpen || m.available));

  return (
    <>
      <h1>Map</h1>
      <ErrorBox error={shops.error || mechs.error} />
      <div className="row card">
        <label className="row"><input type="checkbox" checked={showShops} onChange={(e) => setShowShops(e.target.checked)} /> <span className="legend shop" /> Shops ({shopList.length})</label>
        <label className="row"><input type="checkbox" checked={showMechs} onChange={(e) => setShowMechs(e.target.checked)} /> <span className="legend mech" /> Mechanics ({mechList.length})</label>
        <label className="row"><input type="checkbox" checked={onlyOpen} onChange={(e) => setOnlyOpen(e.target.checked)} /> Open or available only</label>
      </div>
      <div className="map-box">
        <MapContainer center={[REFERENCE.lat, REFERENCE.lng]} zoom={11} scrollWheelZoom style={{ height: '100%', width: '100%' }}>
          <TileLayer attribution="&copy; OpenStreetMap contributors" url="https://tile.openstreetmap.org/{z}/{x}/{y}.png" />
          {showShops &&
            shopList.map((s) => (
              <CircleMarker key={`s${s.id}`} center={[s.lat, s.lng]} radius={10} pathOptions={{ color: '#0f4c5c', fillColor: '#0f4c5c', fillOpacity: 0.85 }}>
                <Popup>
                  <b>{s.name}</b>
                  <br />
                  <Stars value={s.rating} count={s.reviews_count} />
                  <br />
                  <Badge tone={s.open_now ? 'good' : 'bad'}>{s.open_now ? 'Open' : 'Closed'}</Badge> {s.hours}
                  <br />
                  <Link to={`/shop/${s.id}`}>Open shop page</Link>
                </Popup>
              </CircleMarker>
            ))}
          {showMechs &&
            mechList.map((m) => (
              <CircleMarker key={`m${m.id}`} center={[m.lat, m.lng]} radius={10} pathOptions={{ color: '#c2410c', fillColor: '#c2410c', fillOpacity: 0.85 }}>
                <Popup>
                  <b>{m.name}</b>
                  <br />
                  {m.specialties}
                  <br />
                  <Stars value={m.rating} count={m.reviews_count} />
                  <br />
                  <Badge tone={m.available ? 'good' : 'bad'}>{m.available ? 'Available' : 'Busy'}</Badge>
                  <br />
                  <Link to={`/mechanic/${m.id}`}>Open mechanic page</Link>
                </Popup>
              </CircleMarker>
            ))}
        </MapContainer>
      </div>
    </>
  );
}
