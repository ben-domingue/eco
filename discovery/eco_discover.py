#!/usr/bin/env python3
"""Light discovery pass: where does ecological detection data live?

Connectors for Dataverse, Zenodo, Dryad, Figshare and OSF are adapted from
ben-domingue/irw src/automated_finding/irw_discover_updated.py (same endpoints,
same pagination and sleep discipline). Ecology-specific connectors (EDI/PASTA,
DataONE, ScienceBase, NEON, GBIF sampling-event datasets) are new.

Every HTTP response is cached in discovery/cache/ so re-runs cost nothing.

Two kinds of query (2026-11-04, after the Daily-lab Costa Rica deposits turned
out to have been hit but never triaged, or missed because their titles name the
finding rather than the method):
  * term queries: QUERIES below, paged up to --max-hits results per
    (source, query) instead of the first 20;
  * author queries: every creator in ../metadata/biblio.csv (people who already
    deposit detection data) plus discovery/authors_seed.csv, on the sources whose
    APIs search by author (Dryad, Zenodo, Dataverse), up to --author-max each.

Output:
  discovery/hit_counts.csv  total per (source, query)
  discovery/raw_hits.csv    every hit, with query_kind and a normalised doi_norm
  discovery/backlog.csv     one row per distinct deposit not yet in
                            ../discovery_log.csv, ../queue/candidates.csv or
                            ../queue/human_review.csv: the triage worklist

Usage: python3 discovery/eco_discover.py [--max-hits 1000] [--author-max 100]
                                         [--no-authors] [--sources dryad,zenodo]
"""
import argparse, csv, hashlib, json, os, re, sys, time, urllib.parse, urllib.request, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(HERE, "cache"); os.makedirs(CACHE, exist_ok=True)
UA = {"User-Agent": "eco-irw-scout/0.2 (research; https://github.com/ben-domingue/eco)"}
ROOT = os.path.dirname(HERE)

QUERIES = [
    "detection history", "occupancy model", "capture history", "capture-recapture",
    "N-mixture", "repeated counts", "point count", "camera trap",
    "detection/non-detection", "encounter history",
]

def _cache_key(method, url, body):
    return hashlib.sha1(f"{method} {url} {body or ''}".encode()).hexdigest()

def http(url, params=None, json_body=None, method=None, sleep=0.6):
    if params:
        url = url + ("&" if "?" in url else "?") + urllib.parse.urlencode(params, doseq=True)
    body = json.dumps(json_body).encode() if json_body is not None else None
    method = method or ("POST" if body else "GET")
    key = os.path.join(CACHE, _cache_key(method, url, body) + ".json")
    if os.path.exists(key):
        with open(key) as f: cached = json.load(f)
        if not (isinstance(cached, dict) and "_error" in cached): return cached
    # Retry rate limits (429) and transient failures with backoff; never cache an
    # error, so a re-run retries it (the 2026-11-04 run lost 174 Dryad queries to 429).
    for attempt in range(6):
        req = urllib.request.Request(url, data=body, method=method, headers={**UA, "Accept": "application/json"})
        if body: req.add_header("Content-Type", "application/json")
        retry = False
        try:
            with urllib.request.urlopen(req, timeout=40) as r:
                txt = r.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            txt = json.dumps({"_error": e.code, "_body": e.read().decode("utf-8", "replace")[:500]})
            retry = e.code in (429, 500, 502, 503, 504)
            wait = e.headers.get("Retry-After") if e.headers else None
        except Exception as e:
            txt = json.dumps({"_error": str(e)}); retry, wait = True, None
        if not retry: break
        delay = float(wait) if wait and str(wait).isdigit() else min(10 * 2 ** attempt, 300)
        print(f"  retry in {delay:.0f}s: {json.loads(txt)['_error']}", file=sys.stderr)
        time.sleep(delay)
    time.sleep(sleep)
    try: data = json.loads(txt)
    except Exception: data = {"_raw": txt[:2000]}
    if not (isinstance(data, dict) and "_error" in data):
        with open(key, "w") as f: json.dump(data, f)
    return data

# ---- connectors: each returns (total_count, [records]) with a uniform record dict
def rec(source, title, url, doi="", license="", year="", extra=""):
    return {"source": source, "title": (title or "").strip()[:200], "url": url, "doi": doi,
            "license": license, "year": str(year)[:10], "extra": extra}

# Each connector takes (q, page, per) with page starting at 1 and returns
# (total, [records]); total None means the request failed. `paged()` walks pages.

