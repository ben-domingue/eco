import json, urllib.request, time
UA={'User-Agent':'eco (https://github.com/ben-domingue/eco)'}
def get(u):
    for i in range(5):
        try: return json.load(urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=60))
        except Exception as e: time.sleep(3)
    raise
out=[];off=0
while True:
    d=get(f"https://api.gbif.org/v1/dataset/search?type=SAMPLING_EVENT&limit=1000&offset={off}")
    out+=d['results']; off+=1000
    if d['endOfRecords'] or off>=d['count']: break
print(len(out))
json.dump(out,open('se_datasets.json','w'))
