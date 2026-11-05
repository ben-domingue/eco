// Homepage specimen card, after the IRW homepage's: real rows from one table,
// buttons to switch kind of design, "Show another" within a kind. Reads the
// array SPECIMENS that index.qmd inlines from data/specimens.json. Opens on a
// random specimen so the page does not always lead with the same table.
(function () {
  const card = document.getElementById("eco-specimen");
  const S = (typeof SPECIMENS !== "undefined" && Array.isArray(SPECIMENS)) ? SPECIMENS : [];
  if (!card) return;
  if (!S.length) { card.innerHTML = "<p>No specimens available.</p>"; return; }
  const esc = s => String(s == null ? "" : s).replace(/[&<>"']/g,
    c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  const groups = [...new Set(S.map(x => x.group))].map(g => ({ name: g, items: S.filter(x => x.group === g) }));
  let gi = Math.floor(Math.random() * groups.length);
  let si = Math.floor(Math.random() * groups[gi].items.length);
  let codeOpen = false;
  const draw = () => {
    const g = groups[gi], d = g.items[si], many = g.items.length > 1;
    const yi = d.columns.indexOf("y");
    const grid = `grid-template-columns: repeat(${d.columns.length}, minmax(72px, 1fr));`;
    const cell = (v, k, head) => `<span class="${k === yi ? "y" : ""}${head ? "" : (k === yi && Number(v) > 0 ? " hit" : "")}">${esc(v)}</span>`;
    const head = `<div class="spec-row head" style="${grid}">${d.columns.map((c, k) => cell(c, k, true)).join("")}</div>`;
    const body = d.rows.map((r, j) => `<div class="spec-row${j % 2 ? " alt" : ""}" style="${grid}">${r.map((v, k) => cell(v, k, false)).join("")}</div>`).join("");
    const pills = groups.map((x, k) => `<button type="button" class="spec-pill" data-go="${k}" aria-pressed="${k === gi}">${esc(x.name)}</button>`).join("");
    card.innerHTML = `
      <div class="spec-top"><span class="spec-chip">${esc(d.family)}</span>
        <span class="spec-pos">${many ? `${si + 1} of ${g.items.length}` : ""}</span></div>
      <h3 class="spec-title">${esc(d.title)}</h3>
      <div class="spec-meta"><a class="spec-name" href="data.html#${esc(d.table)}"><code>${esc(d.table)}</code></a><span>${esc(d.dims)}</span></div>
      <div class="spec-grid-wrap">${head}${body}<div class="spec-more">… ${Number(d.n_rows).toLocaleString("en-US")} rows</div></div>
      <div class="spec-fetch"><button type="button" class="spec-code-toggle" data-code aria-expanded="${codeOpen}">${codeOpen ? "Hide code" : "Show code to fetch"}</button>
        <pre class="spec-code"${codeOpen ? "" : " hidden"}><code>${esc(d.fetch)}</code></pre></div>
      <div class="spec-foot"><div class="spec-pills" role="group" aria-label="Kind of design">${pills}</div>
        <button type="button" class="spec-next" data-next${many ? "" : " disabled"}>Show another →</button></div>`;
    card.querySelector("[data-code]").addEventListener("click", () => { codeOpen = !codeOpen; draw(); });
    card.querySelectorAll("[data-go]").forEach(b => b.addEventListener("click", () => { gi = Number(b.dataset.go); si = 0; draw(); }));
    card.querySelector("[data-next]").addEventListener("click", () => { si = (si + 1) % g.items.length; draw(); });
  };
  draw();
})();
