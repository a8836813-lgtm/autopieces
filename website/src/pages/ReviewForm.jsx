import { useState } from 'react';
import { api } from '../api';
import { ErrorBox, useAction } from '../ui';

export default function ReviewForm({ kind, targetId, reservationId, onDone }) {
  const [open, setOpen] = useState(false);
  const [stars, setStars] = useState(5);
  const [comment, setComment] = useState('');
  const [files, setFiles] = useState([]);
  const { busy, error, run } = useAction();

  function submit(e) {
    e.preventDefault();
    run(async () => {
      await api.form(
        'reviews.php',
        {
          target_kind: kind,
          target_id: targetId,
          stars,
          comment,
          ...(reservationId ? { reservation_id: reservationId } : {}),
        },
        files.slice(0, 3).map((f) => ['photos[]', f])
      );
      setOpen(false);
      setComment('');
      setFiles([]);
      onDone && onDone();
    });
  }

  if (!open) {
    return <button className="btn ghost" onClick={() => setOpen(true)}>Write a review</button>;
  }
  return (
    <form className="card stack" onSubmit={submit}>
      <div className="row">
        {[1, 2, 3, 4, 5].map((n) => (
          <button type="button" key={n} className="btn ghost small" onClick={() => setStars(n)}>
            {n <= stars ? '★' : '☆'}
          </button>
        ))}
      </div>
      <textarea placeholder="Your experience" value={comment} onChange={(e) => setComment(e.target.value)} required />
      <input type="file" accept="image/*" multiple onChange={(e) => setFiles([...e.target.files])} />
      <ErrorBox error={error} />
      <div className="row">
        <button className="btn" disabled={busy}>Send review</button>
        <button type="button" className="btn ghost" onClick={() => setOpen(false)}>Cancel</button>
      </div>
    </form>
  );
}