def dataverse(q, page=1, per=100):
    d = http("https://dataverse.harvard.edu/api/search",
             {"q": q, "type": "dataset", "per_page": per, "start": (page - 1) * per})
    if "_error" in d: return None, []
    data = d.get("data", {})
    return data.get("total_count", 0), [rec("dataverse", it.get("name"), it.get("url"), it.get("global_id", ""),
                                            "", it.get("published_at", ""), it.get("description", "")[:200] if it.get("description") else "")
                                        for it in data.get("items", [])]

def zenodo(q, page=1, per=25):  # anonymous page size is capped at 25
    d = http("https://zenodo.org/api/records", {"q": q, "size": min(per, 25), "page": page, "type": "dataset"})
    if "_error" in d or "hits" not in d: return None, []
    hits = d.get("hits", {})
    out = []
    for h in hits.get("hits", []):
        md = h.get("metadata", {})
        lic = md.get("license", {}); lic = lic.get("id", "") if isinstance(lic, dict) else str(lic)
        files = ",".join(sorted({f.get("key", "").rsplit(".", 1)[-1].lower() for f in h.get("files", [])}))
        out.append(rec("zenodo", md.get("title"), h.get("links", {}).get("self_html") or f"https://zenodo.org/records/{h.get('id')}",
                       h.get("doi", ""), lic, md.get("publication_date", ""), f"files:{files}"))
    return hits.get("total", 0), out

def dryad(q, page=1, per=100):
    d = http("https://datadryad.org/api/v2/search", {"q": q, "per_page": per, "page": page})
    if "_error" in d: return None, []
    sets = d.get("_embedded", {}).get("stash:datasets", [])
    return d.get("total", 0), [rec("dryad", s.get("title"), f"https://datadryad.org/dataset/{s.get('identifier','')}",
                                   s.get("identifier", ""), s.get("license", ""), s.get("publicationDate", ""),
                                   ";".join(s.get("keywords", [])[:6])) for s in sets]

def figshare(q, page=1, per=100):
    d = http("https://api.figshare.com/v2/articles/search",
             json_body={"search_for": q, "page_size": per, "page": page, "item_type": 3})
    if isinstance(d, dict) and "_error" in d: return None, []
    if not isinstance(d, list): return None, []
    # figshare search returns no total: report "a full page" as more-to-come
    total = (page - 1) * per + len(d) + (1 if len(d) == per else 0)
    return total, [rec("figshare", a.get("title"), a.get("url_public_html"), a.get("doi", ""), "", a.get("published_date", "")) for a in d]

def osf(q, page=1, per=100):
    d = http("https://api.osf.io/v2/nodes/", {"filter[title]": q, "page[size]": per, "page": page})
    if "_error" in d: return None, []
    total = d.get("links", {}).get("meta", {}).get("total", 0)
    return total, [rec("osf", n["attributes"].get("title"), n.get("links", {}).get("html"), "", "",
                       n["attributes"].get("date_created", "")) for n in d.get("data", [])]

def _solr_q(q):
    return f'(title:"{q}" OR abstract:"{q}" OR keywords:"{q}") AND formatType:METADATA AND -obsoletedBy:*'

def edi(q, page=1, per=100):
    # PASTA's own search endpoint returns 403 for unauthenticated users (checked
    # 2026-10-30), so EDI is queried through DataONE, where it is member node urn:node:EDI.
    d = http("https://cn.dataone.org/cn/v2/query/solr/",
             {"q": _solr_q(q) + ' AND datasource:"urn:node:EDI"',
              "fl": "id,title,dateUploaded", "rows": per, "start": (page - 1) * per, "wt": "json"})
    if "_error" in d: return None, []
    resp = d.get("response", {})
    out = []
    for x in resp.get("docs", []):
        pid = x.get("id", "")
        out.append(rec("edi", x.get("title"), f"https://portal.edirepository.org/nis/mapbrowse?packageid={pid}",
                       pid if pid.startswith("doi:") else "", "CC0 or CC-BY (EDI policy)", x.get("dateUploaded", "")))
    return resp.get("numFound", 0), out

def dataone(q, page=1, per=100):
    d = http("https://cn.dataone.org/cn/v2/query/solr/",
             {"q": _solr_q(q), "fl": "id,title,datasource,rightsHolder,dateUploaded,formatId",
              "rows": per, "start": (page - 1) * per, "wt": "json"})
    if "_error" in d: return None, []
    resp = d.get("response", {})
    return resp.get("numFound", 0), [rec("dataone", x.get("title"), f"https://search.dataone.org/view/{urllib.parse.quote(x.get('id',''), safe='')}",
                                         x.get("id", "") if str(x.get("id", "")).startswith("doi:") else "", "",
                                         x.get("dateUploaded", ""), x.get("datasource", "")) for x in resp.get("docs", [])]

