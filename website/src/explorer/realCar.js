import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { ORANGE, TEAL, helix } from './car3d';

const GHOST = '#c9c7c0';
const GLASS = '#a9c0c8';
const DARK = '#3d4450';

export const PARTS_REAL = [
  { id: 'engine', kind: 'engine', name: 'Engine' },
  { id: 'radiator', kind: 'radiator', name: 'Radiator' },
  { id: 'battery', kind: 'battery', name: 'Battery' },
  { id: 'airfilter', kind: 'airfilter', name: 'Air filter' },
  { id: 'alternator', kind: 'alternator', name: 'Alternator' },
  { id: 'gearbox', kind: 'gearbox', name: 'Gearbox' },
  { id: 'exhaust', kind: 'exhaust', name: 'Exhaust' },
  { id: 'fuel', kind: 'fuel', name: 'Fuel tank' },
  { id: 'susp-f', kind: 'suspension', name: 'Front suspension' },
  { id: 'susp-r', kind: 'suspension', name: 'Rear suspension' },
  { id: 'brakes-f', kind: 'brakes', name: 'Front brakes' },
  { id: 'brakes-r', kind: 'brakes', name: 'Rear brakes' },
  { id: 'tyres-f', kind: 'tyres', name: 'Front wheels' },
  { id: 'tyres-r', kind: 'tyres', name: 'Rear wheels' },
  { id: 'headlight', kind: 'headlight', name: 'Headlights' },
  { id: 'taillight', kind: 'taillight', name: 'Tail lights' },
  { id: 'grille', kind: 'grille', name: 'Grille' },
  { id: 'bumper-f', kind: 'bumper', name: 'Front bumper' },
  { id: 'door', kind: 'door', name: 'Doors' },
  { id: 'hood', kind: 'hood', name: 'Bonnet' },
  { id: 'glass', kind: 'windscreen', name: 'Windows' },
];

const DIRS = {
  engine: [0, 1.3, 0.4], radiator: [0, 0.2, 1.3], battery: [-0.8, 1.2, 0.5], airfilter: [0.7, 1.2, 0.3], alternator: [0, -0.6, 0.8], gearbox: [0.9, 0.5, 0],
  exhaust: [0, -0.8, -0.4], fuel: [0, -0.8, 0], headlight: [0, 0.5, 1.3], taillight: [0, 0.5, -1.3], grille: [0, 0, 1.8], 'bumper-f': [0, -0.2, 1.5],
  hood: [0, 1.5, 0.3], glass: [0, 1.7, 0],
};

function ghostMaterial(color, opacity) {
  return new THREE.MeshPhysicalMaterial({ color, transparent: true, opacity, roughness: 0.5, metalness: 0, depthWrite: false, side: THREE.FrontSide });
}

function box(w, h, d) {
  return new THREE.BoxGeometry(w, h, d);
}

