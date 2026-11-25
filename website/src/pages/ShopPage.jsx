import { useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { api } from '../api';
import { Badge, Empty, ErrorBox, Loading, Photos, Stars, money, useAction, useLoad } from '../ui';
import ReviewForm from './ReviewForm';

export default function ShopPage() {
  const { id } = useParams();
  const nav = useNavigate();
  const shop = useLoad(() => api.get('shops.php', { id }), [id]);
  const stock = useLoad(() => api.get('stock.php', { shop_id: id }), [id]);
  const reviews = useLoad(() => api.get('reviews.php', { target_kind: 'shop', target_id: id }), [id]);
  const favs = useLoad(() => api.get('favorites.php'), []);
  const { busy, error, run } = useAction();
  const [notice, setNotice] = useState('');

  if (shop.loading || stock.loading) return <Loading />;
  if (shop.error) return <ErrorBox error={shop.error} />;
  const s = shop.data.shop;
  const isFav = favs.data?.shops?.includes(s.id);

  function reserve(item) {
    run(async () => {
      await api.post('reservations.php', { action: 'create', stock_id: item.stock_id });
      setNotice(`Reserved ${item.name}. Follow it in Orders.`);
      stock.reload();
    });
  }

  function heart() {
    run(async () => {
      await api.post('favorites.php', { kind: 'shop', target_id: s.id });
      favs.reload();
    });
  }

  return (
    <>
      <div className="row between">
        <h1>{s.name}</h1>
        <div className="row">
          <button className="btn ghost" onClick={heart} disabled={busy}>{isFav ? '♥ Saved' : '♡ Save'}</button>
          <button className="btn" onClick={() => nav(`/messages?kind=shop&id=${s.id}&name=${encodeURIComponent(s.name)}`)}>Chat</button>
        </div>
      </div>
      <div className="card stack">
        <div className="row">
          <Stars value={s.rating} count={s.reviews_count} />
          <Badge tone={s.open_now ? 'good' : 'bad'}>{s.open_now ? 'Open' : 'Closed'}</Badge>
          <span className="muted">{s.parts_count} parts</span>
        </div>
        <div>{s.address} · {s.hours} · <a href={`tel:${s.phone}`}>{s.phone}</a></div>
        {s.about && <div className="muted">{s.about}</div>}
        <div>{s.delivers ? 'Delivery available' : 'Pick up in the shop'}</div>
        <div>Pay with {s.payments}</div>
      </div>
      <ErrorBox error={error} />
      {notice && <div className="ok">{notice}</div>}
      <h2>Parts in stock</h2>
      {stock.data.stock.length === 0 ? (
        <Empty>This shop has no parts listed yet.</Empty>
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr><th>Part</th><th>Serial</th><th>Condition</th><th>Stock</th><th>Price</th><th /></tr>
            </thead>
            <tbody>
              {stock.data.stock.map((i) => (
                <tr key={i.stock_id}>
                  <td>{i.name}<div className="muted small">{i.category} · {i.fits}</div></td>
                  <td>{i.oem}</td>
                  <td>{i.part_condition}</td>
                  <td>{i.quantity > 0 ? i.quantity : <Badge tone="bad">Out</Badge>}</td>
                  <td className="price">{money(i.price)}</td>
                  <td><button className="btn small" disabled={busy || i.quantity < 1} onClick={() => reserve(i)}>Reserve</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      <h2>Reviews</h2>
      <ReviewForm kind="shop" targetId={s.id} onDone={reviews.reload} />
      {(reviews.data?.reviews || []).length === 0 && <Empty>No reviews yet.</Empty>}
      {(reviews.data?.reviews || []).map((r) => (
        <div className="card" key={r.id}>
          <div className="row between"><b>{r.author_name}</b><Stars value={r.stars} /></div>
          <div>{r.comment}</div>
          <Photos list={r.photos} />
          {r.reply && <div className="muted small" style={{ marginTop: 8 }}>Shop reply: {r.reply}</div>}
        </div>
      ))}
      <Link to="/">← Back to search</Link>
    </>
  );
}