def sciencebase(q, page=1, per=100):
    d = http("https://www.sciencebase.gov/catalog/items", {"q": q, "format": "json", "max": per, "offset": (page - 1) * per,
                                                             "fields": "title,webLinks,dates,identifiers",
                                                             "filter": "browseCategory=Data"})
    if "_error" in d: return None, []
    out = []
    for it in d.get("items", []):
        doi = next((i.get("key") for i in (it.get("identifiers") or []) if "doi" in str(i.get("type", "")).lower()), "")
        out.append(rec("sciencebase", it.get("title"), it.get("link", {}).get("url"), doi, "Public domain (USGS)", ""))
    return d.get("total", 0), out

def gbif_sampling_event(q, page=1, per=100):
    d = http("https://api.gbif.org/v1/dataset/search", {"q": q, "type": "SAMPLING_EVENT", "limit": per, "offset": (page - 1) * per})
    if "_error" in d: return None, []
    return d.get("count", 0), [rec("gbif_sampling_event", r.get("title"), f"https://www.gbif.org/dataset/{r.get('key')}",
                                   r.get("doi", ""), r.get("license", ""), "", f"records:{r.get('recordCount','')}")
                               for r in d.get("results", [])]

def neon(q=None, per=50):
    d = http("https://data.neonscience.org/api/v0/products")
    if "_error" in d: return None, []
    keep = ("bird", "mammal", "beetle", "mosquito", "fish", "tick", "plant", "herbaceous", "amphib", "zooplankton", "macroinvert")
    out = []
    for p in d.get("data", []):
        name = p.get("productName", "")
        if any(k in name.lower() for k in keep):
            out.append(rec("neon", name, f"https://data.neonscience.org/data-products/{p.get('productCode')}", "",
                           "CC0 (NEON policy)", "", p.get("productCode", "")))
    return len(out), out

# Term queries are phrase-quoted where the API supports it, as before.
TERM_Q = {"dataverse": lambda q: f'"{q}"', "zenodo": lambda q: f'"{q}"', "figshare": lambda q: f'"{q}"'}
SOURCES = {"dataverse": dataverse, "zenodo": zenodo, "dryad": dryad, "figshare": figshare, "osf": osf,
           "edi": edi, "dataone": dataone, "sciencebase": sciencebase, "gbif_sampling_event": gbif_sampling_event}

# Author queries: only where the API can search by creator. Names arrive as
# "Last, First Middle"; Dryad's q is a word match over the record, so it gets
# "First Last" (noisier for common surnames, which is why the cap is low).
def _split(name):
    last, _, first = name.partition(",")
    return last.strip(), first.strip().split(" ")[0] if first.strip() else ""
AUTHOR_Q = {
    "dryad": lambda n: " ".join(x for x in reversed(_split(n)) if x),
    "zenodo": lambda n: "creators.name:(" + " AND ".join(f'"{x}"' for x in _split(n) if x) + ")",
    "dataverse": lambda n: f'authorName:"{_split(n)[0]}, {_split(n)[1]}"' if _split(n)[1] else f'authorName:"{_split(n)[0]}"',
}

def paged(fn, q, max_hits):
    """Walk pages until max_hits records, the reported total, or an empty page."""
    out, page, total = [], 1, None
    while len(out) < max_hits:
        t, recs = fn(q, page=page)
        if t is None: return (total, out) if out else (None, [])
        total = t
        out.extend(recs)
        if not recs or len(out) >= t: break
        page += 1
    return total, out[:max_hits]

def norm_doi(x):
    x = str(x or "").strip().lower()
    x = re.sub(r"^(https?://(dx\.)?doi\.org/|doi:)", "", x)
    return x if x.startswith("10.") else ""

def deposit_key(r):
    return norm_doi(r.get("doi")) or str(r.get("url") or "").strip().lower()

def seed_authors():
    names = set()
    b = os.path.join(ROOT, "metadata", "biblio.csv")
    if os.path.exists(b):
        for row in csv.DictReader(open(b, newline="", encoding="utf-8")):
            for n in (row.get("creator") or "").split(";"):
                n = re.sub(r"\s*\(.*?\)", "", n).strip()
                if "," in n and len(n.split(",")[0].strip()) > 1:   # a person ("Last, First"), not an organisation
                    names.add(n)
    s = os.path.join(HERE, "authors_seed.csv")
    if os.path.exists(s):
        for row in csv.DictReader(open(s, newline="", encoding="utf-8")):
            if row.get("name", "").strip(): names.add(row["name"].strip())
    return sorted(names)

