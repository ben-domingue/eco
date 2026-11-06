import json,re,glob,csv
R='/home/ben/eco-b45/'
txt=''
for f in ['queue/candidates.csv','queue/human_review.csv','discovery_log.csv','dictionary/dictionary_auto.csv']+glob.glob('output/*__dataset.json')+glob.glob('data/*.R'):
    txt+=open(R+f,errors='ignore').read().lower()+'\n'
dois=set(re.findall(r'10\.\d{4,9}/[^\s",;)\]]+',txt))
dois={d.rstrip('.').rstrip('/') for d in dois}
uuids=set(re.findall(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',txt))
se={d['key']:d for d in json.load(open('se_datasets.json'))}
ab={}
for lic in ['CC0_1_0','CC_BY_4_0']:
    for c in json.load(open(f'absent_{lic}.json'))['facets'][0]['counts']: ab[c['name']]=(c['count'],lic)
rows=[];seen=0
for k,(n,lic) in ab.items():
    if k not in se: continue
    d=se[k]; doi=(d.get('doi') or '').lower()
    if k in uuids or (doi and doi in dois): seen+=1; continue
    rows.append(dict(key=k,doi=doi,title=d['title'],lic=lic,absent=n,pub=d.get('publishingOrganizationTitle',''),country=d.get('publishingCountry','')))
rows.sort(key=lambda r:-r['absent'])
print('already',seen,'new',len(rows))
json.dump(rows,open('new_se.json','w'),indent=0)
