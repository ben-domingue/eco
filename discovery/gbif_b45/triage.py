import json, urllib.request, time, re, html
from concurrent.futures import ThreadPoolExecutor
UA={'User-Agent':'eco (https://github.com/ben-domingue/eco)'}
def get(u):
    for i in range(5):
        try: return json.load(urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=120))
        except Exception as e: time.sleep(3*(i+1))
    return None
rows=json.load(open('new_se.json'))
def strip(s): return re.sub(r'\s+',' ',html.unescape(re.sub('<[^>]+>',' ',s or ''))).strip()
def one(r):
    k=r['key']
    d=get(f"https://api.gbif.org/v1/dataset/{k}") or {}
    o=get(f"https://api.gbif.org/v1/occurrence/search?datasetKey={k}&limit=1&facet=year&facet=eventId&facet=decimalLatitude&facet=decimalLongitude&facet=month&facetLimit=5000&facetMincount=1") or {}
    fac={f['field']:f['counts'] for f in o.get('facets',[])}
    ex=(o.get('results') or [{}])[0]
    r2=dict(r)
    r2.update(license=d.get('license'),
      description=strip(d.get('description'))[:1500],
      sampling=strip(' '.join((s.get('description') or '') if isinstance(s,dict) else str(s) for s in (d.get('samplingDescription',{}) or {}).values() if s))[:1500] if isinstance(d.get('samplingDescription'),dict) else '',
      methods=strip(json.dumps(d.get('samplingDescription',{})))[:2000],
      temporal=json.dumps(d.get('temporalCoverages',[]))[:300],
      endpoints=[e.get('url') for e in d.get('endpoints',[]) if e.get('type')=='DWC_ARCHIVE'],
      n_occ=o.get('count'),
      n_years=len(fac.get('YEAR',[])), years=sorted(int(x['name']) for x in fac.get('YEAR',[])),
      n_events=len(fac.get('EVENT_ID',[])),
      n_lat=len(fac.get('DECIMAL_LATITUDE',[])), n_lon=len(fac.get('DECIMAL_LONGITUDE',[])),
      n_months=len(fac.get('MONTH',[])),
      ex={x:ex.get(x) for x in ['eventID','parentEventID','locationID','eventDate','samplingProtocol','sampleSizeValue','sampleSizeUnit','organismQuantity','organismQuantityType','occurrenceStatus','kingdom','class','order','country','locality','fieldNumber']})
    return r2
with ThreadPoolExecutor(6) as ex: out=list(ex.map(one,rows))
json.dump(out,open('triage_raw.json','w'),indent=0)
print(len(out))
