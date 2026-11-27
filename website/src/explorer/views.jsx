const wheel = (id, cx) => [
  {
    id: `tyre-${id}`,
    kind: 'tyres',
    name: `${id === 'f' ? 'Front' : 'Rear'} tyre`,
    hit: null,
    shape: <circle cx={cx} cy={330} r={53} className="ring" />,
  },
  {
    id: `brakes-${id}`,
    kind: 'brakes',
    name: `${id === 'f' ? 'Front' : 'Rear'} brakes`,
    hit: [cx - 36, 294, 72, 72],
    shape: (
      <>
        <circle cx={cx} cy={330} r={31} className="fill" />
        <circle cx={cx} cy={330} r={9} className="line" />
        <path d={`M ${cx + 6} 296 A 36 36 0 0 1 ${cx + 33} 318 L ${cx + 21} 326 A 22 22 0 0 0 ${cx + 6} 312 Z`} className="solid" />
      </>
    ),
  },
];

const spring = (x, top) => {
  let d = `M ${x} ${top}`;
  const steps = [[9, 5], [-18, 7], [18, 7], [-18, 7], [18, 7], [-18, 7], [9, 5]];
  steps.forEach(([dx, dy]) => {
    d += ` l ${dx} ${dy}`;
  });
  return d;
};

export const SIDE = {
  full: [0, 0, 1100, 440],
  body: (
    <>
      <path
        className="body"
        d="M 60 330 L 60 252 Q 62 224 95 216 L 205 198 L 380 178 L 500 96 Q 510 88 528 88 L 780 88 Q 820 90 848 126 L 975 204 Q 1020 218 1030 246 L 1034 330 L 926 330 A 76 76 0 0 0 774 330 L 326 330 A 76 76 0 0 0 174 330 Z"
      />
      <path className="glass" d="M 392 182 L 505 104 L 592 104 L 592 182 Z" />
      <path className="glass" d="M 608 104 L 778 104 Q 806 106 824 130 L 884 182 L 608 182 Z" />
      <path className="seam" d="M 592 182 V 322 M 400 300 H 592" />
      <line x1="0" x2="1100" y1="392" y2="392" className="ground" />
    </>
  ),
  parts: [
    { id: 'door', kind: 'door', name: 'Door', hit: [400, 190, 192, 134], shape: <rect x="400" y="190" width="192" height="134" rx="8" className="outline dashed" /> },
    { id: 'windscreen', kind: 'windscreen', name: 'Windscreen', hit: [392, 104, 200, 78], shape: <path d="M 392 182 L 505 104 L 592 104 L 592 182 Z" className="solid light" /> },
    {
      id: 'exhaust',
      kind: 'exhaust',
      name: 'Exhaust',
      hit: [424, 300, 590, 64],
      shape: (
        <>
          <path d="M 424 312 Q 470 352 520 352 L 940 352" className="line thick" />
          <rect x="940" y="326" width="76" height="34" rx="14" className="fill" />
          <path d="M 1016 343 L 1034 343" className="line thick" />
        </>
      ),
    },
    {
      id: 'fuel',
      kind: 'fuel',
      name: 'Fuel tank',
      hit: [640, 266, 124, 56],
      shape: (
        <>
          <rect x="640" y="270" width="120" height="48" rx="16" className="fill" />
          <path d="M 700 270 V 252 H 560" className="line" />
        </>
      ),
    },
    {
      id: 'gearbox',
      kind: 'gearbox',
      name: 'Gearbox',
      hit: [330, 256, 98, 76],
      shape: (
        <>
          <path d="M 334 262 L 424 262 L 424 328 L 364 328 L 334 300 Z" className="fill" />
          <circle cx="388" cy="296" r="14" className="line" />
        </>
      ),
    },
    {
      id: 'engine',
      kind: 'engine',
      name: 'Engine',
      hit: [150, 204, 176, 52],
      shape: (
        <>
          <rect x="162" y="209" width="150" height="12" rx="4" className="solid" />
          <rect x="158" y="221" width="160" height="30" rx="6" className="fill" />
          {[0, 1, 2, 3, 4].map((i) => (
            <circle key={i} cx={184 + i * 28} cy={236} r={8} className="line" />
          ))}
        </>
      ),
    },
    {
      id: 'radiator',
      kind: 'radiator',
      name: 'Radiator',
      hit: [72, 226, 34, 80],
      shape: (
        <>
          <rect x="80" y="232" width="16" height="70" rx="3" className="fill" />
          {[0, 1, 2, 3, 4, 5].map((i) => (
            <line key={i} x1="80" x2="96" y1={240 + i * 11} y2={240 + i * 11} className="line" />
          ))}
        </>
      ),
    },
    { id: 'battery', kind: 'battery', name: 'Battery', hit: [108, 220, 44, 32], shape: (<><rect x="112" y="224" width="38" height="24" rx="3" className="fill" /><path d="M 120 224 v -4 h 6 v 4 M 136 224 v -4 h 6 v 4" className="line" /></>) },
    { id: 'airfilter', kind: 'airfilter', name: 'Air filter', hit: [336, 192, 58, 44], shape: (<><rect x="340" y="196" width="50" height="36" rx="6" className="fill" />{[0, 1, 2, 3].map((i) => <line key={i} x1={350 + i * 10} x2={350 + i * 10} y1="202" y2="226" className="line" />)}</>) },
    { id: 'alternator', kind: 'alternator', name: 'Alternator', hit: [284, 246, 32, 32], shape: (<><circle cx="300" cy="262" r="12" className="fill" /><circle cx="300" cy="262" r="4" className="line" /></>) },
    ...wheel('f', 250),
    ...wheel('r', 850),
    { id: 'susp-f', kind: 'suspension', name: 'Front suspension', hit: [282, 262, 36, 64], shape: <path d={spring(300, 268)} className="line thick" /> },
    { id: 'susp-r', kind: 'suspension', name: 'Rear suspension', hit: [782, 270, 36, 64], shape: <path d={spring(800, 276)} className="line thick" /> },
    { id: 'headlight', kind: 'headlight', name: 'Headlight', hit: [60, 224, 46, 28], shape: <path d="M 62 252 Q 64 234 86 228 L 104 226 L 100 246 Z" className="solid" /> },
    { id: 'taillight', kind: 'taillight', name: 'Tail light', hit: [1004, 228, 28, 38], shape: <rect x="1010" y="232" width="16" height="32" rx="4" className="solid" /> },
    { id: 'bumper-f', kind: 'bumper', name: 'Front bumper', hit: [54, 290, 50, 36], shape: <path d="M 56 292 L 104 292 L 104 320 L 56 324 Z" className="outline thick" /> },
    { id: 'bumper-r', kind: 'bumper', name: 'Rear bumper', hit: [990, 290, 50, 36], shape: <path d="M 990 292 L 1036 292 L 1036 324 L 990 320 Z" className="outline thick" /> },
    { id: 'mirror', kind: 'mirror', name: 'Side mirror', hit: [380, 180, 30, 24], shape: <rect x="384" y="184" width="22" height="14" rx="5" className="solid" /> },
  ],
};

