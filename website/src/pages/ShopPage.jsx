import { Link, useNavigate, useParams } from 'react-router-dom';
import { api } from '../api';
import { Monogram, PartArt } from '../art';
import { Badge, Empty, ErrorBox, Loading, Photos, Stars, money, useAction, useLoad, useToast } from '../ui';
import ReviewForm from './ReviewForm';

export default function ShopPage() {
  const { id } = useParams();
  const nav = useNavigate();
  const toast = useToast();
  const shop = useLoad(() => api.get('shops.php', { id }), [id]);
  const stock = useLoad(() => api.get('stock.php', { shop_id: id }), [id]);
  const reviews = useLoad(() => api.get('reviews.php', { target_kind: 'shop', target_id: id }), [id]);
  const favs = useLoad(() => api.get('favorites.php'), []);
  const { busy, error, run } = useAction();

  if (shop.loading || stock.loading) return <Loading />;
  if (shop.error) return <ErrorBox error={shop.error} />;
  const s = shop.data.shop;
  const isFav = favs.data?.shops?.includes(s.id);
  const payments = (s.payments || 'Cash').split(',').map((x) => x.trim()).filter(Boolean);

  function reserve(item) {
    run(async () => {
      await api.post('reservations.php', { action: 'create', stock_id: item.stock_id });
      toast(`${item.name} reserved. Follow it in Orders.`);
      stock.reload();
    });
  }

  function heart() {
    run(async () => {
      await api.post('favorites.php', { kind: 'shop', target_id: s.id });
      toast(isFav ? 'Removed from saved' : 'Shop saved');
      favs.reload();
    });
  }

  return (
    <>
      <div className="profile-head">
        <Monogram name={s.name} size={72} />
        <div className="grow">
          <h1>{s.name}</h1>
          <div className="row">
            <Stars value={s.rating} count={s.reviews_count} />
            <Badge tone={s.open_now ? 'good' : 'bad'}>{s.open_now ? 'Open now' : 'Closed'}</Badge>
            <span className="muted">{s.parts_count} parts in stock</span>
          </div>
        </div>
        <div className="row">
          <button className="btn ghost" onClick={heart} disabled={busy}>{isFav ? '♥ Saved' : '♡ Save'}</button>
          <button className="btn" onClick={() => nav(`/messages?kind=shop&id=${s.id}&name=${encodeURIComponent(s.name)}`)}>Chat with shop</button>
        </div>
      </div>
      <ErrorBox error={error} />
      <div className="split">
        <div>
          <h2 style={{ marginTop: 0 }}>Parts in stock</h2>
          {stock.data.stock.length === 0 ? (
            <Empty>This shop has not listed any part yet.</Empty>
          ) : (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr><th>Part</th><th>Condition</th><th>Stock</th><th>Price</th><th /></tr>
                </thead>
                <tbody>
                  {stock.data.stock.map((i) => (
                    <tr key={i.stock_id}>
                      <td>
                        <div className="item">
                          <PartArt category={i.category} size={42} />
                          <div className="grow">
                            <Link to={`/part/${i.part_id}`}>{i.name}</Link>
                            <div className="muted small">{i.oem} · {i.fits}</div>
                          </div>
                        </div>
                      </td>
                      <td>{i.part_condition}</td>
                      <td>{i.quantity > 0 ? i.quantity : <Badge tone="bad">Out</Badge>}</td>
                      <td className="price">{money(i.price)}</td>
                      <td><button className="btn orange small" disabled={busy || i.quantity < 1} onClick={() => reserve(i)}>Reserve</button></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
          <h2>Reviews <ReviewForm kind="shop" targetId={s.id} onDone={() => { toast('Review sent'); reviews.reload(); }} /></h2>
          {(reviews.data?.reviews || []).length === 0 && <Empty>No review yet. Be the first after you pick up a part.</Empty>}
          {(reviews.data?.reviews || []).map((r) => (
            <div className="card" key={r.id}>
              <div className="row between"><b>{r.author_name}</b><Stars value={r.stars} /></div>
              <div>{r.comment}</div>
              <Photos list={r.photos} />
              {r.reply && <div className="muted small" style={{ marginTop: 8 }}><b>Shop reply:</b> {r.reply}</div>}
            </div>
          ))}
        </div>
        <aside className="aside">
          <div className="card">
            <dl className="facts">
              {s.about && <div><dt>About</dt><dd>{s.about}</dd></div>}
              <div><dt>Address</dt><dd>{s.address}</dd></div>
              <div><dt>Opening hours</dt><dd>{s.hours}</dd></div>
              <div><dt>Delivery</dt><dd>{s.delivers ? 'Available' : 'Pick up in the shop'}</dd></div>
              <div><dt>Payment</dt><dd className="chips">{payments.map((p) => <span className="chip" key={p}>{p}</span>)}</dd></div>
            </dl>
          </div>
          <a className="btn ghost" style={{ display: 'block' }} href={`tel:${s.phone}`}>Call {s.phone}</a>
        </aside>
      </div>
    </>
  );
}
