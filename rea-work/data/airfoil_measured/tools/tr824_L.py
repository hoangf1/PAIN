import sys, os, json, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw
from tr824 import *
g=np.array(Image.open('work/tr824_p143.png').convert('L')).astype(float)
for k in range(33):
    x=int(round(614.5+k*(1802.5-614.5)/32)); g[:,x-2:x+3]=255
for k in range(57):
    y=int(round(262+k*(2329-262)/56)); g[y-2:y+3,:]=255
box=(830,900,1660,1840); maps=score_maps(g,box)
px=lambda a:614.5+(a+32)*(1802.5-614.5)/64; py=lambda c:262+(3.6-c)*(2329-262)/5.6
ax=lambda x:-32+(x-614.5)*64/(1802.5-614.5); cl=lambda y:3.6-(y-262)*5.6/(2329-262)
z=lambda X,Y:(1360+X/3,940+Y/3)
pts=[]
stall={"Re9e6":("diamond",[(75,390),(185,213),(300,95),(345,92),(430,103),(480,125),(545,118),(660,265)]),
       "Re6e6":("square",[(190,240),(305,155),(365,135),(432,177),(545,320),(662,470)]),
       "Re3e6":("circle",[(70,483),(188,350),(262,265),(305,272),(370,335),(430,402),(540,477),(655,540)])}
for re,(shape,L) in stall.items():
    for X,Y in L:
        x,y=z(X,Y); s,cx,cy,sc=refine(maps,box,x,y,w=8,shapes=[shape]); pts.append((re,s,cx,cy,sc))
lin=[(222,860),(262,785),(296,705),(335,625),(373,540),(407,463),(446,385),(483,308),(518,232)]
for X,Y in lin:
    s,cx,cy,sc=refine(maps,box,830+X,900+Y,w=9,shapes=["circle","square","diamond"]); pts.append(("all",s,cx,cy,sc))
im=Image.open('work/tr824_p143.png').convert('RGB').crop(box); dr=ImageDraw.Draw(im)
col={'Re9e6':(0,0,255),'Re6e6':(0,160,0),'Re3e6':(255,0,0),'all':(200,0,200)}
out=[]
for re,s,cx,cy,sc in pts:
    X,Y=cx-box[0],cy-box[1]; dr.ellipse((X-12,Y-12,X+12,Y+12),outline=col[re],width=2)
    out.append(dict(Re=re,shape=s,alpha_deg=round(ax(cx),2),cl=round(cl(cy),4),score=round(sc,2)))
im.save('work/tr824_L_ref.png'); json.dump(out,open('work/tr824_L_ref.json','w'),indent=0)
for o in out: print(o)
