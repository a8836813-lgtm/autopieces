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
          <div className="ticket" key={r.id} style={{ marginBottom: 12 }}>
            <div className="ticket-stub">
              <div>
                <div className="small" style={{ fontWeight: 600 }}>{r.car}</div>
                <div className="small">{r.mechanic_name}</div>
                <div className="small">{r.category}</div>
              </div>
              <div>
                <span className="price">{money(r.cost)}</span>
                <div className="small">{r.warranty_months} months warranty · {r.duration_hours} h</div>
              </div>
            </div>
            <dl className="ticket-body" style={{ margin: 0 }}>
              <div><h3>{r.title}</h3></div>
              <div><dt>Problem</dt><dd>{r.problem}</dd></div>
              <div><dt>Diagnosis</dt><dd>{r.diagnosis}</dd></div>
              <div><dt>Work done</dt><dd>{r.work_done}</dd></div>
              <div className="row between">
                <span className="muted small">Labour {money(r.labour_cost)} · Parts {money(r.parts_cost)} ({r.parts_text})</span>
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
            </dl>
          </div>
        ))
      )}
    </>
  );
}
