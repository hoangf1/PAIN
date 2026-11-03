import cv2, numpy as np, csv
img=cv2.imread('per-000.png'); rgb=img[:,:,::-1].astype(int); qa=img.copy()
R,G,B=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
blk=(np.maximum(np.maximum(R,G),B)<80)
red=((R-G)>80)&(R>110)
xl,xr,y0,y1=1031.5,1703.0,536.5,16.5
out=[]
for px in range(1036,1701,3):
    r=np.where(blk[20:530,px])[0]+20; q=np.where(red[20:530,px])[0]+20
    if len(r)==0 or len(q)==0: continue
    rr=(px-xl)/(xr-xl)*0.7+0.3
    chord=(y0-np.median(r))/(y0-y1)*0.25
    twist=(y0-np.median(q))/(y0-y1)*45
    out.append((round(rr,4),round(chord,5),round(twist,3)))
    cv2.circle(qa,(px,int(np.median(r))),2,(0,255,0),-1); cv2.circle(qa,(px,int(np.median(q))),2,(255,0,255),-1)
with open('pereira_fig1b_chord_twist.csv','w',newline='') as f:
    w=csv.writer(f); w.writerow(['r_over_R','c_over_R','twist_deg']); w.writerows(out)
print(len(out)); 
for r in out[::25]: print(r)
cv2.imwrite('/sessions/modest-vigilant-allen/mnt/outputs/qa/per_fig1b_overlay.png',qa[:, 880:1800])
