import cv2,numpy as np
def shape_templates(shape,R=7.5,t=2.6,pad=4):
    n=int(2*(R+pad))+1; c=n//2
    yy,xx=np.mgrid[0:n,0:n]; dx=xx-c; dy=yy-c
    if shape=='circle':
        d=np.hypot(dx,dy); outer=d<=R; inner=d<=R-t
    elif shape=='square':
        h=R*0.92; outer=(abs(dx)<=h)&(abs(dy)<=h); inner=(abs(dx)<=h-t)&(abs(dy)<=h-t)
    elif shape=='diamond':
        h=R*1.25; outer=(abs(dx)+abs(dy)<=h); inner=(abs(dx)+abs(dy)<=h-t*1.41)
    elif shape=='triangle':
        # apex up; centroid at centre
        h=R*1.35; 
        top=-h*0.9; bot=h*0.55
        # width at y: proportional
        frac=np.clip((dy-top)/(bot-top),0,1)
        halfw=frac*h*0.95
        outer=(dy>=top)&(dy<=bot)&(abs(dx)<=halfw)
        frac2=np.clip((dy-(top+t*2.2))/(bot-t-(top+t*2.2)),0,1)
        inner=(dy>=top+t*2.2)&(dy<=bot-t)&(abs(dx)<=frac2*h*0.95-t*1.1)
    ring=(outer&~inner).astype(np.float32); inn=inner.astype(np.float32)
    return ring,inn
def detect(gray,shape,box,thr=150,score_min=0.62,R=7.5,t=2.6):
    x0,y0,x1,y1=box; c=gray[y0:y1,x0:x1]
    mask=(c<thr).astype(np.float32)
    ring,inn=shape_templates(shape,R,t)
    rc=cv2.filter2D(mask,-1,ring/ring.sum(),borderType=cv2.BORDER_CONSTANT)
    ie=1-cv2.filter2D(mask,-1,inn/inn.sum(),borderType=cv2.BORDER_CONSTANT)
    sc=np.minimum(rc,ie*1.0)
    res=[]
    s=sc.copy()
    while True:
        i=np.unravel_index(np.argmax(s),s.shape)
        if s[i]<score_min: break
        res.append((i[1]+x0,i[0]+y0,float(s[i]),float(rc[i]),float(ie[i])))
        yy,xx=i; s[max(0,yy-12):yy+13,max(0,xx-12):xx+13]=0
    return res

def score_maps(gray,box,thr=190,R=7.0,t=2.4):
    x0,y0,x1,y1=box; c=gray[y0:y1,x0:x1]
    mask=(c<thr).astype(np.float32)
    maps={}
    for s in ('circle','square','diamond','triangle'):
        ring,inn=shape_templates(s,R,t)
        rc=cv2.filter2D(mask,-1,ring/ring.sum(),borderType=cv2.BORDER_CONSTANT)
        ie=1-cv2.filter2D(mask,-1,inn/inn.sum(),borderType=cv2.BORDER_CONSTANT)
        maps[s]=np.minimum(rc,ie)
    return maps
def refine(maps,box,x,y,w=7):
    """best (shape,x,y,score) within +-w px of approx (x,y) in full-image coords"""
    x0,y0,_,_=box
    best=None
    for s,m in maps.items():
        xa,ya=int(round(x-x0)),int(round(y-y0))
        sub=m[max(0,ya-w):ya+w+1,max(0,xa-w):xa+w+1]
        if sub.size==0: continue
        i=np.unravel_index(np.argmax(sub),sub.shape)
        sc=float(sub[i])
        # subpixel: score-weighted centroid around peak
        yy,xx=i[0]+max(0,ya-w),i[1]+max(0,xa-w)
        pat=m[max(0,yy-2):yy+3,max(0,xx-2):xx+3]; ys,xs=np.mgrid[max(0,yy-2):yy+3,max(0,xx-2):xx+3]
        wgt=np.clip(pat-0.5*pat.max(),0,None)
        cx=(wgt*xs).sum()/wgt.sum()+x0; cy=(wgt*ys).sum()/wgt.sum()+y0
        if best is None or sc>best[3]: best=(s,cx,cy,sc)
    return best

# ---------------------------------------------------------------------------
# Driver: NACA Report 996 Figs. 12(a), 12(b), 13(a), 14(a) -> tr996_fig12_13a_14_digitized.csv
# Usage (from rea-work\data\report996): python tools/digitize_tr996.py "..\..\references\NASA Report 996.pdf"
# Method: render PDF pages at 300 dpi (pdftoppm), fit axes to the printed grid lines, locate hollow markers by
# ring-template matching around approximate positions chosen by eye (marker identity and the x = 0 curve
# assignment in Fig. 12b were checked visually against the curves), refine to sub-pixel, convert to data units.
# Needs: pdftoppm (poppler), numpy, opencv-python.
# ---------------------------------------------------------------------------
import sys, os, subprocess, csv, tempfile
def render(pdf,page,outdir):
    base=os.path.join(outdir,f'p{page}')
    subprocess.run(['pdftoppm','-r','300','-png','-f',str(page),'-l',str(page),pdf,base],check=True)
    f=[x for x in os.listdir(outdir) if x.startswith(f'p{page}') and x.endswith('.png')][0]
    return cv2.imread(os.path.join(outdir,f),0)
