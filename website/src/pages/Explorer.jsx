import { Suspense, lazy, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { api } from '../api';
import { BRANDS } from '../vehicles';
import { fitsCar, indexFitments } from '../carfilter';
import { KINDS } from '../explorer/kinds';
import { VIEWS } from '../explorer/views';
import { PARTS_3D } from '../explorer/parts3d';
import { Badge, Loading, money } from '../ui';

const CAR_NOTES = {
  'audi:RS3': {
    engine: 'On the Audi RS3 this is a 2.5 litre five-cylinder turbo, which is why five cylinders are drawn.',
    gearbox: 'On the Audi RS3 this is a 7-speed dual-clutch automatic with four-wheel drive.',
  },
};

const ease = (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);

function useCamera(resetKey, full) {
  const [X, Y, W, H] = full;
  const [box, setBox] = useState(full);
  const current = useRef(full);
  const frame = useRef(0);

  const go = useCallback((to) => {
    cancelAnimationFrame(frame.current);
    const from = current.current;
    const reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (reduce) {
      current.current = to;
      setBox(to);
      return;
    }
    const start = performance.now();
    const tick = (now) => {
      const k = Math.min(1, (now - start) / 550);
      const e = ease(k);
      const next = from.map((v, i) => v + (to[i] - v) * e);
      current.current = next;
      setBox(next);
      if (k < 1) frame.current = requestAnimationFrame(tick);
    };
    frame.current = requestAnimationFrame(tick);
  }, []);

  const reset = useCallback(() => go([X, Y, W, H]), [go, X, Y, W, H]);

  const focus = useCallback(
    (el) => {
      if (!el) return;
      const b = el.getBBox();
      let w = Math.max(b.width * 1.9, 300);
      let h = w * (H / W);
      if (h < b.height * 1.9) {
        h = b.height * 1.9;
        w = h * (W / H);
      }
      w = Math.min(w, W);
      h = Math.min(h, H);
      const x = Math.max(X, Math.min(X + W - w, b.x + b.width / 2 - w / 2));
      const y = Math.max(Y, Math.min(Y + H - h, b.y + b.height / 2 - h / 2));
      go([x, y, w, h]);
    },
    [go, X, Y, W, H],
  );

  useEffect(() => () => cancelAnimationFrame(frame.current), []);
  useEffect(() => {
    cancelAnimationFrame(frame.current);
    current.current = [X, Y, W, H];
    setBox([X, Y, W, H]);
  }, [X, Y, W, H, resetKey]);

  return { box, focus, reset, zoomed: box[2] < W - 1 };
}

function Prices({ kind, brand, model, fitments }) {
  const [state, setState] = useState({ loading: true });

  useEffect(() => {
    let live = true;
    setState({ loading: true });
    (async () => {
      try {
        let r = await api.get('parts_search.php', { q: kind.q });
        let rows = r.results;
        if (!rows.length) {
          r = await api.get('parts_search.php', { category: kind.category });
          rows = r.results;
        }
        rows = [...rows].sort((a, b) => a.price - b.price);
        const fit = rows.filter((x) => fitsCar(fitments, brand, model, x.part_id));
        if (live) setState(fit.length || !rows.length ? { rows: fit } : { rows, other: true });
      } catch (e) {
        if (live) setState({ error: e });
      }
    })();
    return () => {
      live = false;
    };
  }, [kind, brand, model, fitments]);

  if (state.loading) return <Loading />;
  if (state.error) return <div className="alert">Prices could not be loaded. Check that the server is running.</div>;
  const rows = state.rows;
  if (!rows.length) return <p className="muted small">No shop lists this part yet.</p>;
  const avg = Math.round(rows.reduce((s, r) => s + r.price, 0) / rows.length);
  return (
    <>
      {state.other && <p className="muted small" style={{ margin: '0 0 8px' }}>No listing is marked for this car yet. These are the cheapest listings for other cars, so check the fit with the shop.</p>}
      <div className="xprices">
        <div><span className="muted small">Cheapest</span><b className="price">{money(rows[0].price)}</b></div>
        <div><span className="muted small">Average</span><b>{money(avg)}</b></div>
        <div><span className="muted small">Listings</span><b>{rows.length}</b></div>
      </div>
      {rows.slice(0, 3).map((r) => (
        <div className="xrow" key={r.stock_id}>
          <div className="grow">
            <Link to={`/part/${r.part_id}`}>{r.name}</Link>
            <div className="muted small">
              <Link to={`/shop/${r.shop_id}`}>{r.shop_name}</Link> · {r.part_condition}
            </div>
          </div>
          <Badge tone={r.open_now ? 'good' : 'bad'}>{r.open_now ? 'Open' : 'Closed'}</Badge>
          <b>{money(r.price)}</b>
        </div>
      ))}
    </>
  );
}

function ReportsList({ kind }) {
  const [state, setState] = useState({ loading: true });
  useEffect(() => {
    let live = true;
    setState({ loading: true });
    api
      .get('reports.php', { q: kind.report, sort: 'helpful' })
      .then((r) => live && setState({ rows: r.reports }))
      .catch((e) => live && setState({ error: e }));
    return () => {
      live = false;
    };
  }, [kind]);

  if (state.loading) return <Loading />;
  if (state.error) return <div className="alert">Reports could not be loaded.</div>;
  if (!state.rows.length) return <p className="muted small">No mechanic has written a report about this part yet.</p>;
  return (
    <>
      {state.rows.slice(0, 3).map((r) => (
        <div className="xrow col" key={r.id}>
          <div className="row between">
            <b>{r.title}</b>
            <span className="muted small">{r.helpful} found it helpful</span>
          </div>
          <div className="muted small">
            {r.car} · by <Link to={`/mechanic/${r.mechanic_id}`}>{r.mechanic_name}</Link>
          </div>
          <div className="small">{r.diagnosis || r.problem}</div>
          <div className="small">
            <b>{money(r.cost)}</b> total
            {r.duration_hours ? ` · ${r.duration_hours} h` : ''}
            {r.warranty_months ? ` · ${r.warranty_months} months warranty` : ''}
          </div>
        </div>
      ))}
      <Link className="small" to={`/reports`}>All repair reports</Link>
    </>
  );
}

const Car3D = lazy(() => import('../explorer/Car3D'));

export default function Explorer() {
  const [params] = useSearchParams();
  const [brandId, setBrandId] = useState(params.get('brand') || 'audi');
  const [model, setModel] = useState(params.get('model') || 'RS3');
  const [mode, setMode] = useState(params.get('mode') === '2d' ? '2d' : '3d');
  const [viewId, setViewId] = useState('side');
  const [angle, setAngle] = useState('angle');
  const carRef = useRef(null);
  const is3d = mode === '3d';
  const [selected, setSelected] = useState(null);
  const [hover, setHover] = useState(null);
  const [fitments, setFitments] = useState({});
  const svgRef = useRef(null);
  const view = VIEWS[viewId];
  const cam = useCamera(viewId, view.full);
  const brand = BRANDS.find((b) => b.id === brandId);

  useEffect(() => {
    api.get('parts.php').then((r) => setFitments(indexFitments(r.parts))).catch(() => {});
  }, []);

  const list = is3d ? PARTS_3D : view.parts;
  const byId = useMemo(() => Object.fromEntries(list.map((p) => [p.id, p])), [list]);
  const chosen = selected ? byId[selected] : null;
  const kind = chosen ? KINDS[chosen.kind] : null;
  const note = chosen && CAR_NOTES[`${brandId}:${model}`]?.[chosen.kind];

  function pick(id) {
    if (!id) {
      clear();
      return;
    }
    setSelected(id);
    if (is3d) carRef.current?.focus(id);
    else cam.focus(svgRef.current?.querySelector(`[data-part="${id}"]`));
  }

  function clear() {
    setSelected(null);
    if (is3d) carRef.current?.preset(angle);
    else cam.reset();
  }

  function changeMode(m) {
    setMode(m);
    setSelected(null);
    setHover(null);
  }

  function changeAngle(a) {
    setAngle(a);
    setSelected(null);
    carRef.current?.preset(a);
  }

  function changeView(v) {
    setViewId(v);
    setSelected(null);
    setHover(null);
  }

  const labelOf = (id) => (id ? byId[id]?.name : '');
  const chips = list.filter((p, i, all) => all.findIndex((x) => x.kind === p.kind) === i);
  const carName = brand ? `${brand.name}${model ? ` ${model}` : ''}` : 'Your car';
  const searchLink = kind ? `/search?q=${encodeURIComponent(kind.q)}&brand=${brandId}&model=${encodeURIComponent(model)}` : '/search';

  return (
    <>
      <h1>See inside the {carName}</h1>
      <div className="card row">
        <span className="muted small">My car:</span>
        <select value={brandId} onChange={(e) => { setBrandId(e.target.value); setModel(''); }}>
          {BRANDS.filter((b) => b.type === 'car').map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
        </select>
        <select value={model} onChange={(e) => setModel(e.target.value)}>
          <option value="">Any model</option>
          {(brand ? brand.models : []).map((m) => <option key={m}>{m}</option>)}
        </select>
        <div className="grow" />
        <div className="seg" role="tablist" aria-label="Style">
          <button role="tab" aria-selected={is3d} className={is3d ? 'on' : ''} onClick={() => changeMode('3d')}>3D</button>
          <button role="tab" aria-selected={!is3d} className={!is3d ? 'on' : ''} onClick={() => changeMode('2d')}>2D</button>
        </div>
        {is3d ? (
          <div className="seg" role="tablist" aria-label="Camera">
            {[['angle', 'Angle'], ['side', 'Side'], ['front', 'Front'], ['top', 'Top']].map(([k, l]) => (
              <button key={k} role="tab" aria-selected={angle === k} className={angle === k ? 'on' : ''} onClick={() => changeAngle(k)}>{l}</button>
            ))}
          </div>
        ) : (
          <div className="seg" role="tablist" aria-label="View">
            <button role="tab" aria-selected={viewId === 'side'} className={viewId === 'side' ? 'on' : ''} onClick={() => changeView('side')}>Side</button>
            <button role="tab" aria-selected={viewId === 'front'} className={viewId === 'front' ? 'on' : ''} onClick={() => changeView('front')}>Front</button>
          </div>
        )}
      </div>

      <div className="explorer">
        <div>
          <div className="card xstage">
            <div className="xhint" aria-live="polite">
              {hover ? labelOf(hover) : selected ? labelOf(selected) : is3d ? 'Drag to turn the car, scroll to zoom, click a part' : 'Hover a part, then click it to zoom in'}
            </div>
            {(is3d ? !!selected : cam.zoomed) && <button className="btn ghost small xreset" onClick={clear}>Show whole car</button>}
            {is3d ? (
              <Suspense fallback={<div className="x3d xloading">Loading the 3D car...</div>}>
                <Car3D ref={carRef} selected={selected} hover={hover} onHover={setHover} onPick={pick} />
              </Suspense>
            ) : (
            <svg
              ref={svgRef}
              className={`xr${selected ? ' has-sel' : ''}`}
              viewBox={cam.box.map((n) => n.toFixed(1)).join(' ')}
              role="group"
              aria-label={`Cutaway of the ${carName}, ${viewId} view`}
              onClick={(e) => {
                if (e.target === e.currentTarget || e.target.classList.contains('body') || e.target.classList.contains('glass') || e.target.classList.contains('seam')) clear();
              }}
            >
              {view.body}
              {view.parts.map((p) => (
                <g
                  key={`${viewId}-${p.id}`}
                  data-part={p.id}
                  className={`part${hover === p.id ? ' hot' : ''}${selected === p.id ? ' on' : ''}${selected && selected !== p.id ? ' dim' : ''}`}
                  tabIndex={0}
                  role="button"
                  aria-label={`${p.name}. Open details`}
                  onMouseEnter={() => setHover(p.id)}
                  onMouseLeave={() => setHover(null)}
                  onFocus={() => setHover(p.id)}
                  onBlur={() => setHover(null)}
                  onClick={(e) => {
                    e.stopPropagation();
                    pick(p.id);
                  }}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      e.preventDefault();
                      pick(p.id);
                    }
                  }}
                >
                  {p.hit && <rect className="hit" x={p.hit[0]} y={p.hit[1]} width={p.hit[2]} height={p.hit[3]} />}
                  {p.shape}
                </g>
              ))}
            </svg>
            )}
          </div>
          <div className="xchips">
            {chips.map((p) => (
              <button key={p.id} className={`btn small ${chosen && chosen.kind === p.kind ? 'orange' : 'ghost'}`} onClick={() => pick(p.id)}>
                {KINDS[p.kind].label}
              </button>
            ))}
          </div>
          <p className="muted small">The car is a generic hatchback cutaway. Part names, prices and reports are for the car you choose above.</p>
        </div>

        <aside className="card xcard">
          {!chosen ? (
            <div className="stack">
              <h2 style={{ margin: 0 }}>Pick a part</h2>
              <p className="muted">The body is grey and the parts inside are shown in teal. Click any part, or use the buttons under the car. The view zooms in and this card shows how the part works, what mechanics wrote about it and what it costs.</p>
            </div>
          ) : (
            <div className="stack" key={chosen.id}>
              <div className="row between">
                <h2 style={{ margin: 0 }}>{chosen.name}</h2>
                <button className="btn ghost small" onClick={clear}>Close</button>
              </div>
              <section>
                <h3>How it works</h3>
                <p style={{ margin: 0 }}>{kind.how}</p>
                {note && <p className="note">{note}</p>}
              </section>
              <section>
                <h3>Signs it is failing</h3>
                <p style={{ margin: 0 }}>{kind.signs}</p>
                <p className="muted small" style={{ margin: '6px 0 0' }}>{kind.life}</p>
              </section>
              <section>
                <h3>Prices for the {carName}</h3>
                <Prices kind={kind} brand={brand} model={model} fitments={fitments} />
              </section>
              <section>
                <h3>Mechanic reports</h3>
                <ReportsList kind={kind} />
              </section>
              <Link className="btn orange" to={searchLink}>Find {kind.label.toLowerCase()} in shops</Link>
            </div>
          )}
        </aside>
      </div>
    </>
  );
}
