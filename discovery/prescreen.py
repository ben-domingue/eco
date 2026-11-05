#!/usr/bin/env python3
"""Stage 1 of backlog triage: no model calls.

Reads discovery/backlog.csv (written by eco_discover.py), fetches what the
repository APIs serve anonymously and cheaply (Dryad dataset metadata and file
list; Zenodo record metadata and file list; title only elsewhere), applies
keyword and file-type rules, and writes discovery/cards.csv: one compact card
(<= ~450 characters of evidence) per deposit with a rule decision.

  rule_reject   obvious non-survey deposit (genomics, phylogeny, isotopes, rasters,
                images, code-only) with no survey signal anywhere in its metadata
  card          everything else; stage 2 (a cheap agent, cards in batches) sorts
                these into candidate / reject / needs-look

Rules only reject; they never accept. A rule_reject is reversible: it is listed
in cards.csv with the rule that fired, and stage 2 can be pointed at a sample.

Usage: python3 discovery/prescreen.py [--limit N]
"""
import argparse, csv, os, re, sys, urllib.parse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from eco_discover import http, norm_doi, HERE

NEG = re.compile(r"genom|sequenc|transcript|phylogen|isotop|microsatellite|\bsnps?\b|\brna\b|gene expression|"
                 r"metabolom|proteom|fossil|morphometr|physiolog|respirom|\bqtl\b|methylat|hormone|"
                 r"stomach content|diet analysis|thermal tolerance|common garden|greenhouse|mesocosm|"
                 r"lab(oratory)? experiment|simulation", re.I)
POS = re.compile(r"occupan|detect|point.?count|camera.?trap|transect|survey|capture|recapture|resight|"
                 r"mark.?recapture|visit|occasion|n-mixture|abundance|monitoring|census|plot|quadrat|"
                 r"trap(s|ping)?\b|acoustic|edna|presence|absence|species richness|community", re.I)
DEAD_EXT = {"fasta", "fa", "fas", "fastq", "nex", "nexus", "tre", "tree", "newick", "phy", "vcf", "bam", "sam",
            "gb", "tif", "tiff", "jpg", "jpeg", "png", "nc", "shp", "shx", "dbf", "prj", "pdf", "docx", "pptx"}
CODE_EXT = {"r", "py", "jl", "stan", "jags", "bug", "m", "cpp", "rmd", "qmd", "ipynb"}
TABULAR = {"csv", "txt", "tsv", "xlsx", "xls", "rds", "rdata", "rda", "inp", "json", "dat", "zip", "sqlite", "ods"}

def strip_html(s):
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", s or "")).strip()

def dryad_meta(doi):
    enc = urllib.parse.quote("doi:" + doi, safe="")
    d = http(f"https://datadryad.org/api/v2/datasets/{enc}")
    if "_error" in d: return None
    ver = d.get("_links", {}).get("stash:version", {}).get("href", "")
    files = http(f"https://datadryad.org{ver}/files", {"per_page": 100}) if ver else {}
    fl = [(f.get("path", ""), f.get("size") or 0) for f in files.get("_embedded", {}).get("stash:files", [])]
    text = strip_html((d.get("abstract") or "") + " " + (d.get("methods") or ""))
    return {"license": d.get("license", ""), "text": text, "files": fl, "keywords": ";".join(d.get("keywords") or [])}

def zenodo_meta(url):
    m = re.search(r"zenodo\.org/records?/(\d+)", url or "")
    if not m: return None
    d = http(f"https://zenodo.org/api/records/{m.group(1)}")
    if "_error" in d: return None
    md = d.get("metadata", {})
    fl = [(f.get("key", ""), f.get("size") or 0) for f in d.get("files", [])]
    lic = md.get("license", {}); lic = lic.get("id", "") if isinstance(lic, dict) else str(lic)
    return {"license": lic, "text": strip_html(md.get("description")), "files": fl,
            "keywords": ";".join(md.get("keywords") or [])}

def ext(p):
    return p.rsplit(".", 1)[-1].lower() if "." in p else ""

def decide(title, meta):
    blob = " ".join([title, meta.get("text", "") if meta else "", meta.get("keywords", "") if meta else ""])
    files = meta.get("files", []) if meta else []
    exts = {ext(p) for p, _ in files if not p.lower().startswith("readme")}
    pos, neg = bool(POS.search(blob)), NEG.search(blob)
    if files and exts and exts <= (DEAD_EXT | CODE_EXT):
        return "rule_reject", "files: " + ",".join(sorted(exts)) + " (no tabular data)"
    if neg and not pos:
        return "rule_reject", "keyword: " + neg.group(0).lower()
    return "card", ""

STRONG = re.compile(r"occupan|detection.?(history|histories|/non)|non.?detection|point.?count|camera.?trap|"
                    r"capture.?(history|histories|recapture)|mark.?recapture|resight|n-mixture|repeated (counts|surveys|visits)|"
                    r"encounter histor|transect counts?|breeding bird", re.I)

def score(title, meta, n_queries):
    """Rank cards so a capped stage 2 sees the likeliest survey deposits first."""
    blob = " ".join([title, (meta or {}).get("text", ""), (meta or {}).get("keywords", "")])
    exts = {ext(p) for p, _ in (meta or {}).get("files", [])}
    return (3 * len(set(m.group(0).lower() for m in STRONG.finditer(blob)))
            + len(set(m.group(0).lower() for m in POS.finditer(blob)))
            + (2 if exts & TABULAR else 0) + min(int(n_queries or 1), 5))

def card_text(title, meta):
    if not meta: return title[:200]
    files = sorted(meta["files"], key=lambda x: -x[1])[:8]
    fs = ", ".join(f"{p} ({s // 1000}kB)" for p, s in files)
    return f"{title[:160]} || files: {fs[:180]} || {meta['text'][:220]}"

def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--limit", type=int, default=0); ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--out", default="cards.csv", help="file name in discovery/"); a = ap.parse_args()
    rows = list(csv.DictReader(open(os.path.join(HERE, "backlog.csv"), newline="", encoding="utf-8")))
    rows = rows[a.offset:]
    if a.limit: rows = rows[:a.limit]
    out = []
    for i, r in enumerate(rows):
        doi, meta = norm_doi(r["key"]), None
        if doi.startswith(("10.5061/dryad", "10.25338/", "10.7291/", "10.6078/", "10.6086/", "10.15146/")) or "dryad" in r["sources"]:
            meta = dryad_meta(doi) if doi else None
        if meta is None and "zenodo" in r["sources"]:
            for u in r["urls"].split():
                if "zenodo" in u: meta = zenodo_meta(u); break
        dec, why = decide(r["title"], meta)
        out.append({"key": r["key"], "decision": dec, "rule": why, "score": score(r["title"], meta, r["n_queries"]), "sources": r["sources"], "n_queries": r["n_queries"],
                    "license": (meta or {}).get("license") or r["license"], "card": card_text(r["title"], meta),
                    "url": r["urls"].split()[0] if r["urls"] else ""})
        if i % 50 == 0: print(f"{i}/{len(rows)}", file=sys.stderr)
    out.sort(key=lambda o: (o["decision"] != "card", -o["score"]))
    f = ["key", "decision", "rule", "score", "sources", "n_queries", "license", "url", "card"]
    with open(os.path.join(HERE, a.out), "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=f); w.writeheader(); w.writerows(out)
    n = sum(o["decision"] == "card" for o in out)
    print(f"{len(out)} deposits: {n} cards for stage 2, {len(out) - n} rule_reject -> discovery/" + a.out, file=sys.stderr)

if __name__ == "__main__":
    main()