def main(pdf,out_csv,qa_dir):
    tmp=tempfile.mkdtemp(); rows=[]
    def add(fig,panel,qty,Mt,beta,x,mB,val,plotted='',scope=True):
        rows.append(dict(figure=fig,panel=panel,quantity=qty,M_t=Mt,beta_075R_deg=beta,x_over_D=x,harmonic_mB=mB,
                         value=round(val,1),units='dynes/cm2',plotted_M_t=plotted,in_scope=str(scope).lower()))
    def overlay(g,pts,box,name):
        x0,y0,x1,y1=box; v=cv2.cvtColor(g[y0:y1,x0:x1],cv2.COLOR_GRAY2BGR)
        for (x,y) in pts: cv2.circle(v,(int(x-x0),int(y-y0)),13,(0,0,255),2)
        cv2.imwrite(os.path.join(qa_dir,name),cv2.resize(v,None,fx=0.6,fy=0.6))
    # ---- Fig. 14(a): page 16, log-log
    g=render(pdf,16,tmp); box=(392,1380,820,2620); maps=score_maps(g,box,thr=190)
    xs=np.array([390,488,559,615,658,697,730,760,786.]);Ms=np.array([.2,.3,.4,.5,.6,.7,.8,.9,1.0])
    ax,bx=np.polyfit(np.log10(Ms),xs,1)
    ys=np.array([2602,2501,2433,2377,2332,2262,2207,2037,1643,1866,1812,1768,1697,1668.]);ps=np.array([20,30,40,50,60,80,100,200,1000,400,500,600,800,900.])
    ay,by=np.polyfit(np.log10(ps),ys,1)
    appr={2:[(586,2036),(660,1894),(714,1744),(760,1578),(786,1520)],4:[(588,2207),(660,2064),(714,1867),(761,1685),(787,1536)],6:[(586,2376),(658,2263),(714,2003),(758,1790),(787,1543)]}
    nom=[0.45,0.60,0.75,0.90,1.00]; pts=[]
    for mB,L in appr.items():
        for i,(x,y) in enumerate(L):
            s,cx,cy,sc=refine(maps,box,x,y); pts.append((cx,cy))
            add('14','a','p_harmonic',nom[i],10,-0.125,mB,10**((cy-by)/ay),round(10**((cx-bx)/ax),3),nom[i]<=0.9)
    overlay(g,pts,(380,1360,820,2640),'fig14a_overlay.png')
    # ---- Fig. 13(a): page 15, linear
    g=render(pdf,15,tmp); box=(200,1090,1200,2780); maps=score_maps(g,box,thr=190)
    vx=np.array([232,351,466,583,696,816,933,1050,1165.]);ax,bx=np.polyfit(-0.5+0.125*np.arange(9),vx,1)
    Hp=np.array([1119,1238,1354,1471,1589,1706,1823,1939,2056,2173,2290,2406,2524,2643,2760.]);ay,by=np.polyfit(np.arange(1400,-1,-100).astype(float),Hp,1)
    pts=[]
    for (x,y) in [(232,2172),(466,1586),(585,1204),(698,1865),(818,1579),(931,1781),(1163,2342)]:
        s,cx,cy,sc=refine(maps,box,x,y,w=8); pts.append((cx,cy))
        add('13','a','p_first_harmonic',0.75,15,round((cx-bx)/ax,3),2,(cy-by)/ay)
    overlay(g,pts,box,'fig13a_overlay.png')
    # ---- Fig. 12(a): page 13
    g=render(pdf,13,tmp); box=(1470,240,2470,1345); maps=score_maps(g,box,thr=205)
    vx=np.array([1500,1618,1735,1852,1968,2085,2202,2317,2432.]);ax,bx=np.polyfit(-0.25+0.0625*np.arange(9),vx,1)
    hp=np.array([264,383,496,615,734,849,967,1085,1203,1320.]);ay,by=np.polyfit(np.array([900,800,700,600,500,400,300,200,100,0.]),hp,1)
    A={2:[601,622,400,661,563],4:[251,400,321,592,384],6:[102,234,214,404,225],8:[69,158,181,233,155]}; pts=[]
    for mB,vals in A.items():
        for xs_,p in zip([-.25,-.125,0,.125,.25],vals):
            s,cx,cy,sc=refine(maps,box,ax*xs_+bx,ay*p+by,w=9); pts.append((cx,cy))
            add('12','a','p_harmonic',0.75,10,round((cx-bx)/ax,3),mB,(cy-by)/ay)
    overlay(g,pts,box,'fig12a_overlay.png')
    # ---- Fig. 12(b): page 14
    g=render(pdf,14,tmp); box=(260,1160,1330,2900); maps=score_maps(g,box,thr=225)
    vx=np.array([342,474,584,701,819,935,1046,1157,1274.]);ax,bx=np.polyfit(-0.25+0.0625*np.arange(9),vx,1)
    hp=np.array([1217,1332,1455,1578,1690,1810,1929,2043,2155,2278,2395,2517,2630,2751.]);ay,by=np.polyfit(np.arange(1400,0,-100).astype(float)[:14],hp,1)
    # approximate positions (mB, x/D, p). At x/D = 0 the curves cross; assignment by following the curves:
    # mB4 = 578 (V-shaped dip), mB6 = 678, mB8 = 626.
    B={2:[900,1300,790,1140,990],4:[650,850,578,990,790],6:[300,550,678,890,585],8:[250,500,626,640,385]}; pts=[]
    for mB,vals in B.items():
        for xs_,p in zip([-.25,-.125,0,.125,.25],vals):
            s,cx,cy,sc=refine(maps,box,ax*xs_+bx,ay*p+by,w=9); pts.append((cx,cy))
            add('12','b','p_harmonic',0.90,10,round((cx-bx)/ax,3),mB,(cy-by)/ay)
    overlay(g,pts,box,'fig12b_overlay.png')
    with open(out_csv,'w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
    print('wrote',len(rows),'rows to',out_csv)
if __name__=='__main__':
    pdf=sys.argv[1]; main(pdf,sys.argv[2] if len(sys.argv)>2 else 'tr996_fig12_13a_14_digitized.csv',sys.argv[3] if len(sys.argv)>3 else 'qa')
