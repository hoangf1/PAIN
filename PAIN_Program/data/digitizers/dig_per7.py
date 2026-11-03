import cv2, numpy as np, csv, json
img=cv2.imread('per-005.png'); rgb=img[:,:,::-1].astype(int)
panels={'a_phi0':(125,857,50,600,0),'b_phi20':(1090,1822,50,600,20),'c_phi40':(607,1339,821,1371,40)}
cols={'BEMT':(0,0,0),'Numerical':(158,2,30),'Experimental':(8,111,188)}
out=[];qa=img.copy()
for pn,(x0,x1,y0,y1,phi) in panels.items():
    for sn,c in cols.items():
        R,G,B=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
        if sn=='BEMT': mask=(np.maximum(np.maximum(R,G),B)<95)&((np.maximum(np.maximum(R,G),B)-np.minimum(np.minimum(R,G),B))<40)
        elif sn=='Numerical': mask=((R-G)>70)&(R>105)&((R-B)>25)
        else: mask=((B-R)>75)&(B>125)
        pts=[]
        for px in range(x0+4,x1-3):
            rows=np.where(mask[y0+4:y1-3,px])[0]+y0+4
            if pn=='a_phi0' and px>655: rows=rows[rows>130]
            if len(rows)==0: continue
            # keep the largest connected cluster (line) -> median
            groups=np.split(rows,np.where(np.diff(rows)>3)[0]+1)
            g=max(groups,key=len)
            if sn=='BEMT' and len(g)>12: continue
            py=np.median(g)
            th=(px-x0)/(x1-x0)*360; p=1-2*(py-y0)/(y1-y0)
            pts.append((th,p,px,py))
        for th,p,px,py in pts: out.append((pn,phi,sn,round(th,2),round(p,4)))
        col={'BEMT':(0,255,0),'Numerical':(0,255,255),'Experimental':(255,0,255)}[sn]
        for th,p,px,py in pts[::6]: cv2.circle(qa,(int(px),int(py)),2,col,-1)
        print(pn,sn,len(pts),'of',x1-x0-7)
with open('pereira_fig7_digitized.csv','w',newline='') as f:
    w=csv.writer(f); w.writerow(['panel','phi_deg','series','propeller_phase_angle_deg','p_prime_Pa']); w.writerows(out)
cv2.imwrite('/sessions/modest-vigilant-allen/mnt/outputs/qa/per_fig7_overlay.png',qa)
