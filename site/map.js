// The homepage map: one point per table (data/map.json, from
// metadata/table_locations.csv via prerender.R). Expects MAP_DATA and Leaflet
// (L) on the page and #eco-map / #eco-map-legend elements.
//
// Many tables share a place (several tables from one deposit), so hovering
// does not rely on the topmost marker: it lists every table within a few
// pixels of the cursor. Clicking one table opens its entry; clicking a stack
// zooms in, and at close zoom pins the list so its links can be followed.
(function () {
  const el = document.getElementById("eco-map");
  if (!el || typeof L === "undefined") return;
  // Taxon groups in corpus order; validated categorical palette, "Multiple" in neutral grey.
  const GROUPS = [
    ["Mammals", "#2a78d6"], ["Birds", "#eb6834"], ["Invertebrates", "#1baf7a"],
    ["Amphibians", "#eda100"], ["Fish", "#e87ba4"], ["Reptiles", "#008300"],
    ["Plants", "#6250d6"], ["Multiple", "#8a8c94"]
  ];
  const COL = Object.fromEntries(GROUPS);
  const SRC = {
    "unit coordinates": "mean of the table's site coordinates",
    "bounding box": "centre of the study area's bounding box",
    "place name": "a best guess from the study-area description"
  };
  const WIDE = 1000;    // km: a study area this wide is drawn as a ring, not a dot
  const HIT = 9;        // px: how close the cursor must be to count a point
  const esc = (s) => String(s ?? "").replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  const fmt = (n) => Number(n).toLocaleString("en-US");
  const href = (p) => `data.html#${encodeURIComponent(p.table)}`;

  const map = L.map(el, { worldCopyJump: true, scrollWheelZoom: false, minZoom: 1, maxZoom: 11 }).setView([22, 5], 2);
  L.tileLayer("https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}", {
    attribution: "Base map &copy; Esri, HERE, Garmin, &copy; OpenStreetMap contributors", maxZoom: 16
  }).addTo(map);
  map.on("focus", () => map.scrollWheelZoom.enable());
  map.on("blur", () => map.scrollWheelZoom.disable());

  const pts = MAP_DATA.points;
  map.fitBounds(L.latLngBounds(pts.map((p) => [p.lat, p.lon])), { padding: [12, 12] });
  // Big rings first, so dots draw on top of them.
  pts.sort((a, b) => (b.extent_km >= WIDE) - (a.extent_km >= WIDE));
  for (const p of pts) {
    const c = COL[p.taxon_group] || "#8a8c94";
    const wide = p.extent_km >= WIDE;
    L.circleMarker([p.lat, p.lon], wide
      ? { radius: 9, color: c, weight: 2.5, fill: false, interactive: false }
      : { radius: 5, color: "#ffffff", weight: 1.5, fillColor: c, fillOpacity: 0.95, interactive: false }
    ).addTo(map);
  }

  const card = document.createElement("div");
  card.className = "eco-map-card";
  card.hidden = true;
  el.appendChild(card);
  let pinned = false;

  const entry = (p, full) => {
    const dims = [`${fmt(p.n_units)} units`, `${fmt(p.n_taxa)} ${p.n_taxa == 1 ? "taxon" : "taxa"}`];
    if (p.n_periods > 1) dims.push(`${p.n_periods} periods`);
    const yrs = p.years ? " · " + esc(String(p.years).replace("/", "–")) : "";
    const sw = `<span class="sw" style="--sw:${COL[p.taxon_group] || "#8a8c94"}"></span>`;
    if (!full) {
      return `<li>${sw}<a href="${href(p)}">${esc(p.title)}</a><div class="m">${dims.join(" · ")}${yrs}</div></li>`;
    }
    const ext = p.extent_km ? ` across about ${fmt(p.extent_km)} km` : "";
    const why = p.source === "place name" ? ` (${esc(p.basis)})` : "";
    return `<div class="t">${esc(p.title)}</div>
      <div class="c"><code>${esc(p.table)}</code></div>
      <div class="m">${sw}${esc(p.taxon_group)} · ${esc(p.model_family)}</div>
      <div class="m">${dims.join(" · ")}${yrs}</div>
      <div class="w">Location: ${esc(p.precision)}-level point${ext}, ${SRC[p.source]}${why}.</div>`;
  };

  const near = (cp) => {
    const out = [];
    for (const p of pts) {
      const q = map.latLngToContainerPoint([p.lat, p.lon]);
      const r = p.extent_km >= WIDE ? HIT + 4 : HIT;
      if (Math.abs(q.x - cp.x) <= r && Math.abs(q.y - cp.y) <= r) out.push(p);
    }
    return out;
  };

  const show = (cp, hits) => {
    if (!hits.length) { card.hidden = true; el.style.cursor = ""; return; }
    el.style.cursor = "pointer";
    if (hits.length === 1) {
      card.innerHTML = entry(hits[0], true);
    } else {
      const MAX = 4;
      const more = hits.length > MAX
        ? `<div class="w">and ${hits.length - MAX} more; ${map.getZoom() >= 7 ? "click to pin the list" : "click to zoom in"}</div>`
        : `<div class="w">${map.getZoom() >= 7 ? "Click to pin the list" : "Click to zoom in"}</div>`;
      card.innerHTML = `<div class="t">${hits.length} tables here</div><ul>${hits.slice(0, MAX).map((p) => entry(p, false)).join("")}</ul>${more}`;
    }
    card.hidden = false;
    const w = el.clientWidth, cw = card.offsetWidth, ch = card.offsetHeight;
    card.style.left = Math.max(4, Math.min(w - cw - 4, cp.x - cw / 2)) + "px";
    const h = el.clientHeight;
    const top = cp.y - ch - 14 >= 4 ? cp.y - ch - 14 : cp.y + 16;
    card.style.top = Math.max(4, Math.min(h - ch - 4, top)) + "px";
  };

  map.on("mousemove", (e) => { if (!pinned) show(e.containerPoint, near(e.containerPoint)); });
  map.on("mouseout", () => { if (!pinned) card.hidden = true; });
  map.on("movestart", () => { pinned = false; card.hidden = true; card.classList.remove("pinned"); });
  map.on("click", (e) => {
    if (pinned) { pinned = false; card.classList.remove("pinned"); show(e.containerPoint, near(e.containerPoint)); return; }
    const hits = near(e.containerPoint);
    if (hits.length === 1) { window.location.href = href(hits[0]); return; }
    if (hits.length > 1) {
      if (map.getZoom() >= 7) {
        card.innerHTML = `<div class="t">${hits.length} tables here</div><ul>${hits.map((p) => entry(p, false)).join("")}</ul><div class="w">Click the map to close</div>`;
        pinned = true; card.classList.add("pinned");
      } else {
        map.setView(e.latlng, Math.min(map.getZoom() + 3, 9));
      }
    }
  });
  card.addEventListener("click", (ev) => ev.stopPropagation());
  L.DomEvent.disableClickPropagation(card);
  L.DomEvent.disableScrollPropagation(card);

  const present = new Set(pts.map((p) => p.taxon_group));
  const lg = document.getElementById("eco-map-legend");
  if (lg) {
    lg.innerHTML = GROUPS.filter(([g]) => present.has(g))
      .map(([g, c]) => `<span style="--sw:${c}">${g}</span>`).join("")
      + `<span class="ring">study area over ${fmt(WIDE)} km across</span>`;
  }
})();
