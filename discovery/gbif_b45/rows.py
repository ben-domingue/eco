import json,csv,sys
sys.path.insert(0,'.')
from credible import C, DONANA
T=json.load(open('triage_raw.json'))
R='/home/ben/eco-b45/'
lic=lambda t: 'CC0-1.0' if 'zero' in t['license'] else 'CC-BY-4.0'
cand=[];disc=[]
for i,(dt,diff,notes,status) in C.items():
    t=T[i]
    title=t['title']; doi='doi:'+t['doi']
    if i==385:
        title='Long-term monitoring of carnivore track counts in Doñana National Park 2007-2022 (9 GBIF datasets, one per taxon)'
        doi='doi:'+t['doi']+' (+ '+', '.join('doi:'+T[j]['doi'] for j in DONANA if j!=385)+')'
    y=t['years']
    n=f"batch 45 GBIF discovery (key {t['key']}): {t['absent']:,} occurrences ABSENT; {y[0] if y else ''}-{y[-1] if y else ''}, {('>=5000' if t['n_events']>=5000 else t['n_events'])} event ids, {('>=5000' if t['n_lat']>=5000 else t['n_lat'])} distinct latitudes; {notes}"
    st = status if not status.startswith('claimed') else 'available'
    cb = 'batch-45' if status.startswith('claimed') else ''
    cand.append([title,'gbif_sampling_event',doi,lic(t),dt,diff,n,st,cb])
    disc.append(['gbif_sampling_event','2026-11-06 batch 45: GBIF occurrence facet occurrenceStatus=ABSENT x license CC0/CC BY x dataset type SAMPLING_EVENT','',title,doi,lic(t),dt,'DwC-A event core + occurrence extension','dwca','yes (explicit absences)',diff,notes])
with open(R+'queue/candidates.csv','a',newline='') as f: csv.writer(f).writerows(cand)
with open(R+'discovery_log.csv','a',newline='') as f: csv.writer(f).writerows(disc)
print(len(cand))