def triaged_keys():
    keys = set()
    # built tables (biblio) count as triaged too: batch 22 was built from the backlog itself
    for f, cols in (("discovery_log.csv", ("doi_or_url",)), ("queue/candidates.csv", ("doi_or_url",)),
                    ("queue/human_review.csv", ("doi_or_url",)), ("metadata/biblio.csv", ("doi_data", "doi_paper", "source_url"))):
        path = os.path.join(ROOT, f)
        if not os.path.exists(path): continue
        for row in csv.DictReader(open(path, newline="", encoding="utf-8")):
          for col in cols:
            v = row.get(col) or ""
            for part in re.split(r"[;\s]+", v):
                k = norm_doi(part) or part.strip().lower()
                if k: keys.add(k)
    return keys

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--max-hits", type=int, default=1000, help="records kept per (source, term query)")
    ap.add_argument("--author-max", type=int, default=100, help="records kept per (source, author)")
    ap.add_argument("--no-authors", action="store_true")
    ap.add_argument("--sources", default="", help="comma list; default all")
    a = ap.parse_args()
    want = set(a.sources.split(",")) if a.sources else None

    counts, hits = [], []
    def run(name, fn, q, kind, cap):
        total, recs = paged(fn, q, cap)
        counts.append({"source": name, "query": q, "query_kind": kind, "hit_count": "" if total is None else total,
                       "kept": len(recs), "status": "error" if total is None else "ok"})
        for r in recs: hits.append({**r, "query": q, "query_kind": kind})
        print(f"{name:20s} {kind:6s} {q[:40]:40s} {total} kept {len(recs)}", file=sys.stderr)

    for name, fn in SOURCES.items():
        if want and name not in want: continue
        for q in QUERIES:
            run(name, fn, TERM_Q.get(name, lambda x: x)(q), "term", a.max_hits)
    if not a.no_authors:
        authors = seed_authors()
        print(f"{len(authors)} seed authors", file=sys.stderr)
        for name, mk in AUTHOR_Q.items():
            if want and name not in want: continue
            for n in authors:
                run(name, SOURCES[name], mk(n), "author", a.author_max)
    if not want or "neon" in want:
        total, recs = neon()
        counts.append({"source": "neon", "query": "(product catalogue, organismal products)", "query_kind": "catalogue",
                       "hit_count": total, "kept": len(recs), "status": "ok"})
        for r in recs: hits.append({**r, "query": "catalogue", "query_kind": "catalogue"})

    for h in hits: h["doi_norm"] = norm_doi(h.get("doi"))
    with open(os.path.join(HERE, "hit_counts.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["source", "query", "query_kind", "hit_count", "kept", "status"]); w.writeheader(); w.writerows(counts)
    fields = ["source", "query", "query_kind", "title", "url", "doi", "doi_norm", "license", "year", "extra"]
    with open(os.path.join(HERE, "raw_hits.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields); w.writeheader(); w.writerows(hits)

    # Backlog: one row per distinct deposit (Zenodo mirrors of Dryad share the DOI), not yet triaged.
    seen, back = triaged_keys(), {}
    for h in hits:
        k = deposit_key(h)
        if not k or k in seen: continue
        b = back.setdefault(k, {"key": k, "title": h["title"], "sources": set(), "urls": set(), "queries": set(),
                                "license": h["license"], "year": h["year"], "extra": h["extra"]})
        b["sources"].add(h["source"]); b["urls"].add(h["url"] or ""); b["queries"].add(f'{h["query_kind"]}:{h["query"]}')
        if not b["license"]: b["license"] = h["license"]
    rows = [{**b, "n_queries": len(b["queries"]), "sources": ";".join(sorted(b["sources"])),
             "urls": " ".join(sorted(u for u in b["urls"] if u)), "queries": " | ".join(sorted(b["queries"]))[:500]}
            for b in back.values()]
    rows.sort(key=lambda r: -r["n_queries"])
    bf = ["key", "title", "sources", "n_queries", "queries", "license", "year", "urls", "extra"]
    with open(os.path.join(HERE, "backlog.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=bf, extrasaction="ignore"); w.writeheader(); w.writerows(rows)
    print(f"{len(hits)} hits, {len({deposit_key(h) for h in hits})} deposits, {len(rows)} untriaged -> discovery/backlog.csv", file=sys.stderr)

if __name__ == "__main__":
    main()
