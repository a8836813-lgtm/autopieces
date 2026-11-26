const S = { fill: 'none', stroke: 'var(--cobalt-deep)', strokeWidth: 2.2, strokeLinecap: 'round', strokeLinejoin: 'round' };
const Y = { fill: 'var(--tag-light)', stroke: 'var(--cobalt-deep)', strokeWidth: 2.2, strokeLinejoin: 'round' };

const SHAPES = {
  Brakes: (
    <>
      <circle cx="24" cy="24" r="16" {...S} />
      <circle cx="24" cy="24" r="5" {...S} />
      {[0, 60, 120, 180, 240, 300].map((a) => (
        <circle key={a} cx={24 + 10.5 * Math.cos((a * Math.PI) / 180)} cy={24 + 10.5 * Math.sin((a * Math.PI) / 180)} r="1.3" fill="var(--cobalt-deep)" />
      ))}
      <path d="M34 8 q9 4 9 16 q0 12 -9 16 l-3 -6 q4 -4 4 -10 q0 -6 -4 -10 z" {...Y} />
    </>
  ),
  Filters: (
    <>
      <rect x="12" y="14" width="24" height="26" rx="3" {...S} />
      <rect x="10" y="8" width="28" height="8" rx="2" {...Y} />
      {[18, 24, 30].map((x) => <path key={x} d={`M${x} 20 v14`} {...S} />)}
    </>
  ),
  Battery: (
    <>
      <rect x="6" y="14" width="36" height="24" rx="3" {...S} />
      <path d="M13 14 v-4 h6 v4 M29 14 v-4 h6 v4" {...S} />
      <path d="M25 18 l-6 8 h5 l-2 8 l8 -10 h-5 z" {...Y} />
    </>
  ),
  Engine: (
    <>
      <circle cx="24" cy="24" r="8" {...S} />
      <circle cx="24" cy="24" r="3" {...Y} />
      {[0, 45, 90, 135, 180, 225, 270, 315].map((a) => (
        <path key={a} d="M24 8 v5" {...S} transform={`rotate(${a} 24 24)`} />
      ))}
    </>
  ),
  Electrical: <path d="M27 5 L11 26 h11 l-3 17 l18 -23 h-12 z" {...Y} />,
  Suspension: (
    <>
      <path d="M14 6 h20 M14 42 h20" {...S} />
      <path d="M24 6 v4 l-9 4 l18 5 l-18 5 l18 5 l-18 5 l9 4 v4" {...S} />
      <circle cx="24" cy="24" r="2.5" {...Y} />
    </>
  ),
  Cooling: (
    <>
      <rect x="6" y="12" width="36" height="24" rx="3" {...S} />
      {[14, 20, 26, 32, 38].map((x) => <path key={x} d={`M${x} 16 v16`} {...S} />)}
      <path d="M24 3 q4 5 0 8 q-4 -3 0 -8z" {...Y} />
    </>
  ),
  Body: (
    <>
      <path d="M5 30 l4 -10 q2 -4 6 -4 h18 q4 0 6 4 l4 10 v6 h-38 z" {...S} />
      <path d="M12 22 h24" {...S} />
      <circle cx="14" cy="36" r="4" {...Y} />
      <circle cx="34" cy="36" r="4" {...Y} />
    </>
  ),
  Other: (
    <>
      <path d="M24 6 l15 9 v18 l-15 9 l-15 -9 v-18 z" {...S} />
      <circle cx="24" cy="24" r="5" {...Y} />
    </>
  ),
};

export function PartArt({ category, size = 48 }) {
  const shape = SHAPES[category] || SHAPES.Other;
  return (
    <span className="art" style={{ width: size, height: size }}>
      <svg viewBox="0 0 48 48" width={size * 0.72} height={size * 0.72} aria-hidden="true">{shape}</svg>
    </span>
  );
}

const TONES = [
  ['#e1edf0', '#0f4c5c'],
  ['#fde7d9', '#c2410c'],
  ['#ddefe3', '#14532d'],
  ['#eceae4', '#14181f'],
];

export function Monogram({ name = '', size = 44 }) {
  const initials = name.split(/\s+/).filter(Boolean).slice(0, 2).map((w) => w[0]).join('').toUpperCase();
  const h = [...name].reduce((s, c) => s + c.charCodeAt(0), 0);
  const [bg, fg] = TONES[h % TONES.length];
  return (
    <span className="mono" style={{ width: size, height: size, background: bg, color: fg, fontSize: size * 0.38 }}>
      {initials}
    </span>
  );
}
