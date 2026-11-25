import { useState } from 'react';
import { api } from '../api';
import { Empty, ErrorBox, Loading, money, useAction, useLoad } from '../ui';

export default function Reports() {
  const [q, setQ] = useState('');
  const { data, error, loading, reload } = useLoad(() => api.get('reports.php'), []);
  const { run } = useAction();

  const list = (data?.reports || []).filter((r) =>
    `${r.title} ${r.car} ${r.category} ${r.diagnosis} ${r.mechanic_name}`.toLowerCase().includes(q.toLowerCase())
  );

  return (
    <>
      <h1>Repair reports</h1>
      <input style={{ width: '100%', marginBottom: 12 }} placeholder="Search by car, problem or category" value={q} onChange={(e) => setQ(e.target.value)} />
      <ErrorBox error={error} />
      {loading ? (
        <Loading />
      ) : list.length === 0 ? (
        <Empty>No report found.</Empty>
      ) : (
        list.map((r) => (
          <div className="card stack" key={r.id}>
            <div className="row between">
              <h3>{r.title}</h3>
              <span className="price">{money(r.cost)}</span>
            </div>
            <div className="muted small">{r.car} · {r.category} · by {r.mechanic_name}</div>
            <div><b>Problem:</b> {r.problem}</div>
            <div><b>Diagnosis:</b> {r.diagnosis}</div>
            <div><b>Work done:</b> {r.work_done}</div>
            <div className="muted small">
              Labour {money(r.labour_cost)} · Parts {money(r.parts_cost)} ({r.parts_text}) · {r.duration_hours} h · {r.warranty_months} months warranty
            </div>
            <div>
              <button
                className="btn ghost small"
                onClick={() =>
                  run(async () => {
                    await api.post('reports.php', { action: 'helpful', id: r.id });
                    reload();
                  })
                }
              >
                {r.voted ? '👍 Helpful' : '👍 Mark helpful'} · {r.helpful}
              </button>
            </div>
          </div>
        ))
      )}
    </>
  );
}
