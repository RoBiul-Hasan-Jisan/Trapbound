import Phaser from 'phaser';
import {LEVELS,R,Trap} from './levels';
import {save,store,beep,touch} from './core';
import {C,WORLD,WORLDS,RM,TEST,txt,btn,card,backdrop} from './ui';
const DEBUG=location.search.includes('debug');
const I=Phaser.Geom.Intersects.RectangleToRectangle;
const Rc=(x:number,y:number,w:number,h:number)=>new Phaser.Geom.Rectangle(x,y,w,h);
const BG=[74,61,130];
// Procedural 24x32 "man" icon, 4 poses (same size as the physics hitbox).
function makeMan(s:Phaser.Scene){
  if(s.textures.exists('man_idle'))return;
  const poses:Record<string,number[][]>={
    man_idle:[[12,12,6,20],[12,12,18,20],[12,21,8,31],[12,21,16,31]],
    man_run1:[[12,12,5,17],[12,12,19,21],[12,21,4,29],[12,21,18,31]],
    man_run2:[[12,12,19,17],[12,12,5,21],[12,21,20,29],[12,21,6,31]],
    man_jump:[[12,12,4,6],[12,12,20,6],[12,21,6,28],[12,21,18,28]]};
  for(const k in poses){const g=s.add.graphics();g.lineStyle(3,0xffe3b0).fillStyle(0xffe3b0);
    g.fillCircle(12,6,5.5);g.lineBetween(12,11,12,21);poses[k].forEach(l=>g.lineBetween(l[0],l[1],l[2],l[3]));
    g.fillStyle(0x2a2547);g.fillCircle(14,5,1.2);g.generateTexture(k,24,32);g.destroy()}
}
const fade=(s:Phaser.Scene,ms=300)=>{if(!RM&&!TEST)s.cameras.main.fadeIn(ms,BG[0],BG[1],BG[2])};

