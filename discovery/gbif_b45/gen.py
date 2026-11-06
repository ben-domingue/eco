import json, csv, re, sys
sys.path.insert(0,'.')
from credible import C, DONANA, HOLD
T=json.load(open('triage_raw.json'))
PLANK=set('Bacillariophyceae Dinophyceae Copepoda Cyanobacteriia Bacteria Alphaproteobacteria Gammaproteobacteria Trebouxiophyceae Prymnesiophyceae Oligotrichea Kinetoplastea Conjugatophyceae Chrysophyceae Eurotatoria Branchiopoda Prostomatea Chromadorea Hydrozoa Tentaculata Nuda Thaliacea Scyphozoa Tremellomycetes'.split())
def decide(t):
    i=t['i']; y=t['years']; r=t['n_events']/max(t['n_lat'],1); cap=t['n_events']>=5000
    title=t['title']
    if i in C: return 'queued', C[i][3]
    if i in DONANA: return 'queued','merged into the Doñana track-count row'
    if i in HOLD: return 'held', HOLD[i]
    if re.match(r'NEON ',title): return 'rejected','duplicate: NEON products are built from the NEON API (batches 36, 38)'
    if 'Swedish National Forest Inventory' in title: return 'held','as batch 42 (doi:10.15468/b9c3d7): no plot id; plots linkable only through obfuscated coordinates'
    if 'by-nc' in (t['license'] or ''): return 'held','non-commercial licence (standing call)'
    if re.search(r'Reef Visual Census|National Coral Reef Monitoring Program: Assessment of fish',title): return 'rejected','one year per dataset, stratified-random PSUs not revisited (batch 42 RVC note)'
    if re.search(r'Coral Reef Evaluation and Monitoring Project',title): return 'not queued','fixed CREMP stations but one dataset per year; a multi-dataset merge for a later batch'
    if re.search(r'TPWD HARC',title): return 'rejected','stratified-random sampling stations, not revisited'
    if re.search(r'Research Vessel|RV Surveys|trawl|Trawl',title): return 'rejected','research-vessel stations not revisited as fixed locations'
    if re.search(r'landings|Landings',title): return 'rejected','fishery landings, not a survey'
    if re.search(r'EDIA',title): return 'not queued','EDIA Alqueva bird monitoring split into many small per-group/per-year datasets; a family merge for a later batch'
    if re.search(r'occasional observations|collection|Collection|citizen science observations|Hunt|BioBlitz|Bioblitz|Theses|inventory|Inventory|Catalogue',title): return 'rejected','incidental records, collection or inventory, no survey design'
    if (t['n_occ'] or 0)==0: return 'rejected','no occurrences indexed'
    if t['n_lat']<=2 and not cap: return 'rejected','one or two locations only'
    if not cap and r<1.5: return 'rejected','single visit per location (events about equal to distinct coordinates)'
    if len(y)<=1: return 'rejected','one season only'
    cls=(t['ex'].get('class') or '')
    if cls in PLANK: return 'not queued','plankton, microbial or meiofauna sample series; outside this batch\'s priorities'
    return 'not queued','repeat sampling but not a priority taxon or design for this batch; read the archive before queueing'
rows=[]
for t in T:
    d,why=decide(t)
    y=t['years']
    rows.append(dict(gbif_key=t['key'],doi=t['doi'],title=t['title'],license=(t['license'] or '').replace('http://creativecommons.org/','').replace('/legalcode',''),
        publisher=t['pub'],country=t['country'],absent_occurrences=t['absent'],occurrences=t['n_occ'],years=f"{y[0]}-{y[-1]} ({len(y)})" if y else '',
        events=('>=5000' if t['n_events']>=5000 else t['n_events']),distinct_latitudes=('>=5000' if t['n_lat']>=5000 else t['n_lat']),decision=d,reason=why))
from collections import Counter
print(Counter(r['decision'] for r in rows))
with open('/home/ben/eco-b45/discovery/gbif_se_absent_b45.csv','w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
