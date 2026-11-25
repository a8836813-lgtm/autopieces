import { api } from '../api';
import { Empty, ErrorBox, Loading, Photos, StatusBadge, money, useAction, useLoad } from '../ui';
import ReviewForm from './ReviewForm';

export default function Appointments() {
  const { data, error, loading, reload } = useLoad(() => api.get('appointments.php'), []);
  const act = useAction();

  return (
    <>
      <h1>My appointments</h1>
      <ErrorBox error={error || act.error} />
      {loading ? (
        <Loading />
      ) : data.appointments.length === 0 ? (
        <Empty>No appointment yet. Open a mechanic and press Book.</Empty>
      ) : (
        data.appointments.map((a) => (
          <div className="card stack" key={a.id}>
            <div className="row between">
              <h3>{a.service} · {a.mechanic_name}</h3>
              <StatusBadge status={a.job_status || a.appointment_status} />
            </div>
            <div className="muted small">{a.when_at} · {a.mechanic_phone}</div>
            {a.note && <div>{a.note}</div>}
            {a.invoice_total != null && (
              <div>
                Invoice {a.invoice_no}: <b>{money(a.invoice_total)}</b> {a.paid ? '· paid' : '· unpaid'}
              </div>
            )}
            <Photos list={a.photos} />
            <div className="row">
              {a.job_status === 'New' && (
                <button
                  className="btn danger small"
                  onClick={() =>
                    act.run(async () => {
                      await api.post('appointments.php', { action: 'cancel', id: a.id });
                      reload();
                    })
                  }
                >
                  Cancel
                </button>
              )}
              {a.job_status === 'Done' && <ReviewForm kind="mechanic" targetId={a.mechanic_id} onDone={reload} />}
            </div>
          </div>
        ))
      )}
    </>
  );
}
