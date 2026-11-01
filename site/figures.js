// Chart code ported from report.html (analysis/report_template.html).
// Expects a global D with the contents of analysis/figures.json.
const ns = "http://www.w3.org/2000/svg";
const el = (t, a, parent) => { const e = document.createElementNS(ns, t); for (const k in a) e.setAttribute(k, a[k]); if (parent) parent.appendChild(e); return e; };
const css = v => getComputedStyle(document.documentElement).getPropertyValue(v).trim();
const col = { malhotra_2021_loslagos_comm: "var(--c1)", palacio_2020_pampasbirds_comm: "var(--c2)", frimpong_2017_newriver_dynocc: "var(--c3)", schank_2015_tapir_occ: "var(--ink-3)" };
const W = 520, H = 340, m = { l: 56, r: 16, t: 12, b: 48 };
function frame(svg, xl, yl, xt, yt, xf, yf, fmt) {
  // axes, grid, labels; xt/yt tick values; xf/yf scale functions
  yt.forEach(v => { el("line", { x1: m.l, x2: W - m.r, y1: yf(v), y2: yf(v), stroke: "var(--grid)", "stroke-width": 1 }, svg);
    const t = el("text", { x: m.l - 8, y: yf(v) + 4, "text-anchor": "end", "font-size": 11, fill: "var(--ink-3)" }, svg); t.textContent = fmt(v); });
  el("line", { x1: m.l, x2: W - m.r, y1: H - m.b, y2: H - m.b, stroke: "var(--line-strong)" }, svg);
  xt.forEach(v => { const t = el("text", { x: xf(v), y: H - m.b + 16, "text-anchor": "middle", "font-size": 11, fill: "var(--ink-3)" }, svg); t.textContent = fmt(v); });
  const xl_ = el("text", { x: (m.l + W - m.r) / 2, y: H - 8, "text-anchor": "middle", "font-size": 12, fill: "var(--ink-2)" }, svg); xl_.textContent = xl;
  const yl_ = el("text", { x: 14, y: (m.t + H - m.b) / 2, "text-anchor": "middle", "font-size": 12, fill: "var(--ink-2)", transform: `rotate(-90 14 ${(m.t + H - m.b) / 2})` }, svg); yl_.textContent = yl;
}
const lin = (d0, d1, r0, r1) => v => r0 + (v - d0) / (d1 - d0) * (r1 - r0);
const pct = v => Math.round(v * 100) + "%";
// Figure 1: species as items
(function(){
  const svg = document.getElementById("f1"); if (!svg) return;
  const ymax = 0.5;
  const xf = lin(0, 1, m.l, W - m.r), yf = lin(0, ymax, H - m.b, m.t);
  frame(svg, "naive occupancy (share of units with a detection)", "detection rate per survey", [0, .25, .5, .75, 1], [0, .1, .2, .3, .4, .5], xf, yf, pct);
  D.taxa.forEach(d => {
    const c = el("circle", { cx: xf(d.naive_occ), cy: yf(Math.min(d.det_rate, ymax)), r: 4.5, fill: col[d.table], "fill-opacity": .75, stroke: "var(--paper)", "stroke-width": 1.5 }, svg);
    const t = el("title", {}, c); t.textContent = `${d.taxon ?? d.item} (${d.table.split("_")[0]}): naive occupancy ${pct(d.naive_occ)}, detected in ${pct(d.det_rate)} of ${d.n_surveys.toLocaleString()} surveys`;
  });
})();
// Figure 2: estimated vs naive occupancy
(function(){
  const svg = document.getElementById("f2"); if (!svg) return;
  const xf = lin(0, 1, m.l, W - m.r), yf = lin(0, 1, H - m.b, m.t);
  frame(svg, "naive occupancy", "estimated occupancy ψ", [0, .25, .5, .75, 1], [0, .25, .5, .75, 1], xf, yf, pct);
  el("line", { x1: xf(0), y1: yf(0), x2: xf(1), y2: yf(1), stroke: "var(--line-strong)", "stroke-dasharray": "4 4" }, svg);
  const lab = el("text", { x: xf(.78), y: yf(.72), "font-size": 11, fill: "var(--ink-3)" }, svg); lab.textContent = "ψ = naive";
  const sorted = D.est.slice().sort((a, b) => b.p - a.p);
  sorted.forEach(d => {
    const r = 3 + 14 * Math.sqrt(d.p);
    const c = el("circle", { cx: xf(d.naive_occ), cy: yf(d.psi), r, fill: col[d.table], "fill-opacity": .6, stroke: "var(--paper)", "stroke-width": 1.5 }, svg);
    const t = el("title", {}, c); t.textContent = `${d.taxon ?? d.item}: naive ${pct(d.naive_occ)}, ψ ${pct(d.psi)}, p ${pct(d.p)} (${d.n_units} units)`;
  });
})();
// Figure 3: fish species detected vs effort
(function(){
  const svg = document.getElementById("f3"); if (!svg) return;
  const xs = D.fish_effort.map(d => d.effort), ymax = 25;
  const xf = lin(0.5, 8.5, m.l, W - m.r), yf = lin(0, ymax, H - m.b, m.t);
  frame(svg, "collections in the watershed-year (obs_effort; 8 = 8 or more)", "fish species detected", xs, [0, 5, 10, 15, 20, 25], xf, yf, v => String(v));
  const band = D.fish_effort.map(d => `${xf(d.effort)},${yf(d.q3)}`).concat(D.fish_effort.slice().reverse().map(d => `${xf(d.effort)},${yf(d.q1)}`)).join(" ");
  el("polygon", { points: band, fill: "var(--c3)", "fill-opacity": .15 }, svg);
  el("polyline", { points: D.fish_effort.map(d => `${xf(d.effort)},${yf(d.median_species)}`).join(" "), fill: "none", stroke: "var(--c3)", "stroke-width": 2 }, svg);
  D.fish_effort.forEach(d => {
    const c = el("circle", { cx: xf(d.effort), cy: yf(d.median_species), r: 4.5, fill: "var(--c3)", stroke: "var(--paper)", "stroke-width": 1.5 }, svg);
    const t = el("title", {}, c); t.textContent = `${d.effort} collection(s): median ${d.median_species} species (IQR ${d.q1}–${d.q3}) across ${d.n} watershed-years`;
    const n = el("text", { x: xf(d.effort), y: yf(d.q3) - 6, "text-anchor": "middle", "font-size": 10, fill: "var(--ink-3)" }, svg); n.textContent = "n=" + d.n;
  });
  const lg = el("text", { x: W - m.r, y: m.t + 10, "text-anchor": "end", "font-size": 11, fill: "var(--ink-2)" }, svg); lg.textContent = "median and interquartile range";
})();
// Figure 4: CJS captures per session
(function(){
  const svg = document.getElementById("f4"); if (!svg) return;
  const ymax = 60, n = D.cjs.length, bw = (W - m.l - m.r) / n;
  const xf = i => m.l + bw * (i - 0.5), yf = lin(0, ymax, H - m.b, m.t);
  frame(svg, "capture session (period)", "birds captured", D.cjs.map(d => d.period), [0, 20, 40, 60], xf, yf, v => String(v));
  D.cjs.forEach((d, i) => {
    const x = xf(d.period) - bw * 0.3, w = bw * 0.6;
    const y0 = yf(0), yNew = yf(d.new), yRe = yf(d.new + d.recaptured);
    const r1 = el("rect", { x, width: w, y: yNew, height: y0 - yNew, fill: "var(--c1)" }, svg);
    el("title", {}, r1).textContent = `session ${d.period}: ${d.new} first captures`;
    if (d.recaptured > 0) {
      const r2 = el("rect", { x, width: w, y: yRe, height: yNew - yRe - 2, fill: "var(--c2)" }, svg);
      el("title", {}, r2).textContent = `session ${d.period}: ${d.recaptured} recaptures`;
    }
    const t = el("text", { x: xf(d.period), y: yRe - 6, "text-anchor": "middle", "font-size": 11, fill: "var(--ink-2)" }, svg); t.textContent = d.captured;
  });
})();
