import sys,json,time,os
from playwright.sync_api import sync_playwright
JS="""async ([i,maxR,capMs])=>{
 const G=window.__g,T=window.__t,K=6,MAXD=170;
 G.loop.stop();G.scene.render=()=>{};
 const rn=performance.now.bind(performance);let now=1000;performance.now=()=>now;const dn=Date.now;Date.now=()=>1.7e12+now;const step=()=>{now+=1000/60;G.step(now,1000/60)};
 const ACTS=[[0,1,0],[0,1,1],[0,0,0],[0,0,1],[1,0,0],[1,0,1]];
 const sc=()=>G.scene.getScene('Game');
 function start(){const s=sc();s.p=null;s.won=false;s.dead=false;G.scene.start('Game',{i,fresh:true});
   for(let n=0;n<20&&!(s.p&&s.p.body);n++)step();}
 function run(P){start();for(let c=0;c<P.length;c++){const a=ACTS[P[c]];T.l=!!a[0];T.r=!!a[1];T.j=!!a[2];
   for(let f=0;f<K;f++){step();const s=sc();if(s.won)return{w:1};if(s.dead)return{d:1}}}
   const b=sc().p.body;return{x:b.x,y:b.y,vy:b.velocity.y}}
 const end=rn()+capMs,vis=new Set();let P=[],d=0,R=0,maxd=0,bestP=[],far=-1;const nxt=[0];
 while(R<maxR&&rn()<end){
  if(d>=MAXD||nxt[d]>=6){if(d==0)break;d--;continue}
  const a=nxt[d]++;P[d]=a;const res=run(P.slice(0,d+1));R++;
  if(res.w){const sol=P.slice(0,d+1);const v=run(sol);let tr=[];if(i==2){run(sol.slice(0,0));const q=sc();T.r=true;T.l=T.j=false;for(let n=0;n<230&&!q.won&&!q.dead;n++){step();if(n%10==0){const b=q.p.body;tr.push([n,b.x|0,b.y|0,q.ts[0].o.y|0,+q.ts[0].kill].join(':'))}}}
   return{ok:!!v.w,tr:tr.join(' '),chunks:sol.length,replays:R,sol,ons:sc().ts.map(t=>+t.on).join(''),deaths:sc().registry.get('deaths')}}
  if(res.d)continue;
  const key=d+':'+(res.x/12|0)+','+(res.y/12|0)+','+Math.round(res.vy/250);
  if(vis.has(key))continue;vis.add(key);d++;nxt[d]=0;maxd=Math.max(maxd,d);if(res.x>far){far=res.x;bestP=P.slice(0,d+1)};
 }
 const r=run(bestP);const q=sc();const tr=[];for(let n=0;n<60&&!q.dead&&!q.won;n++){step();if(n%6==0)tr.push((q.p.x|0)+','+(q.p.y|0))}
 const b=q.p.body,cul=q.ts.filter(t=>t.kill&&!(t.o.x>b.x+b.width||t.o.x+(t.d.r[2])<b.x||t.o.y>b.y+b.height||t.o.y+t.d.r[3]<b.y)).map(t=>t.d.t);
 return{ok:false,replays:R,far,cul,tr:tr.join(' '),end:{x:q.p.x|0,y:q.p.y|0,dead:q.dead,gf:q.gf,y2:b.y|0}};}"""
lv=[int(x) for x in sys.argv[1:]] or list(range(18))
with sync_playwright() as p:
    b=p.chromium.launch(args=['--no-sandbox']);pg=b.new_page();pg.set_default_timeout(0)
    for i in lv:
        pg.goto('http://localhost:4173/?test');pg.wait_for_function('window.__g&&window.__g.isBooted')
        t=time.time();r=pg.evaluate(JS,[i,int(os.environ.get('MAXR',3000)),int(os.environ.get('CAP',40000))])
        if i==2:
            r['probe']=pg.evaluate('''()=>{const G=window.__g,T=window.__t;let n=1e4;const st=()=>{n+=16.7;G.step(n,16.7)};const s0=G.scene.getScene('Game');s0.p=null;s0.dead=false;G.scene.start('Game',{i:2,fresh:true});for(let k=0;k<20&&!(s0.p&&s0.p.body);k++)st();T.r=true;T.l=T.j=false;const s=G.scene.getScene('Game');let dead=0;for(let k=0;k<300;k++){st();if(s.dead){dead=k;break}}return{dead,won:s.won,x:s.p.x|0,blk:[s.ts[0].on,s.ts[0].kill,s.ts[0].o.y|0]}}''')
        r.pop('sol',None);print(i+1,r,round(time.time()-t,1),'s',flush=True)
    b.close()
