# EDITO / EMODnet Biology EurOBIS occurrence parquet (2026-09-30 snapshot, anonymous S3 on CloudFerro): profile the
# datasets that carry occurrenceStatus = absent (events, taxa, sites, events per site, duplicate event x taxon rows) and
# look each up in IMIS (title, licence, DOI). Run 2026-11-11; triaged into discovery/edito_eurobis_absent_2026-11-11.csv.
# Streams ~1.5 GB; ~13 min. The IMIS lookup needs `x.get("dois") or []` (some records have none).
import pyarrow.parquet as pq, pyarrow.fs as pfs, pyarrow.compute as pc, pyarrow as pa, pandas as pd, time, json, urllib.request
from collections import defaultdict
SP="./"   # directory holding absent_by_dataset.csv (per-dataset absent counts from a first full pass over the parquet)
ab=pd.read_csv(SP+"absent_by_dataset.csv",index_col=0); ids=set(ab.index.astype(int))
fs=pfs.S3FileSystem(anonymous=True, endpoint_override="https://s3.waw3-1.cloudferro.com", region="waw3-1")
P="emodnet/emodnet_biology/12639/marine_biodiversity_observations_occurrence_2026-09-30.parquet"
pf=pq.ParquetFile(P, filesystem=fs)
ev=defaultdict(set); tx=defaultdict(set); site=defaultdict(set); siteev=defaultdict(set); yrs=defaultdict(set); prot={}; et={}; dup=defaultdict(int); ndate=defaultdict(int)
t0=time.time()
for b in pf.iter_batches(batch_size=1_000_000, columns=["IMISDatasetId","eventID","eventIDLevel2","eventDate","aphiaidaccepted","decimalLatitude","decimalLongitude","samplingProtocol","eventType","occurrenceStatus"]):
    m=pc.is_in(b.column("IMISDatasetId"), value_set=pa.array(list(ids),type=b.column("IMISDatasetId").type))
    t=b.filter(m)
    if t.num_rows==0: continue
    d=t.to_pandas()
    d["s"]=d.decimalLatitude.round(4).astype(str)+","+d.decimalLongitude.round(4).astype(str)
    for k,g in d.groupby("IMISDatasetId"):
        ev[k].update(g.eventID.dropna().map(hash)); tx[k].update(g.aphiaidaccepted.dropna().astype(int))
        site[k].update(g.s); siteev[k].update((g.s+"|"+g.eventID.fillna("")).map(hash))
        yrs[k].update(g.eventDate.dropna().astype(str).str.slice(0,4)); ndate[k]+=int(g.eventDate.notna().sum())
        p=g.samplingProtocol.dropna()
        if len(p) and k not in prot: prot[k]=p.iloc[0][:120]
        e=g.eventType.dropna()
        if len(e) and k not in et: et[k]=e.iloc[0]
        dup[k]+=int(g.duplicated(["eventID","aphiaidaccepted"]).sum())
print("scan secs",round(time.time()-t0),flush=True)
rows=[]
for k in sorted(ids):
    y=sorted(x for x in yrs[k] if x.isdigit())
    rows.append(dict(imis=k,n=int(ab.loc[k,"n"]),absent=int(ab.loc[k,"absent"]),events=len(ev[k]),taxa=len(tx[k]),sites=len(site[k]),
        ev_per_site=round(len(siteev[k])/max(1,len(site[k])),1),dup_event_taxon=dup[k],date_frac=round(ndate[k]/ab.loc[k,"n"],2),
        y0=y[0] if y else "",y1=y[-1] if y else "",nyears=len(y),protocol=prot.get(k,""),eventType=et.get(k,"")))
out=pd.DataFrame(rows)
# IMIS lookups
def imis(k):
    try:
        d=json.load(urllib.request.urlopen(urllib.request.Request(f"https://www.vliz.be/en/imis?module=dataset&dasid={k}&show=json",headers={"User-Agent":"eco (https://github.com/ben-domingue/eco)"}),timeout=60))
        r=d.get("datasetrec",{}); dois=[x.get("DOI") for x in (d.get("dois") or []) if x.get("DOI")]
        return dict(title=r.get("StandardTitle") or r.get("EngTitle"),licence=r.get("License") or "",access=r.get("AccessConstraint") or "",doi=dois[0] if dois else "",citation=(r.get("Citation") or "")[:300])
    except Exception as e: return dict(title="ERR "+str(e)[:60])
info=[]
for k in out.imis: info.append(imis(k)); time.sleep(0.5)
out=pd.concat([out,pd.DataFrame(info)],axis=1)
out.to_csv("edito_absent_profile.csv",index=False); print("done",len(out),flush=True)
