import { forwardRef, useEffect, useImperativeHandle, useRef, useState } from 'react';
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { createCar } from './carScene.js';
import { loadRealCar } from './realCar.js';

const ease = (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);

const Car3D = forwardRef(function Car3D({ modelUrl, selected, hover, onHover, onPick, onReady }, ref) {
  const host = useRef(null);
  const [ready, setReady] = useState(0);
  const state = useRef({});
  const cb = useRef({ onHover, onPick, onReady });
  cb.current = { onHover, onPick, onReady };

  useEffect(() => {
    const el = host.current;
    let disposed = false;
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(34, 2, 0.05, 100);
    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    el.appendChild(renderer.domElement);
    const cv = renderer.domElement;
    cv.style.display = 'block';
    cv.style.width = '100%';
    cv.style.height = '100%';
    cv.style.cursor = 'grab';
    cv.style.touchAction = 'none';

    scene.add(new THREE.HemisphereLight('#ffffff', '#cfcdc6', 1.6));
    const sun = new THREE.DirectionalLight('#ffffff', 1.7);
    sun.position.set(-4, 9, 6);
    scene.add(sun);
    const fill = new THREE.DirectionalLight('#ffffff', 0.7);
    fill.position.set(6, 3, -6);
    scene.add(fill);

    const controls = new OrbitControls(camera, cv);
    controls.enableDamping = true;
    controls.maxPolarAngle = Math.PI * 0.55;

    const ray = new THREE.Raycaster();
    const ndc = new THREE.Vector2();
    let car = null;
    let grid = null;
    let anim = null;
    let raf = 0;
    let down = null;
    let hovered = null;
    let last = performance.now();

    function resize() {
      const w = el.clientWidth || 600;
      const h = el.clientHeight || 300;
      renderer.setSize(w, h, false);
      camera.aspect = w / h;
      camera.updateProjectionMatrix();
    }
    const ro = new ResizeObserver(resize);
    ro.observe(el);
    resize();

    function fly(pos, target) {
      const reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      if (reduce) {
        camera.position.copy(pos);
        controls.target.copy(target);
        controls.update();
        return;
      }
      anim = { t0: performance.now(), p0: camera.position.clone(), t0v: controls.target.clone(), p1: pos.clone(), t1v: target.clone() };
    }

    function pick(e) {
      if (!car) return null;
      const r = cv.getBoundingClientRect();
      ndc.set(((e.clientX - r.left) / r.width) * 2 - 1, -((e.clientY - r.top) / r.height) * 2 + 1);
      ray.setFromCamera(ndc, camera);
      const inner = car.pickables.filter((m) => m.userData.layer === 'inner');
      const outer = car.pickables.filter((m) => m.userData.layer === 'outer');
      const hit = ray.intersectObjects(inner, false)[0] || ray.intersectObjects(outer, false)[0];
      return hit ? hit.object.userData.partId : null;
    }

    const onMove = (e) => {
      if (e.buttons) return;
      const id = pick(e);
      if (id !== hovered) {
        hovered = id;
        cv.style.cursor = id ? 'pointer' : 'grab';
        cb.current.onHover(id);
      }
    };
    const onDown = (e) => {
      down = { x: e.clientX, y: e.clientY };
    };
    const onUp = (e) => {
      if (!down) return;
      const moved = Math.hypot(e.clientX - down.x, e.clientY - down.y);
      down = null;
      if (moved < 5) cb.current.onPick(pick(e));
    };
    const onLeave = () => {
      if (hovered) {
        hovered = null;
        cb.current.onHover(null);
      }
    };
    cv.addEventListener('pointermove', onMove);
    cv.addEventListener('pointerdown', onDown);
    cv.addEventListener('pointerup', onUp);
    cv.addEventListener('pointerleave', onLeave);

    function loop(now) {
      raf = requestAnimationFrame(loop);
      const dt = Math.min(0.05, (now - last) / 1000);
      last = now;
      if (anim) {
        const k = Math.min(1, (now - anim.t0) / 750);
        const e = ease(k);
        camera.position.lerpVectors(anim.p0, anim.p1, e);
        controls.target.lerpVectors(anim.t0v, anim.t1v, e);
        if (k >= 1) anim = null;
      }
      if (car) {
        const ex = car.update(dt);
        state.current.explodeT = ex;
        car.setShell(Math.max(0.03, state.current.shellBase * (1 - 0.75 * ex)));
      }
      controls.update();
      renderer.render(scene, camera);
    }
    raf = requestAnimationFrame(loop);

    (async () => {
      let built;
      let usedReal = false;
      if (modelUrl) {
        try {
          built = await loadRealCar(modelUrl);
          usedReal = true;
        } catch (err) {
          built = null;
        }
      }
      if (!built) built = createCar();
      if (disposed) return;
      car = built;
      scene.add(car.root);
      const f = car.framing;
      grid = new THREE.GridHelper(f.grid, f.grid, '#cfcdc6', '#e3e1db');
      scene.add(grid);
      controls.minDistance = f.minDistance;
      controls.maxDistance = f.maxDistance;
      controls.target.copy(f.target);
      camera.position.copy(f.presets.angle);
      controls.update();
      state.current.shellBase = 0.26;
      car.setShell(0.26);
      state.current.car = car;
      setReady((n) => n + 1);
      cb.current.onReady({ meta: car.meta, caps: car.caps, real: usedReal });
    })();

    state.current = {
      shellBase: 0.26,
      canvas: cv,
      fly,
      camera,
      controls,
      focus(id) {
        const c = state.current.car;
        const pt = c && c.parts[id];
        if (!pt) return;
        const box = new THREE.Box3();
        pt.meshes.forEach((m) => box.expandByObject(m));
        if (box.isEmpty()) return;
        const ctr = box.getCenter(new THREE.Vector3());
        const size = box.getSize(new THREE.Vector3());
        const f = c.framing;
        const dist = Math.min(f.focusMax, Math.max(f.focusMin, Math.max(size.x, size.y, size.z) * 2.1 + 0.8));
        const dir = camera.position.clone().sub(controls.target).normalize();
        if (dir.y < 0.12) dir.y = 0.12;
        dir.normalize();
        fly(ctr.clone().add(dir.multiplyScalar(dist)), ctr);
      },
      preset(name) {
        const c = state.current.car;
        if (c) fly(c.framing.presets[name].clone(), c.framing.target.clone());
      },
    };

    return () => {
      disposed = true;
      cancelAnimationFrame(raf);
      ro.disconnect();
      cv.removeEventListener('pointermove', onMove);
      cv.removeEventListener('pointerdown', onDown);
      cv.removeEventListener('pointerup', onUp);
      cv.removeEventListener('pointerleave', onLeave);
      controls.dispose();
      scene.traverse((o) => {
        if (o.geometry) o.geometry.dispose();
        if (o.material) (Array.isArray(o.material) ? o.material : [o.material]).forEach((m) => m.dispose());
      });
      renderer.dispose();
      if (cv.parentNode === el) el.removeChild(cv);
      state.current = {};
    };
  }, [modelUrl]);

  useEffect(() => {
    const c = state.current.car;
    if (!c) return;
    Object.values(c.parts).forEach((pt) => {
      const hot = pt.id === hover || pt.id === selected;
      const dim = selected && pt.id !== selected && pt.id !== hover;
      pt.apply(hot ? 'hot' : dim ? 'dim' : 'normal');
    });
    state.current.shellBase = selected ? 0.07 : 0.26;
  }, [hover, selected, ready]);

  useImperativeHandle(ref, () => ({
    focus: (id) => state.current.focus?.(id),
    preset: (name) => state.current.preset?.(name),
    set: (key, on) => {
      const c = state.current.car;
      if (c) c.anim[key] = on;
    },
    canvas: () => state.current.canvas,
  }));

  return <div ref={host} className="x3d" />;
});

export default Car3D;
