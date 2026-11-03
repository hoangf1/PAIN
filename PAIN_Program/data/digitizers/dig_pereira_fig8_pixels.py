import numpy as np, math, sys
from PIL import Image
from scipy import ndimage as nd
# Usage (from rea-work): python data/digitizers/dig_pereira_fig8_pixels.py references/Pereira.pdf data/pereira/pereira_fig8_directivity.csv data/pereira/qa/pereira_fig8_pixels_overlay.png
# Needs: pymupdf, numpy, scipy, Pillow. Reads the embedded Fig. 8 image (PDF p. 9, image xref 44) at its native resolution.
import io, pymupdf
_pdf=pymupdf.open(sys.argv[1]); _img=_pdf.extract_image(44)
a=np.asarray(Image.open(io.BytesIO(_img['image'])).convert('RGB')).astype(int)
R,G,B=a[:,:,0],a[:,:,1],a[:,:,2]
masks={'Experimental':(B>140)&(R<90)&(G>60)&(G<170),
       'Numerical':(R>110)&(G<90)&(B<110)&(R-G>70),
       'BEMT':(R<70)&(G<70)&(B<70)}
panels={1:(88.5,384.5,60),2:(720.5,383.5,50),3:(1353.5,383.5,40),4:(88.5,1212.5,20),5:(720.5,1212.5,20),6:(1353.5,1213.0,20)}
Rpx=343.5; span=30.0
out=[]
for h,(cx,cy,r0) in panels.items():
    for s,m in masks.items():
        sub=np.zeros_like(m); 
        y0,y1=int(cy-Rpx-40),int(cy+Rpx+40); x0,x1=int(cx+3),int(cx+Rpx+120)
        sub[y0:y1,x0:x1]=m[y0:y1,x0:x1]
        er=nd.binary_opening(sub,structure=np.ones((5,5)))
        lab,n=nd.label(er)
        for i in range(1,n+1):
            ys,xs=np.where(lab==i)
            if len(ys)<15: continue
            x,y=xs.mean(),ys.mean()
            dx,dy=x-cx,cy-y; r=math.hypot(dx,dy); th=math.degrees(math.atan2(dy,dx))
            out.append((h,s,round(th,1),round(r0+r/Rpx*span,2),round(x),round(y),len(ys)))


H_,W_=R.shape
yy,xx=np.mgrid[0:H_,0:W_]
res={}
for h,(cx,cy,r0) in panels.items():
    dx=xx-cx; dy=cy-yy; rr=np.hypot(dx,dy); th=np.degrees(np.arctan2(dy,dx))
    for s,m in masks.items():
        for k in range(-20,41,10):
            w=m&(np.abs(th-k)<2.2)&(rr>5)&(rr<Rpx+60)&(xx>cx+2)
            # also require blob thickness: opening with 3x3
            w=nd.binary_opening(w,structure=np.ones((3,3)))
            r=rr[w]
            if len(r)<8: res[(h,s,k)]=(None,len(r)); continue
            hist,edges=np.histogram(r,bins=np.arange(0,Rpx+62,3))
            sm=np.convolve(hist,np.ones(5),'same'); i=sm.argmax()
            sel=(r>edges[i]-9)&(r<edges[i]+12)
            rm=r[sel].mean()
            res[(h,s,k)]=(round(r0+rm/Rpx*span,2),int(sel.sum()))



# ---- final table
import csv, sys
OUT=sys.argv[2]
rows=[]
raw_override={(1,'Numerical',0):'Experimental',(1,'Numerical',20):'Experimental',(1,'BEMT',20):'Experimental',(1,'BEMT',40):'Experimental',
              (2,'Numerical',10):'Experimental',(6,'BEMT',-10):'Numerical',(6,'BEMT',20):'Numerical'}
manual={(1,'BEMT',30):(83.75,'partly hidden under Experimental marker; ±1 dB'),(2,'BEMT',30):(63.6,'partly hidden; read at inner edge of the visible marker; ±1 dB')}
qa=[]
for h,(cx,cy,r0) in panels.items():
    for k in range(-20,41,10):
        rec={'BPF':h,'Angle_deg':k}; flags=[]
        for s in ['BEMT','Numerical','Experimental']:
            v,n=res[(h,s,k)]
            if (h,s,k) in manual: v,f=manual[(h,s,k)]; flags.append(f'{s}: {f}')
            elif (h,s,k) in raw_override:
                dx=xx-cx; dy=cy-yy; rr=np.hypot(dx,dy); th=np.degrees(np.arctan2(dy,dx))
                w=masks[s]&(np.abs(th-k)<1.2)&(rr>5)&(rr<Rpx+60)&(xx>cx+2)
                v=round(r0+np.median(rr[w])/Rpx*span,2); flags.append(f'{s}: marker hidden under {raw_override[(h,s,k)]}; value from the visible line ends at the marker; ±1 dB')
            elif v is None:
                if h==6 and s=='Experimental': flags.append(f'{s}: beyond outer ring (>{r0+span:.0f} dB), not readable')
                elif h==3 and s=='BEMT': flags.append(f'{s}: below inner limit (<{r0:.0f} dB), drawn at the centre, not readable')
                else: flags.append(f'{s}: not found')
            rec[s+'_dB']='' if v is None else f'{float(v):.1f}'
            if v is not None:
                rad=(float(v)-r0)/span*Rpx; qa.append((cx+rad*math.cos(math.radians(k)), cy-rad*math.sin(math.radians(k)), s))
        rec['inner_dB']=r0; rec['outer_dB']=r0+span; rec['flags']='; '.join(flags)
        rows.append(rec)
hdr=["# Source: Pereira et al., Aerosp. Sci. Technol. 177 (2026) 112963, Fig. 8 (a)-(f), BPF harmonics 1-6, PDF p. 9 (printed p. 9)",
"# Method: pixel digitization of the embedded figure image (1808 x 1656 px, xref 44) by script data/digitizers/dig_pereira_fig8_pixels.py; centre and outer ring of each panel from the grey axis lines (outer radius 343.5 px = 30 dB); centre value from the panel's SPL labels (a 60, b 50, c 40, d-f 20 dB); markers found by colour (BEMT black, Numerical red, Experimental blue) in a +-2.2 deg wedge at each microphone angle",
"# Uncertainty: about +-0.3 dB for visible markers (centroid +-1.5 px, calibration +-1 px); +-1 dB where flagged as hidden; angles found at -20..40 deg within 0.3 deg",
"# Digitized 2026-10-21 by Claude at the author's request; replaces the author's Fig 8a-8f files. QA overlay data/pereira/qa/pereira_fig8_pixels_overlay.png",
"# Conventions: SPL in dB as plotted (tonal, phase-lock averaged); Angle_deg = microphone angle phi, 0 = rotation plane, positive downstream (Fig. 2b); check: phi = 0 values agree with Fig. 9 bars within about 1 dB for H1-H3"]
with open(OUT,'w',newline='') as f:
    f.write('\n'.join(hdr)+'\n')
    w=csv.DictWriter(f,fieldnames=['BPF','Angle_deg','BEMT_dB','Numerical_dB','Experimental_dB','inner_dB','outer_dB','flags']); w.writeheader(); w.writerows(rows)
from PIL import ImageDraw
im=Image.open(io.BytesIO(_img['image'])).convert('RGB'); d=ImageDraw.Draw(im)
col={'BEMT':(0,200,0),'Numerical':(255,140,0),'Experimental':(255,0,255)}
for x,y,s in qa: d.ellipse((x-9,y-9,x+9,y+9),outline=col[s],width=3)
im.save(sys.argv[3])
