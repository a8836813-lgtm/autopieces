import { useState } from 'react';
import { api } from '../api';
import { useAuth } from '../auth';
import { Empty, ErrorBox, Field, Loading, Modal, money, useAction, useLoad } from '../ui';

const blank = {
  car: '',
  category: 'Brakes',
  title: '',
  problem: '',
  diagnosis: '',
  work_done: '',
  parts_text: '',
  labour_cost: '0',
  parts_cost: '0',
  duration_hours: '1',
  warranty_months: '0',
};

export default function MechanicReports() {
  const { user } = useAuth();
  const { data, error, loading, reload } = useLoad(() => api.get('reports.php'), []);
  const [form, setForm] = useState(null);
  const act = useAction();

  if (loading) return <Loading />;
  const mine = data.reports.filter((r) => r.mechanic_id === user.mechanic_id);
  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  function save(e) {
    e.preventDefault();
    act.run(async () => {
      const labour = Number(form.labour_cost);
      const parts = Number(form.parts_cost);
      await api.post('reports.php', {
        action: form.id ? 'update' : 'create',
        ...(form.id ? { id: form.id } : {}),
        car: form.car,
        category: form.category,
        title: form.title,
        problem: form.problem,
        diagnosis: form.diagnosis,
        work_done: form.work_done,
        parts_text: form.parts_text,
        labour_cost: labour,
        parts_cost: parts,
        cost: labour + parts,
        duration_hours: Number(form.duration_hours),
        warranty_months: Number(form.warranty_months),
      });
      setForm(null);
      reload();
    });
  }

  return (
    <>
      <div className="row between">
        <h1>My reports</h1>
        <button className="btn" onClick={() => setForm(blank)}>New report</button>
      </div>
      <ErrorBox error={error || act.error} />
      {mine.length === 0 && <Empty>No report yet. Reports show clients how you work.</Empty>}
      {mine.map((r) => (
        <div className="card stack" key={r.id}>
          <div className="row between">
            <h3>{r.title}</h3>
            <span className="price">{money(r.cost)}</span>
          </div>
          <div className="muted small">{r.car} · {r.category} · {r.helpful} found it helpful</div>
          <div>{r.diagnosis}</div>
          <div className="row">
            <button className="btn ghost small" onClick={() => setForm({ ...r, labour_cost: String(r.labour_cost), parts_cost: String(r.parts_cost), duration_hours: String(r.duration_hours), warranty_months: String(r.warranty_months) })}>Edit</button>
            <button
              className="btn danger small"
              onClick={() =>
                window.confirm('Delete this report?') &&
                act.run(async () => {
                  await api.post('reports.php', { action: 'delete', id: r.id });
                  reload();
                })
              }
            >
              Delete
            </button>
          </div>
        </div>
      ))}
      {form && (
        <Modal title={form.id ? 'Edit report' : 'New report'} onClose={() => setForm(null)}>
          <form onSubmit={save}>
            <Field label="Car (model and year)"><input value={form.car} onChange={set('car')} required /></Field>
            <Field label="Category"><input value={form.category} onChange={set('category')} required /></Field>
            <Field label="Title"><input value={form.title} onChange={set('title')} required /></Field>
            <Field label="Problem"><textarea value={form.problem} onChange={set('problem')} /></Field>
            <Field label="Diagnosis"><textarea value={form.diagnosis} onChange={set('diagnosis')} /></Field>
            <Field label="Work done"><textarea value={form.work_done} onChange={set('work_done')} /></Field>
            <Field label="Parts used"><input value={form.parts_text} onChange={set('parts_text')} /></Field>
            <div className="row">
              <Field label="Labour (DA)"><input type="number" min="0" value={form.labour_cost} onChange={set('labour_cost')} /></Field>
              <Field label="Parts (DA)"><input type="number" min="0" value={form.parts_cost} onChange={set('parts_cost')} /></Field>
            </div>
            <div className="row">
              <Field label="Hours"><input type="number" min="0" step="0.5" value={form.duration_hours} onChange={set('duration_hours')} /></Field>
              <Field label="Warranty (months)"><input type="number" min="0" value={form.warranty_months} onChange={set('warranty_months')} /></Field>
            </div>
            <ErrorBox error={act.error} />
            <button className="btn" disabled={act.busy}>Save report</button>
          </form>
        </Modal>
      )}
    </>
  );
}
