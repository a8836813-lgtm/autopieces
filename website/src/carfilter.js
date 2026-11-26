export function indexFitments(parts) {
  const map = {};
  parts.forEach((p) => {
    let list = [];
    try {
      list = p.fitments_json ? JSON.parse(p.fitments_json) : [];
    } catch {}
    map[p.id] = { list, fits: (p.fits || '').toLowerCase() };
  });
  return map;
}

export function fitsCar(map, brand, model, partId) {
  if (!brand) return true;
  const f = map[partId];
  if (!f) return true;
  if (f.list.length) return f.list.some((x) => x.brandId === brand.id && (!model || x.model === model));
  if (!f.fits || f.fits.includes('universal')) return true;
  return f.fits.includes(brand.name.toLowerCase()) && (!model || f.fits.includes(model.toLowerCase()));
}