const tyreFront = (id, x) => ({
  id,
  kind: 'tyres',
  name: 'Front tyre',
  hit: [x, 296, 32, 98],
  shape: <rect x={x + 2} y="298" width="28" height="92" rx="10" className="solid dark" />,
});

export const FRONT = {
  full: [120, 60, 860, 344],
  body: (
    <>
      <path className="body" d="M 372 340 L 372 244 Q 374 206 408 200 L 424 200 L 452 104 Q 456 92 470 92 L 630 92 Q 644 92 648 104 L 676 200 L 692 200 Q 726 206 728 244 L 728 340 Z" />
      <path className="glass" d="M 428 196 L 456 106 Q 458 100 468 100 L 632 100 Q 642 100 644 106 L 672 196 Z" />
      <line x1="0" x2="1100" y1="392" y2="392" className="ground" />
    </>
  ),
  parts: [
    { id: 'hood', kind: 'hood', name: 'Bonnet', hit: [410, 200, 280, 50], shape: <path d="M 424 200 L 676 200 L 690 250 L 410 250 Z" className="outline dashed" /> },
    { id: 'windscreen', kind: 'windscreen', name: 'Windscreen', hit: [428, 100, 244, 96], shape: <path d="M 428 196 L 456 106 Q 458 100 468 100 L 632 100 Q 642 100 644 106 L 672 196 Z" className="solid light" /> },
    { id: 'wipers', kind: 'wipers', name: 'Wipers', hit: [440, 150, 220, 44], shape: <path d="M 440 188 L 540 160 M 560 188 L 650 160" className="line thick" /> },
    { id: 'grille', kind: 'grille', name: 'Grille and radiator', hit: [484, 254, 132, 48], shape: (<><rect x="484" y="256" width="132" height="44" rx="6" className="fill" />{[0, 1, 2, 3, 4, 5, 6, 7, 8].map((i) => <line key={i} x1={496 + i * 13} x2={496 + i * 13} y1="262" y2="294" className="line" />)}</>) },
    { id: 'headlight-l', kind: 'headlight', name: 'Left headlight', hit: [388, 212, 86, 38], shape: <path d="M 390 232 Q 396 214 424 214 L 470 220 L 470 246 L 394 248 Z" className="solid" /> },
    { id: 'headlight-r', kind: 'headlight', name: 'Right headlight', hit: [626, 212, 86, 38], shape: <path d="M 710 232 Q 704 214 676 214 L 630 220 L 630 246 L 706 248 Z" className="solid" /> },
    { id: 'fog-l', kind: 'fog', name: 'Left fog light', hit: [398, 292, 34, 34], shape: <circle cx="415" cy="309" r="11" className="solid" /> },
    { id: 'fog-r', kind: 'fog', name: 'Right fog light', hit: [668, 292, 34, 34], shape: <circle cx="685" cy="309" r="11" className="solid" /> },
    { id: 'bumper', kind: 'bumper', name: 'Front bumper', hit: [376, 300, 348, 40], shape: <rect x="376" y="304" width="348" height="32" rx="14" className="outline thick" /> },
    { id: 'mirror-l', kind: 'mirror', name: 'Left mirror', hit: [346, 184, 30, 28], shape: <rect x="350" y="188" width="24" height="16" rx="6" className="solid" /> },
    { id: 'mirror-r', kind: 'mirror', name: 'Right mirror', hit: [726, 184, 30, 28], shape: <rect x="726" y="188" width="24" height="16" rx="6" className="solid" /> },
    tyreFront('tyre-l', 346),
    tyreFront('tyre-r', 722),
  ],
};

export const VIEWS = { side: SIDE, front: FRONT };
