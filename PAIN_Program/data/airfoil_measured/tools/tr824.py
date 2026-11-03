"""Marker detection for NACA TR 824 p. 141 (NACA 4412). Ring templates from data/report996/tools/digitize_tr996.py."""
import sys, json, numpy as np

def filter2D(a, k):
    """Correlation with zero padding (same size), via FFT; stands in for cv2.filter2D(BORDER_CONSTANT)."""
    H, W = a.shape; kh, kw = k.shape
    sh = (H + kh - 1, W + kw - 1)
    F = np.fft.rfft2(a, sh) * np.fft.rfft2(k[::-1, ::-1], sh)
    full = np.fft.irfft2(F, sh)
    return full[kh // 2:kh // 2 + H, kw // 2:kw // 2 + W]
def shape_templates(shape,R=10,t=3.0,pad=4):
    n=int(2*(R+pad))+1; c=n//2
    yy,xx=np.mgrid[0:n,0:n]; dx=xx-c; dy=yy-c
    if shape=='circle':
        d=np.hypot(dx,dy); outer=d<=R; inner=d<=R-t
    elif shape=='square':
        h=R*0.92; outer=(abs(dx)<=h)&(abs(dy)<=h); inner=(abs(dx)<=h-t)&(abs(dy)<=h-t)
    elif shape=='diamond':
        h=R*1.25; outer=(abs(dx)+abs(dy)<=h); inner=(abs(dx)+abs(dy)<=h-t*1.41)
    elif shape in ('triangle','vtriangle'):
        h=R*1.35; top=-h*0.9; bot=h*0.55
        frac=np.clip((dy-top)/(bot-top),0,1); halfw=frac*h*0.95
        outer=(dy>=top)&(dy<=bot)&(abs(dx)<=halfw)
        frac2=np.clip((dy-(top+t*2.2))/(bot-t-(top+t*2.2)),0,1)
        inner=(dy>=top+t*2.2)&(dy<=bot-t)&(abs(dx)<=frac2*h*0.95-t*1.1)
        if shape=='vtriangle': outer=outer[::-1]; inner=inner[::-1]
    return (outer&~inner).astype(np.float32), inner.astype(np.float32)
def score_maps(gray,box,thr=150,R=10,t=3.0):
    x0,y0,x1,y1=box; mask=(gray[y0:y1,x0:x1]<thr).astype(np.float32); maps={}
    for s in ('circle','square','diamond','triangle','vtriangle'):
        ring,inn=shape_templates(s,R,t)
        rc=filter2D(mask,ring/ring.sum())
        ie=1-filter2D(mask,inn/inn.sum())
        maps[s]=np.minimum(rc,ie)
    return maps
def refine(maps,box,x,y,w=8,shapes=None):
    x0,y0,_,_=box; best=None
    for s,m in maps.items():
        if shapes and s not in shapes: continue
        xa,ya=int(round(x-x0)),int(round(y-y0))
        sub=m[max(0,ya-w):ya+w+1,max(0,xa-w):xa+w+1]
        i=np.unravel_index(np.argmax(sub),sub.shape); sc=float(sub[i])
        yy,xx=i[0]+max(0,ya-w),i[1]+max(0,xa-w)
        pat=m[max(0,yy-2):yy+3,max(0,xx-2):xx+3]; ys,xs=np.mgrid[max(0,yy-2):yy+3,max(0,xx-2):xx+3]
        wgt=np.clip(pat-0.5*pat.max(),0,None)
        cx=(wgt*xs).sum()/wgt.sum()+x0; cy=(wgt*ys).sum()/wgt.sum()+y0
        if best is None or sc>best[3]: best=(s,float(cx),float(cy),sc)
    return best
def peaks(m,box,smin,sep=12):
    x0,y0,_,_=box; s=m.copy(); out=[]
    while True:
        i=np.unravel_index(np.argmax(s),s.shape)
        if s[i]<smin: break
        out.append((i[1]+x0,i[0]+y0,float(s[i]))); s[max(0,i[0]-sep):i[0]+sep+1,max(0,i[1]-sep):i[1]+sep+1]=0
    return out
