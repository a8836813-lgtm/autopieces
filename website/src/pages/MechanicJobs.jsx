import { useState } from 'react';
import { api, photoUrl } from '../api';
import { Empty, ErrorBox, Field, Loading, Modal, StatusBadge, money, useAction, useLoad } from '../ui';

const FILTERS = ['', 'New', 'Accepted', 'In progress', 'Done', 'Declined'];

export default function MechanicJobs() {
  const [status, setStatus] = useState('');
  const { data, error, loading, reload } = useLoad(() => api.get('jobs.php', { status }), [status]);
  const [invoice, setInvoice] = useState(null);
  const act = useAction();

  function step(job, action, extra = {}) {
    return act.run(async () => {
      await api.post('jobs.php', { action, job_id: job.id, ...extra });
      reload();
    });
  }

  function upload(job, file) {
    if (!file) return;
    act.run(async () => {
      await api.form('jobs.php', { action: 'photo', job_id: job.id }, [['photo', file]]);
      reload();
    });
  }

  async function saveInvoice(e) {
    e.preventDefault();
    await step(invoice, 'invoice', { labour: Number(invoice.labour), parts: Number(invoice.parts) });
    setInvoice(null);
  }

  return (
    <>
      <h1>Jobs</h1>
      <div className="tabs" style={{ flexWrap: 'wrap' }}>
        {FILTERS.map((f) => (
          <button key={f} className={status === f ? 'on' : ''} onClick={() => setStatus(f)}>{f || 'All'}</button>
        ))}
      </div>
      <ErrorBox error={error || act.error} />
      {loading ? (
        <Loading />
      ) : data.jobs.length === 0 ? (
        <Empty>No job.</Empty>
      ) : (
        data.jobs.map((j) => (
          <div className="card stack" key={j.id}>
            <div className="row between">
              <h3>{j.client_name} · {j.car}</h3>
              <StatusBadge status={j.status} />
            </div>
            <div>{j.problem}</div>
            <div className="muted small">
              {j.slot}
              {j.distance_km != null && j.distance_km > 0 ? ` · ${Number(j.distance_km).toFixed(1)} km away` : ''}
              {j.urgent ? ' · urgent' : ''}
            </div>
            {j.invoice_total > 0 && (
              <div>Invoice {j.invoice_no}: <b>{money(j.invoice_total)}</b> {j.paid ? '· paid' : '· unpaid'}</div>
            )}
            {j.photos.length > 0 && (
              <div className="photos">
                {j.photos.map((p) => (
                  <div key={p.id}>
                    <img src={photoUrl(p.url)} alt="" />
                    <div>
                      <button className="btn danger small" onClick={() => step(j, 'remove_photo', { photo_id: p.id })}>Remove</button>
                    </div>
                  </div>
                ))}
              </div>
            )}
            <div className="row">
              {j.status === 'New' && (
                <>
                  <button className="btn small" disabled={act.busy} onClick={() => step(j, 'accept')}>Accept</button>
                  <button className="btn danger small" disabled={act.busy} onClick={() => step(j, 'decline')}>Decline</button>
                </>
              )}
              {j.status === 'Accepted' && <button className="btn small" disabled={act.busy} onClick={() => step(j, 'start')}>Start work</button>}
              {j.status === 'In progress' && <button className="btn orange small" disabled={act.busy} onClick={() => step(j, 'finish')}>Finish</button>}
              {['Accepted', 'In progress', 'Done'].includes(j.status) && (
                <label className="btn ghost small">
                  Add progress photo
                  <input type="file" accept="image/*" hidden onChange={(e) => upload(j, e.target.files[0])} />
                </label>
              )}
              {j.status === 'Done' && (
                <>
                  <button className="btn ghost small" onClick={() => setInvoice({ ...j, labour: j.labour_cost ?? j.price, parts: j.parts_cost })}>Invoice</button>
                  <button className="btn ghost small" disabled={act.busy} onClick={() => step(j, 'paid', { paid: !j.paid })}>
                    {j.paid ? 'Mark unpaid' : 'Mark paid'}
                  </button>
                </>
              )}
            </div>
          </div>
        ))
      )}
      {invoice && (
        <Modal title={`Invoice ${invoice.invoice_no}`} onClose={() => setInvoice(null)}>
          <form onSubmit={saveInvoice}>
            <Field label="Labour (DA)"><input type="number" min="0" value={invoice.labour} onChange={(e) => setInvoice({ ...invoice, labour: e.target.value })} required /></Field>
            <Field label="Parts (DA)"><input type="number" min="0" value={invoice.parts} onChange={(e) => setInvoice({ ...invoice, parts: e.target.value })} required /></Field>
            <div className="price">Total {money(Number(invoice.labour) + Number(invoice.parts))}</div>
            <div style={{ marginTop: 10 }}><button className="btn" disabled={act.busy}>Save invoice</button></div>
          </form>
        </Modal>
      )}
    </>
  );
}
