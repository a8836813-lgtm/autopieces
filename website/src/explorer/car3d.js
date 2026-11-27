import * as THREE from 'three';
import { PARTS_3D } from './parts3d';

const X = (x) => (x - 547) / 100;
const Y = (y) => (392 - y) / 100;

export const TEAL = '#0f4c5c';
export const ORANGE = '#c2410c';
const DARK = '#3d4450';


function shellShape() {
  const s = new THREE.Shape();
  s.moveTo(X(60), Y(330));
  s.lineTo(X(60), Y(252));
  s.quadraticCurveTo(X(62), Y(224), X(95), Y(216));
  s.lineTo(X(205), Y(198));
  s.lineTo(X(380), Y(178));
  s.lineTo(X(500), Y(96));
  s.quadraticCurveTo(X(510), Y(88), X(528), Y(88));
  s.lineTo(X(780), Y(88));
  s.quadraticCurveTo(X(820), Y(90), X(848), Y(126));
  s.lineTo(X(975), Y(204));
  s.quadraticCurveTo(X(1020), Y(218), X(1030), Y(246));
  s.lineTo(X(1034), Y(330));
  s.lineTo(X(926), Y(330));
  s.absarc(X(850), Y(330), 0.76, 0, Math.PI, false);
  s.lineTo(X(326), Y(330));
  s.absarc(X(250), Y(330), 0.76, 0, Math.PI, false);
  s.lineTo(X(60), Y(330));
  return s;
}

export function helix(radius, height, turns) {
  class Helix extends THREE.Curve {
    getPoint(t, target = new THREE.Vector3()) {
      const a = t * turns * Math.PI * 2;
      return target.set(Math.cos(a) * radius, t * height, Math.sin(a) * radius);
    }
  }
  return new Helix();
}

