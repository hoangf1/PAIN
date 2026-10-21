import pdfplumber, numpy as np, csv, re, os
M='/sessions/modest-vigilant-allen/mnt/PAIN/rea-work/Foil Geom for Wu (Russell).pdf'
rR=[0.1237,0.1650,0.2062,0.2475,0.2887,0.3300,0.3712,0.4124,0.4537,0.4949,0.5362,0.5774,0.6187,0.6599,0.7011,0.7424,0.7836,0.8249,0.8661,0.9074,0.9486,0.9899]
xin=[329.8,392.65,455.5,517.95]; xs=37.55; ys=37.35
y04=[86.33,138.49,190.9,243.06,295.48,347.63]
tab={}
for r in csv.DictReader(open('russell_table1.csv')): tab[int(r['section'])]=r
with pdfplumber.open(M) as pdf:
    p=pdf.pages[2]
    cs=[c for c in p.curves if c['x0']>285 and len(c['pts'])>=10]
os.makedirs('russ_sections',exist_ok=True)
allrows=[];summ=[]
for k in range(22):
    row,col=divmod(k,4)
    x0=xin[col]; yt=y04[row]
    pcs=[c for c in cs if x0-3<=c['x0']<=x0+39 and yt-4<=c['top']<=yt+39]
    pieces=[np.array([((x-x0)/xs, 0.4-(y-yt)/ys) for x,y in c['pts']]) for c in pcs]
    pieces=[q for q in pieces if q[:,1].min()>-0.3 and q[:,1].max()<0.3 and q[:,0].min()>-0.06 and q[:,0].max()<1.06]
    print(k+1,[len(q) for q in pieces])
    # chain
    chain=pieces.pop(0)
    while pieces:
        best=None
        for i,pc in enumerate(pieces):
            for rev in (False,True):
                q=pc[::-1] if rev else pc
                d=np.hypot(*(q[0]-chain[-1]))
                if best is None or d<best[0]: best=(d,i,rev)
        d,i,rev=best; q=pieces.pop(i); q=q[::-1] if rev else q
        chain=np.vstack([chain,q])
    # orientation: start TE upper -> LE -> lower
    xmin=chain[:,0].min(); xmax=chain[:,0].max()
    iLE=np.argmin(chain[:,0])
    # rotate chain so it starts at the max-x point of upper side
    n=len(chain)
    # find upper at mid chord
    def ymid(seg):
        m=np.abs(seg[:,0]-0.5)<0.05; return seg[m,1].mean() if m.any() else np.nan
    a=chain[:iLE+1]; b=chain[iLE:]
    if ymid(a)<ymid(b): chain=chain[::-1]
    # normalize chord to 1 using x range
    c=chain.copy(); c[:,0]=(c[:,0]-xmin)/(xmax-xmin); c[:,1]=c[:,1]/(xmax-xmin)
    # t/c
    up=c[:np.argmin(c[:,0])+1]; lo=c[np.argmin(c[:,0]):]
    xx=np.linspace(0.02,0.98,200)
    yu=np.interp(xx,up[::-1,0],up[::-1,1]); yl=np.interp(xx,lo[:,0],lo[:,1])
    tc=(yu-yl).max(); camb=((yu+yl)/2).max()
    sec=k+1; tr=tab[sec]
    summ.append((sec,rR[k],xmax-xmin,round(tc*100,2),float(tr['t_over_c_pct']),round(camb*100,2),len(c)))
    with open(f'russ_sections/section_{sec:02d}_rR{rR[k]:.4f}.csv','w',newline='') as f:
        w=csv.writer(f); w.writerow(['x_over_c','y_over_c']); w.writerows([(round(a,5),round(b,5)) for a,b in c])
    for a,b in c: allrows.append((sec,rR[k],round(a,5),round(b,5)))
for s in summ: print(s)
with open('russell_fig4_sections_all.csv','w',newline='') as f:
    w=csv.writer(f); w.writerow(['section','r_over_R','x_over_c','y_over_c']); w.writerows(allrows)
with open('russell_fig4_check.csv','w',newline='') as f:
    w=csv.writer(f); w.writerow(['section','r_over_R','x_span_unit_chord','tc_pct_from_outline','tc_pct_table1','max_camber_pct','n_points']); w.writerows(summ)