export class Menu extends Phaser.Scene{
  constructor(){super('Menu')}
  create(){
    backdrop(this,8);fade(this,350);
    const title=txt(this,480,84,'Trapbound',84,C.roseS,'800').setShadow(0,5,'#140a2866',10,false,true);
    if(!RM)this.tweens.add({targets:title,y:92,yoyo:true,repeat:-1,duration:2600,ease:'Sine.inOut'});
    makeMan(this);const m=this.add.sprite(760,98,'man_idle').setScale(2.5);
    this.tweens.add({targets:m,x:870,yoyo:true,repeat:-1,duration:1800,ease:'Sine.inOut',onYoyo:()=>m.setFlipX(true),onRepeat:()=>m.setFlipX(false)});
    this.time.addEvent({delay:130,loop:true,callback:()=>m.setTexture(m.texture.key=='man_run1'?'man_run2':'man_run1')});
    txt(this,480,142,"tread lightly… not everything is as it seems",19,C.mute,'600');
    txt(this,480,172,`${save.done.length} of ${LEVELS.length} levels cleared`,16,C.mute,'700').setAlpha(.8);
    btn(this,480,240,380,68,save.unlocked>0?'Continue':'Play',()=>this.scene.start('Game',{i:Math.min(save.unlocked,LEVELS.length-1),fresh:true}),{kind:'primary',color:C.rose});
    btn(this,480,330,320,68,'Levels',()=>this.scene.start('Levels'));
    const lbl=()=>'Sound: '+(save.sound?'on':'off');
    const snd=btn(this,310,425,300,68,lbl(),()=>{save.sound=!save.sound;store();snd.setText(lbl())},{size:24});
    btn(this,650,425,300,68,'Fullscreen',()=>{this.scale.toggleFullscreen();try{Promise.resolve((screen.orientation as any).lock('landscape')).catch(()=>{})}catch{}},{size:24});
    txt(this,480,505,matchMedia('(pointer:coarse)').matches?'◀ ▶ move  ·  ▲ jump  ·  II pause':'A/D or ←/→ move  ·  W/↑/Space jump  ·  R restart  ·  Esc pause',16,C.mute,'600').setAlpha(.85);
  }
}
export class Levels extends Phaser.Scene{
  w=0;constructor(){super('Levels')}
  init(d:{w?:number}){this.w=d?.w??Math.min(2,Math.floor(Math.min(save.unlocked,LEVELS.length-1)/10))}
  create(){
    backdrop(this,6);fade(this,250);
    const w=this.w,N=['The Warm-Up','False Confidence','Reality Glitch'],col=WORLD,hex=WORLDS[w];
    const done=[...Array(10).keys()].filter(k=>save.done.includes(w*10+k)).length;
    txt(this,480,44,`World ${w+1} · ${N[w]}`,34,hex,'800');
    txt(this,480,84,`${done} of 10 cleared`,16,C.mute,'700');
    const bar=this.add.graphics(),bw=240;
    bar.fillStyle(0xffffff,.14).fillRoundedRect(480-bw/2,102,bw,12,6);
    if(done)bar.fillStyle(col[w],1).fillRoundedRect(480-bw/2,102,Math.max(12,bw*done/10),12,6);
    [-1,1].forEach(dw=>{const nw=w+dw;if(nw<0||nw>2)return;const x=480+dw*420;
      btn(this,x,270,84,180,dw<0?'◀':'▶',()=>this.scene.restart({w:nw}),{size:36})});
    for(let k=0;k<10;k++){const i=w*10+k,ok=i<=save.unlocked,d=save.done.includes(i),x=480+((k%5)-2)*150,y=205+Math.floor(k/5)*115;
      const g=this.add.graphics(),L=x-67,T=y-48;
      g.fillStyle(0x140a28,.25).fillRoundedRect(L,T+4,134,96,22);
      if(ok){g.fillStyle(d?C.mint:0xffffff,d?.26:.14).fillRoundedRect(L,T,134,96,22);
        g.lineStyle(2.5,d?C.mint:col[w],.9).strokeRoundedRect(L,T,134,96,22)}
      else g.fillStyle(0xffffff,.06).fillRoundedRect(L,T,134,96,22);
      if(ok){const hit=this.add.rectangle(x,y,134,96,0xffffff,.001).setInteractive({useHandCursor:true});
        hit.on('pointerdown',()=>this.scene.start('Game',{i,fresh:true}));
}
      if(ok){txt(this,x,y,String(k+1),38,d?C.mintS:'#ffffff','800');if(d)txt(this,x+44,y-28,'✓',20,C.mintS)}
      else txt(this,x,y,'🔒',28,'#ffffff').setAlpha(.45)}
    btn(this,480,470,260,64,'Back',()=>this.scene.start('Menu'),{size:24});
  }
}
type S={d:Trap;o:any;on:boolean;kill:boolean;trig?:R};
export class Game extends Phaser.Scene{
  i=0;clk=0;gf=1;dead=false;won=false;paused=false;rev=0;coy=0;buf=0;jp=false;
  p!:Phaser.GameObjects.Sprite;plats!:Phaser.Physics.Arcade.StaticGroup;ex!:Phaser.GameObjects.Rectangle;
  pt!:Phaser.GameObjects.Container;dbg?:Phaser.GameObjects.Text;ts:S[]=[];movers:any[]=[];k:any;
  constructor(){super('Game')}
  pb(){return this.p.body as Phaser.Physics.Arcade.Body}
  door(x:number,y:number){
    if(!TEST){const gl=this.add.image(x+16,y+24,'glow').setTint(C.mint).setDisplaySize(130,130).setAlpha(.45);
      if(!RM)this.tweens.add({targets:gl,alpha:.75,scale:gl.scale*1.15,yoyo:true,repeat:-1,duration:1400,ease:'Sine.inOut'})}
    return this.add.rectangle(x,y,32,48,C.mint).setOrigin(0).setStrokeStyle(3,0x4fbf93)}
  create(d:{i:number;fresh?:boolean}){
    this.i=d.i;if(d.fresh||this.registry.get('deaths')==null)this.registry.set('deaths',0);
    Object.assign(this,{dead:false,won:false,paused:false,clk:0,gf:1,rev:0,coy:0,buf:0,jp:false,ts:[],movers:[]});
    backdrop(this,5);if(d.fresh)fade(this,350);
    const L=LEVELS[this.i];
    this.physics.world.setBoundsCollision(true,true,false,false);
    const box=(r:R,c:number)=>this.add.rectangle(r[0],r[1],r[2],r[3],c).setOrigin(0);
    const solid=(r:R)=>{const o=box(r,0xb7a3e6).setStrokeStyle(2,0xf0eaff);this.physics.add.existing(o,true);this.plats.add(o);return o};
    this.plats=this.physics.add.staticGroup();
    L.plats.forEach(solid);
    for(const d of L.traps){
      const [x,y,w,h]=d.r;let o:any;
      const s:S={d,o:null,on:false,kill:false,trig:d.trig||((d.t=='collapse'||d.t=='vanish')?[x,y-6,w,8]:undefined)};
      if(d.t=='spike')o=this.add.triangle(x,y+h,0,h,w/2,0,w,h,0xff8fa3).setOrigin(0).setAlpha(0);
      else if(d.t=='collapse'||d.t=='vanish')o=solid(d.r);
      else if(d.t=='block')o=box(d.r,0xc9b8f2).setStrokeStyle(2,0xf0eaff);
      else if(d.t=='fake'){o=this.door(x,y);s.kill=true}
      else if(d.t=='saw'){o=this.add.star(x+w/2,y+h/2,8,10,20,0xffc27a).setStrokeStyle(2,0xfff0d0);s.kill=true;
        this.tweens.add({targets:o,angle:360,repeat:-1,duration:600});
        this.tweens.add({targets:o,x:d.to![0]+w/2,y:d.to![1]+h/2,yoyo:true,repeat:-1,ease:'Sine.inOut',
          duration:Math.hypot(d.to![0]-x,d.to![1]-y)/(d.v||120)*1000})}
      else if(d.t=='timed')o=box(d.r,0xff8fa3).setAlpha(.25);
      else if(d.t=='wall'){o=box(d.r,0xff7a93);s.kill=true;this.tweens.add({targets:o,x:d.to![0],y:d.to![1],yoyo:true,repeat:-1,ease:'Sine.inOut',hold:300,repeatDelay:300,
        duration:Math.hypot(d.to![0]-x,d.to![1]-y)/(d.v||120)*1000})}
      else if(d.t=='mover'){o=box(d.r,0x8fb4ff).setStrokeStyle(2,0xd0e0ff);this.physics.add.existing(o);o.d=d;
        (o.body as Phaser.Physics.Arcade.Body).setAllowGravity(false).setImmovable(true).setVelocityX(d.v||100);this.movers.push(o)}
      s.o=o;this.ts.push(s);
      if(DEBUG&&s.trig)this.add.rectangle(s.trig[0],s.trig[1],s.trig[2],s.trig[3]).setOrigin(0).setStrokeStyle(1,0x00ff88);
    }
    this.ex=this.door(L.exit[0],L.exit[1]);
    makeMan(this);this.p=this.add.sprite(L.spawn[0],L.spawn[1],'man_idle').setDepth(5);
    this.physics.add.existing(this.p);
    this.pb().setCollideWorldBounds(true).setMaxVelocity(260,900).setDragX(1500);
    this.physics.add.collider(this.p,this.plats);this.physics.add.collider(this.p,this.movers);
    // HUD: soft frosted pills
    const hud={fontFamily:"Nunito,Quicksand,'Trebuchet MS',ui-rounded,system-ui,sans-serif",fontSize:'16px',fontStyle:'700',color:'#c9bde0'};
    const pill=(t:Phaser.GameObjects.Text)=>{this.add.graphics().setDepth(9).fillStyle(0x1b1530,.4).fillRoundedRect(t.x-t.displayOriginX-12,t.y-t.displayOriginY-5,t.width+24,t.height+10,14)};
    const lv=this.add.text(84,13,`${Math.floor(this.i/10)+1}-${this.i%10+1}  ${L.name}`,hud).setDepth(10).setColor(WORLDS[Math.floor(this.i/10)]);pill(lv);
    const dt=this.add.text(936,13,'oops '+this.registry.get('deaths'),hud).setOrigin(1,0).setDepth(10);pill(dt);
    const pb=this.add.circle(36,36,28,0xffffff,.16).setStrokeStyle(2,0xffffff,.32).setDepth(10).setInteractive().on('pointerdown',()=>this.pause(!this.paused));
    this.add.graphics().setDepth(11).fillStyle(0xfdf6ff,1).fillRoundedRect(27,26,6,20,3).fillRoundedRect(39,26,6,20,3);
    const pc=this.add.container(0,0).setDepth(30).setVisible(false);this.pt=pc;
    pc.add(this.add.rectangle(480,270,960,540,0x140a28,.62).setInteractive());
    card(this,480,262,420,460,.7,0xffffff,pc);
    pc.add(txt(this,480,92,'Paused',42,C.ink,'800'));
    const sl=()=>'Sound: '+(save.sound?'on':'off');let st:Phaser.GameObjects.Text;
    const items:[string,()=>void][]=[['Resume',()=>this.pause(false)],['Restart',()=>{this.pause(false);this.scene.restart({i:this.i})}],
      [sl(),()=>{save.sound=!save.sound;store();st.setText(sl())}],['Menu',()=>{this.pause(false);this.scene.start('Menu')}]];
    items.forEach(([t,f],k)=>{const y=175+k*85;
      const tx=btn(this,480,y,340,68,t,f,{kind:k==0?'primary':'ghost',color:C.mint,size:26,into:pc});if(k==2)st=tx});
    if(DEBUG)this.dbg=this.add.text(12,50,'',hud);
    this.k=this.input.keyboard!.addKeys('A,D,W,SPACE,LEFT,RIGHT,UP,R,ESC,M');
    const hid=()=>{if(!this.dead&&!this.won&&!this.paused)this.pause(true)};this.game.events.on('hidden',hid);this.events.once('shutdown',()=>this.game.events.off('hidden',hid));
  }
  pause(on:boolean){this.paused=on;on?this.physics.pause():this.physics.resume();
    on?this.tweens.pauseAll():this.tweens.resumeAll();this.time.paused=on;this.pt.setVisible(on)}
  msg(t:string){const m=txt(this,480,84,t,22,C.gold,'800').setDepth(15).setShadow(0,2,'#140a2899',6,false,true);
    this.tweens.add({targets:m,alpha:0,y:64,duration:1700,onComplete:()=>m.destroy()})}
  fire(s:S){s.on=true;const{d,o}=s,[x,y,w,h]=d.r;beep(300,.12,'sine',-120);
    d.chain?.forEach((j,n)=>this.time.delayedCall(250*(n+1),()=>{const t=this.ts[j];if(t&&!t.on)this.fire(t)}));
    if(d.t=='spike'){s.kill=true;o.setAlpha(1);this.tweens.add({targets:o,y,duration:80})}
    else if(d.t=='block'){s.kill=true;this.tweens.add({targets:o,y:d.to![1],duration:220,ease:'Quad.In'})}
    else if(d.t=='grav'){this.gf=d.v!;this.pb().setGravityY(this.gf<0?-3000:0);this.p.setFlipY(this.gf<0);
      this.msg(this.gf<0?'Whoa, gravity flipped!':'Gravity is back to normal');if(!RM)this.cameras.main.flash(150,156,200,255)}
    else if(d.t=='rev'){this.rev=3000;this.msg('Oops, controls reversed!')}
    else if(d.t=='collapse'||d.t=='vanish'){
      const gone=d.t=='vanish';
      if(!gone)this.tweens.add({targets:o,x:x+3,yoyo:true,repeat:5,duration:40});
      this.time.delayedCall(gone?350:260,()=>{(o.body as Phaser.Physics.Arcade.StaticBody).enable=false;
        this.tweens.add({targets:o,alpha:0,y:gone?y:y+400,duration:gone?150:500})})}
  }
  hb(s:S){const o=s.o,[,,w,h]=s.d.r;return s.d.t=='saw'?Rc(o.x-14,o.y-14,28,28):Rc(o.x+3,o.y+3,w-6,h-6)}
  update(_:number,dt:number){
    const K=this.k,J=Phaser.Input.Keyboard.JustDown;
    if(J(K.ESC)&&!this.dead&&!this.won)this.pause(!this.paused);
    if(this.paused){if(J(K.M)){this.pause(false);this.scene.start('Menu')}
      if(J(K.R)){this.pause(false);this.scene.restart({i:this.i})}return}
    if(J(K.R)){this.scene.restart({i:this.i});return}
    if(this.dead||this.won)return;
    const b=this.pb();
    let dir=((K.D.isDown||K.RIGHT.isDown||touch.r)?1:0)-((K.A.isDown||K.LEFT.isDown||touch.l)?1:0);
    if(this.rev>0){dir=-dir;this.rev-=dt;if(this.rev<=0)this.msg('Controls restored')}
    b.setAccelerationX(dir*1800);
    const gr=this.gf>0?(b.blocked.down||b.touching.down):(b.blocked.up||b.touching.up);this.coy=gr?100:this.coy-dt;
    const jd=K.W.isDown||K.UP.isDown||K.SPACE.isDown||touch.j;
    this.buf=(jd&&!this.jp)?120:this.buf-dt;this.jp=jd;
    if(this.buf>0&&this.coy>0){b.setVelocityY(-560*this.gf);this.buf=this.coy=0;beep(420,.09,'sine',260)}
    if(!jd&&b.velocity.y*this.gf<-220)b.setVelocityY(-220*this.gf);
    this.p.setTexture(!gr?'man_jump':Math.abs(b.velocity.x)>40?((this.clk/110|0)%2?'man_run1':'man_run2'):'man_idle');
    if(b.velocity.x<-10)this.p.setFlipX(true);else if(b.velocity.x>10)this.p.setFlipX(false);
    for(const m of this.movers){const v=Math.abs(m.d.v||100),mb=m.body as Phaser.Physics.Arcade.Body;
      if(m.x<=m.d.r[0])mb.setVelocityX(v);else if(m.x>=m.d.to[0])mb.setVelocityX(-v)}
    this.clk+=dt;const pr=Rc(b.x,b.y,b.width,b.height);
    for(const s of this.ts){
      if(s.d.t=='timed'){s.kill=(this.clk+s.d.to![0])%s.d.v!<s.d.v!/2;s.o.setAlpha(s.kill?1:.25)}
      if(!s.on&&s.trig&&I(pr,Rc(...s.trig)))this.fire(s);
      if(s.kill&&I(pr,this.hb(s))){this.die();return}
    }
    if(b.y>570||b.y<-90){this.die();return}
    if(I(pr,Rc(this.ex.x,this.ex.y,32,48)))this.win();
    this.dbg?.setText(`L${this.i} x${b.x|0} y${b.y|0} traps:${this.ts.map(s=>+s.on).join('')}`);
  }
  die(){
    if(this.dead||this.won)return;this.dead=true;
    this.registry.set('deaths',this.registry.get('deaths')+1);
    beep(190,.3,'triangle',-110);navigator.vibrate?.(40);
    for(let n=0;n<12;n++){const q=this.add.circle(this.p.x,this.p.y,Phaser.Math.Between(3,5),n%2?0xffe3b0:0xff9eb5);
      this.tweens.add({targets:q,x:q.x+Phaser.Math.Between(-70,70),y:q.y+Phaser.Math.Between(-70,40),alpha:0,scale:.3,duration:400,onComplete:()=>q.destroy()})}
    this.p.setVisible(false);this.pb().enable=false;
    if(!RM)this.cameras.main.shake(120,.004);
    this.time.delayedCall(350,()=>this.scene.restart({i:this.i}));
  }
  win(){
    if(this.won||this.dead)return;this.won=true;this.pb().setVelocity(0,0).setAcceleration(0,0);
    if(!save.done.includes(this.i))save.done.push(this.i);
    save.unlocked=Math.max(save.unlocked,Math.min(this.i+1,LEVELS.length-1));store();
    beep(520,.4,'triangle',500);
    this.tweens.add({targets:this.ex,scaleX:.15,yoyo:true,duration:250});
    const pn=card(this,480,270,380,150,.65,C.mint).setDepth(19);
    const t1=txt(this,480,244,'Nicely done!',44,C.mintS,'800').setDepth(20),
      t2=txt(this,480,298,`level cleared  ·  oops ${this.registry.get('deaths')}`,20,C.ink,'700').setDepth(20);
    if(!RM){[pn,t1,t2].forEach(o=>{o.setAlpha(0);this.tweens.add({targets:o,alpha:1,duration:250})});
      const cols=[0xff9eb5,0xffc9a3,0x9ff0c8,0x9cc8ff,0xc9a8ff,0xffe3b0];
      for(let n=0;n<26;n++){const c=this.add.rectangle(Phaser.Math.Between(40,920),-10,Phaser.Math.Between(6,10),Phaser.Math.Between(4,7),cols[n%6]).setDepth(18);
        this.tweens.add({targets:c,y:560,x:c.x+Phaser.Math.Between(-60,60),angle:Phaser.Math.Between(-360,360),duration:Phaser.Math.Between(1100,1900),delay:Phaser.Math.Between(0,300),onComplete:()=>c.destroy()})}}
    this.time.delayedCall(1200,()=>this.i+1<LEVELS.length?this.scene.start('Game',{i:this.i+1,fresh:true}):this.scene.start('Menu'));
  }
}
