import { api } from '../api';
import { useAuth } from '../auth';
import { Empty, ErrorBox, Loading, Photos, Stars, useAction, useLoad } from '../ui';

export default function Reviews({ kind }) {
  const { user } = useAuth();
  const id = kind === 'shop' ? user.shop_id : user.mechanic_id;
  const { data, error, loading, reload } = useLoad(() => api.get('reviews.php', { target_kind: kind, target_id: id }), []);
  const act = useAction();

  function reply(r) {
    const text = window.prompt('Your reply', r.reply || '');
    if (!text) return;
    act.run(async () => {
      await api.post('reviews.php', { action: 'reply', review_id: r.id, reply: text });
      reload();
    });
  }

  if (loading) return <Loading />;
  return (
    <>
      <h1>Reviews</h1>
      <ErrorBox error={error || act.error} />
      <div className="card"><Stars value={data.average} count={data.count} /></div>
      {data.reviews.length === 0 && <Empty>No review yet.</Empty>}
      {data.reviews.map((r) => (
        <div className="card stack" key={r.id}>
          <div className="row between"><b>{r.author_name}</b><Stars value={r.stars} /></div>
          <div>{r.comment}</div>
          <Photos list={r.photos} />
          {r.reply && <div className="muted small">Your reply: {r.reply}</div>}
          <button className="btn ghost small" onClick={() => reply(r)}>{r.reply ? 'Edit reply' : 'Reply'}</button>
        </div>
      ))}
    </>
  );
}