export async function loadRealCar(url) {
  const gltf = await new GLTFLoader().loadAsync(url);
  const model = gltf.scene;
  model.scale.setScalar(100);
  model.updateMatrixWorld(true);

  const root = new THREE.Group();
  root.add(model);
  const shellMat = ghostMaterial(GHOST, 0.16);
  const parts = {};
  const pickables = [];
  const spinPivots = [];
  const doorPivots = [];

  const meta = Object.fromEntries(PARTS_REAL.map((p) => [p.id, p]));
  function part(id) {
    if (!parts[id]) {
      parts[id] = { id, kind: meta[id].kind, name: meta[id].name, meshes: [], holders: [], apply() {} };
    }
    return parts[id];
  }
  function holderFor(pt, key, dir) {
    let h = pt.holders.find((x) => x.key === key);
    if (!h) {
      h = { key, obj: new THREE.Group(), dir: new THREE.Vector3(...dir) };
      root.add(h.obj);
      pt.holders.push(h);
    }
    return h;
  }

  const items = [];
  model.traverse((o) => {
    if (!o.isMesh) return;
    const chain = [];
    for (let a = o; a; a = a.parent) chain.push(a.name);
    items.push({ mesh: o, chain: chain.join('/'), mat: (o.material.name || '').replace('ARMAT_', '') });
  });

  const wheelBox = {};
  model.traverse((o) => {
    const m = /^3DWheel_(Front|Rear)_(L|R)$/.exec(o.name);
    if (m) wheelBox[`${m[1][0].toLowerCase()}${m[2]}`] = new THREE.Box3().setFromObject(o);
  });

  const plans = [];
  items.forEach((it) => {
    const { mesh, chain, mat } = it;
    const w = /3DWheel_(Front|Rear)_(L|R)/.exec(chain);
    if (w) {
      const axle = w[1][0].toLowerCase();
      const side = w[2];
      const caliper = mat.includes('Brake');
      const disc = mat.includes('Disk');
      plans.push({ mesh, kind: 'wheel', id: disc || caliper ? `brakes-${axle}` : `tyres-${axle}`, axle, side, spin: !caliper });
      return;
    }
    if (/ANC_Door_(L|R)/.test(chain)) {
      plans.push({ mesh, kind: 'ghost', id: 'door', side: /ANC_Door_L/.test(chain) ? 'L' : 'R', color: GHOST, opacity: 0.2 });
      return;
    }
    if (/SM_Hood/.test(chain)) {
      plans.push({ mesh, kind: 'ghost', id: 'hood', color: GHOST, opacity: 0.2 });
      return;
    }
    if (/ANC_Glass/.test(chain) || (/SM_RearKit/.test(chain) && mat === 'Glass1')) {
      plans.push({ mesh, kind: 'ghost', id: 'glass', color: GLASS, opacity: 0.24 });
      return;
    }
    if (/SM_FrontKit/.test(chain)) {
      if (mat === 'Glass1' || mat === 'Lights1') plans.push({ mesh, kind: 'real', id: 'headlight' });
      else if (mat.includes('Grid')) plans.push({ mesh, kind: 'ghost', id: 'grille', color: GHOST, opacity: 0.22 });
      else plans.push({ mesh, kind: 'ghost', id: 'bumper-f', color: GHOST, opacity: 0.2 });
      return;
    }
    if (/SM_RearKit/.test(chain) && mat === 'Lights1') {
      plans.push({ mesh, kind: 'real', id: 'taillight' });
      return;
    }
    plans.push({ mesh, kind: 'shell' });
  });

  function prepare(mesh, id, layer) {
    mesh.userData.partId = id;
    mesh.userData.layer = layer;
    pickables.push(mesh);
  }

  plans.forEach((pl) => {
    const { mesh } = pl;
    mesh.frustumCulled = false;
    if (pl.kind === 'shell') {
      mesh.material = shellMat;
      mesh.renderOrder = 2;
      return;
    }
    const pt = part(pl.id);
    pt.meshes.push(mesh);
    if (pl.kind === 'ghost') {
      mesh.material = ghostMaterial(pl.color, pl.opacity);
      mesh.userData.orig = { ghost: true, color: pl.color, opacity: pl.opacity };
      mesh.renderOrder = 2;
      prepare(mesh, pl.id, 'outer');
      if (pl.id === 'door') {
        const side = pl.side;
        const h = holderFor(pt, `door${side}`, [side === 'L' ? 1.5 : -1.5, 0, 0]);
        let pivot = h.pivot;
        if (!pivot) {
          pivot = new THREE.Group();
          pivot.position.set(side === 'L' ? 0.95 : -0.95, 0.8, 0.89);
          h.obj.add(pivot);
          h.pivot = pivot;
          doorPivots.push({ pivot, sign: side === 'L' ? -1 : 1 });
        }
        pivot.attach(mesh);
      } else {
        const h = holderFor(pt, pl.id, DIRS[pl.id] || [0, 1, 0]);
        h.obj.attach(mesh);
      }
      return;
    }
    const m = mesh.material.clone();
    mesh.material = m;
    mesh.userData.orig = { ghost: false, emissive: m.emissive ? m.emissive.clone() : new THREE.Color(0), ei: m.emissiveIntensity ?? 1, opacity: m.opacity, transparent: m.transparent, depthWrite: m.depthWrite };
    prepare(mesh, pl.id, 'inner');
    if (pl.kind === 'wheel') {
      const key = `${pl.axle}${pl.side}`;
      const h = holderFor(pt, key, [pl.side === 'L' ? 1.1 : -1.1, 0, 0]);
      if (pl.spin) {
        if (!h.spin) {
          const c = wheelBox[key].getCenter(new THREE.Vector3());
          h.spin = new THREE.Group();
          h.spin.position.copy(c);
          h.obj.add(h.spin);
          spinPivots.push(h.spin);
        }
        h.spin.attach(mesh);
      } else {
        h.obj.attach(mesh);
      }
    } else {
      const h = holderFor(pt, pl.id, DIRS[pl.id] || [0, 1, 0]);
      h.obj.attach(mesh);
    }
  });

  Object.values(parts).forEach((pt) => {
    pt.apply = (state) => {
      pt.meshes.forEach((mesh) => {
        const m = mesh.material;
        const o = mesh.userData.orig;
        if (!o) return;
        if (o.ghost) {
          m.color.set(state === 'hot' ? ORANGE : o.color);
          m.opacity = state === 'hot' ? 0.6 : state === 'dim' ? 0.05 : o.opacity;
        } else {
          m.emissive.set(state === 'hot' ? ORANGE : o.emissive);
          m.emissiveIntensity = state === 'hot' ? 0.8 : o.ei;
          const t = state === 'dim' || o.transparent;
          if (m.transparent !== t) m.needsUpdate = true;
          m.transparent = t;
          m.opacity = state === 'dim' ? 0.2 : o.opacity;
          m.depthWrite = state === 'dim' ? false : o.depthWrite;
        }
      });
    };
  });

  const FZ = 1.36;
  const RZ = -1.275;
  const WY = 0.3;

  const innerMats = [];
  function inner(id, dir, build, opts = {}) {
    const g = new THREE.Group();
    const base = opts.color || TEAL;
    const material = new THREE.MeshStandardMaterial({ color: base, roughness: 0.45, metalness: 0.3 });
    innerMats.push(material);
    build(g, material);
    const pt = part(id);
    g.traverse((o) => {
      if (o.isMesh) {
        pt.meshes.push(o);
        prepare(o, id, 'inner');
      }
    });
    root.add(g);
    pt.holders.push({ key: id, obj: g, dir: new THREE.Vector3(...dir) });
    pt.apply = (state) => {
      const hot = state === 'hot';
      material.color.set(hot ? ORANGE : base);
      material.emissive.set(hot ? ORANGE : '#000000');
      material.emissiveIntensity = hot ? 0.3 : 0;
      material.transparent = state === 'dim';
      material.opacity = state === 'dim' ? 0.2 : 1;
      material.needsUpdate = true;
    };
  }
  const mesh = (geo, mat, x = 0, y = 0, z = 0) => {
    const m = new THREE.Mesh(geo, mat);
    m.position.set(x, y, z);
    return m;
  };

  inner('engine', DIRS.engine, (g, m) => {
    g.add(mesh(box(0.66, 0.1, 0.3), m, -0.08, 0.8, 1.5));
    for (let i = 0; i < 5; i += 1) g.add(mesh(new THREE.CylinderGeometry(0.052, 0.052, 0.36, 20), m, -0.08 + (i - 2) * 0.125, 0.6, 1.5));
    g.add(mesh(box(0.66, 0.08, 0.34), m, -0.08, 0.38, 1.5));
  });
  inner('radiator', DIRS.radiator, (g, m) => {
    g.add(mesh(box(0.9, 0.34, 0.03), m, 0, 0.46, 1.95));
    for (let i = 0; i < 4; i += 1) g.add(mesh(box(0.92, 0.012, 0.05), m, 0, 0.35 + i * 0.07, 1.95));
  });
  inner('battery', DIRS.battery, (g, m) => g.add(mesh(box(0.3, 0.2, 0.18), m, -0.56, 0.72, 1.74)));
  inner('airfilter', DIRS.airfilter, (g, m) => g.add(mesh(box(0.3, 0.18, 0.34), m, 0.5, 0.74, 1.72)));
  inner('alternator', DIRS.alternator, (g, m) => {
    const c = mesh(new THREE.CylinderGeometry(0.07, 0.07, 0.16, 24), m, 0.2, 0.36, 1.72);
    c.rotation.z = Math.PI / 2;
    g.add(c);
  });
  inner('gearbox', DIRS.gearbox, (g, m) => g.add(mesh(box(0.36, 0.4, 0.46), m, 0.56, 0.48, 1.45)));
  inner('exhaust', DIRS.exhaust, (g, m) => {
    const curve = new THREE.CatmullRomCurve3([
      new THREE.Vector3(0.12, 0.34, 1.2),
      new THREE.Vector3(0.12, 0.2, 0.6),
      new THREE.Vector3(0.12, 0.17, -0.8),
      new THREE.Vector3(0.12, 0.2, -1.8),
    ]);
    g.add(mesh(new THREE.TubeGeometry(curve, 48, 0.035, 12), m));
    const muffler = mesh(new THREE.CylinderGeometry(0.1, 0.1, 0.55, 24), m, 0.12, 0.22, -1.75);
    muffler.rotation.x = Math.PI / 2;
    g.add(muffler);
  });
  inner('fuel', DIRS.fuel, (g, m) => g.add(mesh(box(0.78, 0.22, 0.5), m, 0, 0.27, -0.85)));
  [['f', FZ], ['r', RZ]].forEach(([k, z]) => {
    inner(`susp-${k}`, [0, 1.0, 0], (g, m) => {
      [-0.5, 0.5].forEach((x) => {
        g.add(mesh(new THREE.TubeGeometry(helix(0.05, 0.38, 6), 100, 0.012, 8), m, x, 0.4, z));
        g.add(mesh(new THREE.CylinderGeometry(0.016, 0.016, 0.5, 10), m, x, 0.62, z));
      });
    });
  });

  pickables.forEach((m) => {
    if (m.userData.layer == null) m.userData.layer = 'inner';
  });

  const state = { explode: 0, doors: 0, tx: 0, td: 0, spin: false };
  const anim = { explode: false, doors: false, spin: false };

  return {
    root,
    parts,
    pickables,
    meta: PARTS_REAL,
    caps: { explode: true, doors: doorPivots.length > 0, spin: spinPivots.length > 0 },
    framing: {
      target: new THREE.Vector3(0, 0.62, 0.05),
      presets: {
        angle: new THREE.Vector3(3.3, 1.7, 4.5),
        side: new THREE.Vector3(5.6, 0.8, 0),
        front: new THREE.Vector3(0, 0.9, 6.0),
        top: new THREE.Vector3(0, 7.0, 0.01),
        explode: new THREE.Vector3(5.6, 3.2, 7.4),
      },
      grid: 12,
      minDistance: 0.9,
      maxDistance: 14,
      focusMin: 1.5,
      focusMax: 7,
    },
    setShell(v) {
      shellMat.opacity = v;
    },
    anim,
    update(dt) {
      state.explode += ((anim.explode ? 1 : 0) - state.explode) * Math.min(1, dt * 4);
      state.doors += ((anim.doors ? 1 : 0) - state.doors) * Math.min(1, dt * 3);
      Object.values(parts).forEach((pt) => pt.holders.forEach((h) => h.obj.position.copy(h.dir).multiplyScalar(state.explode * 0.7)));
      doorPivots.forEach((d) => {
        d.pivot.rotation.y = d.sign * (Math.PI / 3) * state.doors;
      });
      if (anim.spin) spinPivots.forEach((w) => { w.rotation.x += dt * 4; });
      return state.explode;
    },
  };
}
