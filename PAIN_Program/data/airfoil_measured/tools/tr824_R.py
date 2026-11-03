import sys, os, json, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw
from tr824 import *
g=np.array(Image.open('work/tr824_p143.png').convert('L')).astype(float)
bx=lambda v:2006+(v+1.5)*(3114-2006)/3.0; by=lambda v:1585.5-v*(1585.5-700.5)/0.024
for k in range(-16,17):
    x=int(round(bx(k/10))); g[:,x-2:x+3]=255
for k in range(0,25):
    y=int(round(by(k/1000))); g[y-2:y+3,:]=255
box=(2230,760,3160,1420); maps=score_maps(g,box)
icl=lambda x:-1.5+(x-2006)*3.0/(3114-2006); icd=lambda y:(1585.5-y)*0.024/(1585.5-700.5)
L={"Re3e6":("circle",[(75,402),(162,488),(232,534),(312,560),(396,562),(480,575),(548,570),(637,572),(712,510),(763,363),(818,224),(858,62)]),
   "Re6e6":("square",[(83,462),(157,526),(238,568),(318,590),(398,592),(480,600),(556,598),(642,590),(713,528),(785,426),(848,321),(897,186)]),
   "Re9e6":("diamond",[(80,500),(153,541),(232,578),(316,598),(394,600),(478,605),(555,605),(642,580),(713,520),(788,452),(852,357),(906,256)])}
im=Image.open('work/tr824_p143.png').convert('RGB').crop(box); dr=ImageDraw.Draw(im)
col={'Re9e6':(0,0,255),'Re6e6':(0,160,0),'Re3e6':(255,0,0)}; out=[]
for re,(shape,P) in L.items():
    for X,Y in P:
        s,cx,cy,sc=refine(maps,box,box[0]+X,box[1]+Y,w=9,shapes=[shape])
        x,y=cx-box[0],cy-box[1]; dr.ellipse((x-12,y-12,x+12,y+12),outline=col[re],width=2)
        out.append(dict(Re=re,shape=s,cl=round(icl(cx),4),cd=round(icd(cy),5),score=round(sc,2)))
im.save('work/tr824_R_ref.png'); json.dump(out,open('work/tr824_R_ref.json','w'),indent=0)
for o in out: print(o)
