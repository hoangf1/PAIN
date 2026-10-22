import sys, numpy as np
from PIL import Image
g=np.array(Image.open(sys.argv[1]).convert('L')).astype(float); dark=g<140
def lines(box,axis,frac):
    x0,y0,x1,y1=box; sub=dark[y0:y1,x0:x1]
    prof=(sub.sum(0)/(y1-y0)) if axis=='v' else (sub.sum(1)/(x1-x0))
    idx=np.where(prof>frac)[0]+(x0 if axis=='v' else y0)
    out=[]
    for i in idx:
        if out and i-out[-1][-1]<=2: out[-1].append(i)
        else: out.append([i])
    return [round(float(np.mean(o)),1) for o in out]
for spec in sys.argv[2:]:
    name,b=spec.split('=');box=tuple(int(v) for v in b.split(','))
    print(name,'V',lines(box,'v',0.5)); print(name,'H',lines(box,'h',0.5))
