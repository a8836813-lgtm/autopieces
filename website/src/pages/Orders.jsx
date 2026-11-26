import { api } from '../api';
import { Monogram } from '../art';
import { Empty, ErrorBox, Loading, StatusBadge, money, useAction, useLoad } from '../ui';
import ReviewForm from './ReviewForm';

export default function Orders() {
  const { data, error, loading, reload } = useLoad(() => api.get('reservations.php'), []);
  const act = useAction();

  return (
    <>
      <h1>My orders</h1>
      <ErrorBox error={error || act.error} />
      {loading ? (
        <Loading />
      ) : data.reservations.length === 0 ? (
        <Empty>No reservation yet. Search a part and reserve it.</Empty>
      ) : (
        data.reservations.map((r) => (
          <div className="card stack" key={r.id}>
            <div className="item">
              <Monogram name={r.shop_name} size={44} />
              <div className="grow"><h3 style={{ margin: 0 }}>{r.part_name}</h3><div className="muted small">{r.shop_name}</div></div>
              <StatusBadge status={r.status} />
            </div>
            <div className="muted small">{r.shop_name} · {r.shop_phone} · {r.created_at}</div>
            <div className="price">{money(r.price)}</div>
            <div className="row">
              {['Pending', 'Confirmed'].includes(r.status) && (
                <button
                  className="btn danger small"
                  onClick={() =>
                    act.run(async () => {
                      await api.post('reservations.php', { action: 'cancel', id: r.id });
                      reload();
                    })
                  }
                >
                  Cancel
                </button>
              )}
              {r.status === 'Picked up' && !r.reviewed && (
                <ReviewForm kind="shop" targetId={r.shop_id} reservationId={r.id} onDone={reload} />
              )}
            </div>
          </div>
        ))
      )}
    </>
  );
}
