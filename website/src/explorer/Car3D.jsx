import { forwardRef, useEffect, useImperativeHandle, useRef } from 'react';
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { ORANGE, createCar } from './carScene.js';

const TARGET = new THREE.Vector3(0, 1.3, 0);
const PRESETS = {
  angle: new THREE.Vector3(-5.4, 3.3, 7.0),
  side: new THREE.Vector3(0, 1.6, 10.2),
  front: new THREE.Vector3(-10.2, 1.6, 0.01),
  top: new THREE.Vector3(0, 11.5, 0.01),
};

const ease = (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);

const Car3D = forwardRef(function Car3D({ selected, hover, onHover, onPick }, ref) {
  const host = useRef(null);
  const state = useRef({});
  const cb = useRef({ onHover, onPick });
  cb.current = { onHover, onPick };

  useEffect(() => {
    const el = host.current;
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(34, 2, 0.1, 100);
    camera.position.copy(PRESETS.angle);
    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    el.appendChild(renderer.domElement);
    renderer.domElement.style.display = 'block';
    renderer.domElement.style.width = '100%';
    renderer.domElement.style.height = '100%';

    scene.add(new THREE.HemisphereLight('#ffffff', '#cfcdc6', 1.5));
    const sun = new THREE.DirectionalLight('#ffffff', 1.6);
    sun.position.set(-4, 9, 6);
    scene.add(sun);
    const fill = new THREE.DirectionalLight('#ffffff', 0.6);
    fill.position.set(6, 3, -6);
    scene.add(fill);

    const grid = new THREE.GridHelper(24, 24, '#cfcdc6', '#e3e1db');
    grid.position.y = 0;
    scene.add(grid);

    const { root, parts, pickables, shell, edges } = createCar();
    scene.add(root);

    const controls = new OrbitControls(camera, renderer.domElement);
    controls.target.copy(TARGET);
    controls.enableDamping = true;
    controls.minDistance = 1.2;
    controls.maxDistance = 22;
    controls.maxPolarAngle = Math.PI * 0.55;
    controls.update();

    const ray = new THREE.Raycaster();
    const ndc = new THREE.Vector2();
    let anim = null;
    let raf = 0;
    let down = null;
    let hovered = null;

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
      const r = renderer.domElement.getBoundingClientRect();
      ndc.set(((e.clientX - r.left) / r.width) * 2 - 1, -((e.clientY - r.top) / r.height) * 2 + 1);
      ray.setFromCamera(ndc, camera);
      const hit = ray.intersectObjects(pickables, false)[0];
      return hit ? hit.object.userData.partId : null;
    }

    const onMove = (e) => {
      if (e.buttons) return;
      const id = pick(e);
      if (id !== hovered) {
        hovered = id;
        renderer.domElement.style.cursor = id ? 'pointer' : 'grab';
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
    const cv = renderer.domElement;
    cv.addEventListener('pointermove', onMove);
    cv.addEventListener('pointerdown', onDown);
    cv.addEventListener('pointerup', onUp);
    cv.addEventListener('pointerleave', onLeave);
    cv.style.cursor = 'grab';
    cv.style.touchAction = 'none';

    function loop(now) {
      raf = requestAnimationFrame(loop);
      if (anim) {
        const k = Math.min(1, (now - anim.t0) / 750);
        const e = ease(k);
        camera.position.lerpVectors(anim.p0, anim.p1, e);
        controls.target.lerpVectors(anim.t0v, anim.t1v, e);
        if (k >= 1) anim = null;
      }
      controls.update();
      renderer.render(scene, camera);
    }
    raf = requestAnimationFrame(loop);

    state.current = {
      shell,
      edges,
      parts,
      renderer,
      camera,
      controls,
      fly,
      focus(id) {
        const g = parts[id];
        if (!g) return;
        const box = new THREE.Box3().setFromObject(g);
        const c = box.getCenter(new THREE.Vector3());
        const size = box.getSize(new THREE.Vector3());
        const dist = Math.min(11, Math.max(2.2, Math.max(size.x, size.y, size.z) * 2.1 + 0.8));
        const dir = camera.position.clone().sub(controls.target).normalize();
        if (dir.y < 0.12) dir.y = 0.12;
        if (Math.abs(dir.z) < 0.35) dir.z = dir.z < 0 ? -0.35 : 0.35;
        dir.normalize();
        fly(c.clone().add(dir.multiplyScalar(dist)), c);
      },
      preset(name) {
        fly(PRESETS[name].clone(), TARGET.clone());
      },
    };

    return () => {
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
    };
  }, []);

  useEffect(() => {
    const { parts, shell, edges } = state.current;
    if (!parts) return;
    shell.material.opacity = selected ? 0.07 : 0.26;
    edges.material.transparent = true;
    edges.material.opacity = selected ? 0.25 : 1;
    Object.values(parts).forEach((g) => {
      const { material, base, baseOpacity, partId } = g.userData;
      const hot = partId === hover || partId === selected;
      const dim = selected && partId !== selected && partId !== hover;
      material.color.set(hot ? ORANGE : base);
      material.emissive.set(hot ? ORANGE : '#000000');
      material.emissiveIntensity = hot ? 0.25 : 0;
      material.opacity = dim ? Math.min(baseOpacity, 0.22) : hot ? Math.max(baseOpacity, 0.55) : baseOpacity;
      material.transparent = material.opacity < 1;
      material.needsUpdate = true;
    });
  }, [hover, selected]);

  useImperativeHandle(ref, () => ({
    focus: (id) => state.current.focus?.(id),
    preset: (name) => state.current.preset?.(name),
    canvas: () => state.current.renderer?.domElement,
  }));

  return <div ref={host} className="x3d" />;
});

export default Car3D;