export function createCar() {
  const root = new THREE.Group();
  const parts = {};
  const pickables = [];

  const shell = new THREE.Mesh(
    new THREE.ExtrudeGeometry(shellShape(), {
      depth: 1.7,
      bevelEnabled: true,
      bevelSize: 0.1,
      bevelThickness: 0.1,
      bevelSegments: 4,
      curveSegments: 20,
    }),
    new THREE.MeshPhysicalMaterial({ color: '#c9c7c0', transparent: true, opacity: 0.26, roughness: 0.6, depthWrite: false }),
  );
  shell.geometry.translate(0, 0, -0.85);
  shell.renderOrder = 2;
  root.add(shell);
  const edges = new THREE.LineSegments(new THREE.EdgesGeometry(shell.geometry, 25), new THREE.LineBasicMaterial({ color: '#8b8a84' }));
  edges.renderOrder = 3;
  root.add(edges);

  function part(id, build, opts = {}) {
    const meta = PARTS_3D.find((p) => p.id === id);
    const group = new THREE.Group();
    const base = opts.color || TEAL;
    const baseOpacity = opts.opacity ?? 1;
    const material = new THREE.MeshStandardMaterial({
      color: base,
      roughness: 0.45,
      metalness: 0.25,
      transparent: baseOpacity < 1,
      opacity: baseOpacity,
    });
    group.userData = { partId: id, kind: meta.kind, name: meta.name, material, base, baseOpacity };
    build(group, material);
    group.traverse((o) => {
      if (o.isMesh) {
        o.userData.partId = id;
        pickables.push(o);
      }
    });
    root.add(group);
    parts[id] = group;
    return group;
  }

  const mesh = (geo, mat, x = 0, y = 0, z = 0) => {
    const m = new THREE.Mesh(geo, mat);
    m.position.set(x, y, z);
    return m;
  };
  const box = (w, h, d) => new THREE.BoxGeometry(w, h, d);

  part('engine', (g, m) => {
    g.add(mesh(box(1.6, 0.3, 1.0), m, X(238), Y(236), 0));
    g.add(mesh(box(1.5, 0.12, 0.9), m, X(238), Y(236) + 0.21, 0));
    for (let i = 0; i < 5; i += 1) {
      const c = mesh(new THREE.CylinderGeometry(0.085, 0.085, 1.04, 20), m, X(184 + i * 28), Y(236), 0);
      c.rotation.x = Math.PI / 2;
      g.add(c);
    }
  });
  part('radiator', (g, m) => {
    g.add(mesh(box(0.16, 0.7, 1.3), m, X(88), Y(267), 0));
    for (let i = 0; i < 6; i += 1) g.add(mesh(box(0.2, 0.02, 1.34), m, X(88), Y(267) - 0.27 + i * 0.11, 0));
  });
  part('battery', (g, m) => g.add(mesh(box(0.42, 0.26, 0.28), m, X(131), Y(236), 0.5)));
  part('airfilter', (g, m) => g.add(mesh(box(0.5, 0.36, 0.42), m, X(365), Y(214), -0.4)));
  part('alternator', (g, m) => {
    const c = mesh(new THREE.CylinderGeometry(0.13, 0.13, 0.3, 24), m, X(300), Y(262), 0.35);
    c.rotation.x = Math.PI / 2;
    g.add(c);
  });
  part('gearbox', (g, m) => g.add(mesh(box(0.92, 0.66, 0.8), m, X(379), Y(295), 0)));
  part('exhaust', (g, m) => {
    const curve = new THREE.CatmullRomCurve3([
      new THREE.Vector3(X(424), Y(312), 0.28),
      new THREE.Vector3(X(470), Y(345), 0.28),
      new THREE.Vector3(X(540), Y(352), 0.28),
      new THREE.Vector3(X(900), Y(352), 0.28),
    ]);
    g.add(mesh(new THREE.TubeGeometry(curve, 48, 0.06, 12), m));
    const muffler = mesh(new THREE.CylinderGeometry(0.17, 0.17, 0.78, 24), m, X(978), Y(343), 0.28);
    muffler.rotation.z = Math.PI / 2;
    g.add(muffler);
  });
  part('fuel', (g, m) => g.add(mesh(box(1.2, 0.48, 1.0), m, X(700), Y(294), 0)));

  [['f', 250], ['r', 850]].forEach(([k, x]) => {
    part(`tyres-${k}`, (g, m) => {
      [-0.78, 0.78].forEach((z) => g.add(mesh(new THREE.TorusGeometry(0.45, 0.17, 18, 40), m, X(x), Y(330), z)));
    }, { color: DARK });
    part(`brakes-${k}`, (g, m) => {
      [-0.62, 0.62].forEach((z) => {
        const disc = mesh(new THREE.CylinderGeometry(0.31, 0.31, 0.05, 40), m, X(x), Y(330), z);
        disc.rotation.x = Math.PI / 2;
        g.add(disc);
        g.add(mesh(box(0.16, 0.26, 0.14), m, X(x) + 0.22, Y(330) + 0.12, z + (z > 0 ? 0.08 : -0.08)));
      });
    });
  });

  [['f', 300, 0.62], ['r', 800, 0.62]].forEach(([k, x, y0]) => {
    part(`susp-${k}`, (g, m) => {
      [-0.55, 0.55].forEach((z) => {
        const s = mesh(new THREE.TubeGeometry(helix(0.1, 0.62, 6), 120, 0.022, 8), m, X(x), y0, z);
        g.add(s);
        g.add(mesh(new THREE.CylinderGeometry(0.03, 0.03, 0.9, 10), m, X(x), y0 + 0.4, z));
      });
    });
  });

  part('headlight', (g, m) => [-0.56, 0.56].forEach((z) => g.add(mesh(box(0.26, 0.2, 0.42), m, X(80), Y(238), z))));
  part('fog', (g, m) => [-0.62, 0.62].forEach((z) => g.add(mesh(new THREE.SphereGeometry(0.085, 18, 14), m, X(66), Y(290), z))));
  part('taillight', (g, m) => [-0.6, 0.6].forEach((z) => g.add(mesh(box(0.1, 0.28, 0.42), m, X(1022), Y(248), z))));
  part('bumper-f', (g, m) => g.add(mesh(box(0.16, 0.3, 1.74), m, X(56), Y(306), 0)));
  part('bumper-r', (g, m) => g.add(mesh(box(0.16, 0.3, 1.74), m, X(1038), Y(306), 0)));
  part('mirror', (g, m) => [-1.0, 1.0].forEach((z) => g.add(mesh(box(0.2, 0.15, 0.14), m, X(395), Y(191), z))));

  const dx = X(505) - X(392);
  const dy = Y(104) - Y(182);
  part('windscreen', (g, m) => {
    const w = mesh(box(Math.hypot(dx, dy), 0.03, 1.55), m, (X(392) + X(505)) / 2, (Y(182) + Y(104)) / 2, 0);
    w.rotation.z = Math.atan2(dy, dx);
    g.add(w);
  }, { opacity: 0.35 });
  part('wipers', (g, m) => {
    [-0.35, 0.35].forEach((z) => {
      const w = mesh(box(0.8, 0.02, 0.025), m, (X(392) + X(505)) / 2 - 0.05, (Y(182) + Y(104)) / 2 + 0.045, z);
      w.rotation.z = Math.atan2(dy, dx);
      w.rotation.y = z > 0 ? 0.15 : -0.15;
      g.add(w);
    });
  }, { color: DARK });
  part('door', (g, m) => [-0.93, 0.93].forEach((z) => g.add(mesh(box(1.92, 1.34, 0.03), m, X(496), Y(257), z))), { opacity: 0.16 });
  part('hood', (g, m) => {
    const hx = X(380) - X(95);
    const hy = Y(178) - Y(216);
    const h = mesh(box(Math.hypot(hx, hy), 0.03, 1.5), m, (X(95) + X(380)) / 2, (Y(216) + Y(178)) / 2 + 0.03, 0);
    h.rotation.z = Math.atan2(hy, hx);
    g.add(h);
  }, { opacity: 0.16 });

  const OUTER = new Set(['door', 'hood', 'windscreen', 'bumper-f', 'bumper-r']);
  const DIRS = {
    engine: [0, 1.4, 0], radiator: [-1.4, 0.4, 0], battery: [-0.4, 1.4, 0.8], airfilter: [-0.2, 1.4, -0.8], alternator: [0, -0.8, 0.9], gearbox: [0, 0.9, 0],
    exhaust: [0, -1, 0], fuel: [0, -1, 0], 'brakes-f': [0, 0, 1.1], 'brakes-r': [0, 0, 1.1], 'tyres-f': [0, 0, 1.5], 'tyres-r': [0, 0, 1.5],
    'susp-f': [0, 1.2, 0], 'susp-r': [0, 1.2, 0], headlight: [-1, 0.5, 0], taillight: [1, 0.5, 0], fog: [-1, -0.3, 0], 'bumper-f': [-1.5, 0, 0], 'bumper-r': [1.5, 0, 0],
    mirror: [0, 0.6, 0.8], windscreen: [0, 1.6, 0], wipers: [0, 1.8, 0], door: [0, 0, 1.6], hood: [0, 1.5, 0],
  };
  const out = {};
  const pickable = [];
  Object.entries(parts).forEach(([id, g]) => {
    const meshes = [];
    g.traverse((o) => o.isMesh && meshes.push(o));
    const { material, base, baseOpacity } = g.userData;
    const dir = new THREE.Vector3(...(DIRS[id] || [0, 1, 0]));
    out[id] = {
      id,
      kind: g.userData.kind,
      name: g.userData.name,
      meshes,
      holders: [{ obj: g, dir }],
      apply(state) {
        const hot = state === 'hot';
        material.color.set(hot ? ORANGE : base);
        material.emissive.set(hot ? ORANGE : '#000000');
        material.emissiveIntensity = hot ? 0.25 : 0;
        material.opacity = state === 'dim' ? Math.min(baseOpacity, 0.22) : hot ? Math.max(baseOpacity, 0.55) : baseOpacity;
        material.transparent = material.opacity < 1;
        material.needsUpdate = true;
      },
    };
    meshes.forEach((m) => {
      m.userData.layer = OUTER.has(id) ? 'outer' : 'inner';
      pickable.push(m);
    });
  });

  const explodeT = { v: 0 };
  return {
    root,
    parts: out,
    pickables: pickable,
    meta: PARTS_3D,
    caps: { explode: true, doors: false, spin: false },
    framing: {
      target: new THREE.Vector3(0, 1.3, 0),
      presets: {
        angle: new THREE.Vector3(-5.4, 3.3, 7.0),
        side: new THREE.Vector3(0, 1.6, 10.2),
        front: new THREE.Vector3(-10.2, 1.6, 0.01),
        top: new THREE.Vector3(0, 11.5, 0.01),
        explode: new THREE.Vector3(-8, 5.5, 11),
      },
      grid: 24,
      minDistance: 1.2,
      maxDistance: 22,
      focusMin: 2.2,
      focusMax: 11,
      explodeScale: 1,
    },
    setShell(v) {
      shell.material.opacity = v;
      edges.material.transparent = true;
      edges.material.opacity = v > 0.2 ? 1 : 0.25;
    },
    anim: { explode: false },
    update(dt) {
      const target = this.anim.explode ? 1 : 0;
      explodeT.v += (target - explodeT.v) * Math.min(1, dt * 4);
      Object.values(out).forEach((pt) => pt.holders.forEach((h) => h.obj.position.copy(h.dir).multiplyScalar(explodeT.v)));
      return explodeT.v;
    },
  };
}
