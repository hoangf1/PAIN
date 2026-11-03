import csv, numpy as np, collections
rows=list(csv.DictReader(open('pereira_fig7_digitized.csv')))
D=collections.defaultdict(list)
for r in rows: D[(r['panel'],r['phi_deg'],r['series'])].append((float(r['propeller_phase_angle_deg']),float(r['p_prime_Pa'])))
clean=[];summ=[]
grid=np.arange(0,360.0001,1.0)
for k,v in sorted(D.items()):
    v=np.array(sorted(v)); th,p=v[:,0],v[:,1]
    # reject outliers vs running median
    from numpy.lib.stride_tricks import sliding_window_view
    w=9
    pad=np.pad(p,(w//2,w//2),mode='edge'); med=np.median(sliding_window_view(pad,w),axis=1)
    ok=np.abs(p-med)<0.06
    th,p=th[ok],p[ok]
    if k[2]=='BEMT':
        e=(th>3)&(th<357); th,p=th[e],p[e]
        for _ in range(5):
            t0=np.deg2rad(th); M0=np.column_stack([np.ones_like(t0)]+[f(kk*2*t0) for kk in (1,2) for f in (np.cos,np.sin)])
            c0,*_=np.linalg.lstsq(M0,p,rcond=None); keep=np.abs(p-M0@c0)<0.03
            th,p=th[keep],p[keep]
    pg=np.interp(grid,th,p)           # interpolate gaps
    # require coverage: fraction of 1-deg bins with a source point within 3 deg
    cov=np.mean([np.min(np.abs(th-g))<=3 for g in grid])
    for g,val in zip(grid,pg): clean.append((k[0],k[1],k[2],g,round(val,4)))
    t=np.deg2rad(grid[:-1]); y=pg[:-1]
    M=np.column_stack([np.ones_like(t)]+[f(kk*2*t) for kk in (1,2) for f in (np.cos,np.sin)])
    c,*_=np.linalg.lstsq(M,y,rcond=None)
    res=[k[0],k[1],k[2],round(cov,3),round(c[0],4)]
    for i,kk in enumerate((1,2)):
        a,b=c[1+2*i],c[2+2*i]; A=np.hypot(a,b); psi=np.degrees(np.arctan2(b,a))%360   # p=A cos(kB th - psi)
        res+= [round(A,4),round(psi,1)]
    rms=np.sqrt(np.mean((y-M@c)**2)); res.append(round(rms,4)); summ.append(res)
with open('pereira_fig7_digitized_clean_1deg.csv','w',newline='') as f:
    w=csv.writer(f); w.writerow(['panel','phi_deg','series','propeller_phase_angle_deg','p_prime_Pa']); w.writerows(clean)
hdr=['panel','phi_deg','series','coverage','mean_Pa','H1_amp_Pa','H1_phase_deg','H2_amp_Pa','H2_phase_deg','fit_rms_Pa']
with open('pereira_fig7_harmonics.csv','w',newline='') as f:
    w=csv.writer(f); w.writerow(hdr); w.writerows(summ)
for r in summ: print(r)
