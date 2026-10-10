import Phaser from 'phaser';
import {LEVELS,R,Trap} from './levels';
import {save,store,beep,touch} from './core';
const DEBUG=location.search.includes('debug');
const RM=matchMedia('(prefers-reduced-motion: reduce)').matches;
const txt=(s:Phaser.Scene,x:number,y:number,t:string,sz=20,c='#e8e8f0')=>s.add.text(x,y,t,{fontFamily:'monospace',fontSize:sz+'px',color:c,align:'center'}).setOrigin(.5);
const I=Phaser.Geom.Intersects.RectangleToRectangle;
const Rc=(x:number,y:number,w:number,h:number)=>new Phaser.Geom.Rectangle(x,y,w,h);

export class Menu extends Phaser.Scene{
  constructor(){super('Menu')}
  create(){
    for(let i=0;i<5;i++){const r=this.add.rectangle(100+i*190,100+(i%2)*330,60,16,0x23232e);
      this.tweens.add({targets:r,y:r.y+(i%2?-60:60),yoyo:true,repeat:-1,duration:2500+i*300,ease:'Sine.inOut'})}
    txt(this,480,90,'TRAPBOUND',72,'#ff4d6d');
    txt(this,480,150,`Worlds 1–3 · ${save.done.length}/${LEVELS.length} cleared`,18,'#8a8aa0');
    const btn=(x:number,y:number,t:string,fn:()=>void,c=0x2a2a38,w=220)=>{
      this.add.rectangle(x,y,w,48,c).setInteractive({useHandCursor:true}).on('pointerdown',fn);return txt(this,x,y,t,22)};
    btn(480,230,'PLAY',()=>this.go(Math.min(save.unlocked,LEVELS.length-1)),0xff4d6d,280);
    txt(this,480,286,'LEVEL SELECT',16,'#8a8aa0');
    LEVELS.forEach((l,i)=>{const x=180+(i%6)*120,y=322+Math.floor(i/6)*56,ok=i<=save.unlocked;
      const r=this.add.rectangle(x,y,84,46,ok?(save.done.includes(i)?0x1f6f4a:0x2a2a38):0x16161c);
      if(ok)r.setInteractive({useHandCursor:true}).on('pointerdown',()=>this.go(i));
      txt(this,x,y,ok?String(i+1):'🔒',24,ok?'#fff':'#444')});
    const snd=btn(300,497,'',()=>{save.sound=!save.sound;store();snd.setText(lbl())},0x2a2a38,240);
    const lbl=()=>'SOUND: '+(save.sound?'ON':'OFF');snd.setText(lbl());
    btn(660,497,'FULLSCREEN',()=>this.scale.toggleFullscreen(),0x2a2a38,240);
    txt(this,480,527,'A/D or ←/→ move · W/↑/Space jump · R restart · Esc pause · Trust nothing.',14,'#8a8aa0');
  }
  go(i:number){this.scene.start('Game',{i,fresh:true})}
}

type S={d:Trap;o:any;on:boolean;kill:boolean;trig?:R};
export class Game extends Phaser.Scene{
  i=0;clk=0;gf=1;dead=false;won=false;paused=false;rev=0;coy=0;buf=0;jp=false;
  p!:Phaser.GameObjects.Rectangle;plats!:Phaser.Physics.Arcade.StaticGroup;ex!:Phaser.GameObjects.Rectangle;
  pt!:Phaser.GameObjects.Text;dbg?:Phaser.GameObjects.Text;ts:S[]=[];movers:any[]=[];k:any;
  constructor(){super('Game')}
  pb(){return this.p.body as Phaser.Physics.Arcade.Body}
  door(x:number,y:number){return this.add.rectangle(x,y,32,48,0x66ffaa).setOrigin(0).setStrokeStyle(3,0x1a7a52)}
  create(d:{i:number;fresh?:boolean}){
    this.i=d.i;if(d.fresh||this.registry.get('deaths')==null)this.registry.set('deaths',0);
    Object.assign(this,{dead:false,won:false,paused:false,clk:0,gf:1,rev:0,coy:0,buf:0,jp:false,ts:[],movers:[]});
    const L=LEVELS[this.i];
    this.physics.world.setBoundsCollision(true,true,false,false);
    const box=(r:R,c:number)=>this.add.rectangle(r[0],r[1],r[2],r[3],c).setOrigin(0);
    const solid=(r:R)=>{const o=box(r,0x3a3a4a);this.physics.add.existing(o,true);this.plats.add(o);return o};
    this.plats=this.physics.add.staticGroup();
    L.plats.forEach(solid);
    for(const d of L.traps){
      const [x,y,w,h]=d.r;let o:any;
      const s:S={d,o:null,on:false,kill:false,trig:d.trig||((d.t=='collapse'||d.t=='vanish')?[x,y-6,w,8]:undefined)};
      if(d.t=='spike')o=this.add.triangle(x,y+h,0,h,w/2,0,w,h,0xff4d6d).setOrigin(0).setAlpha(0);
      else if(d.t=='collapse'||d.t=='vanish')o=solid(d.r);
      else if(d.t=='block')o=box(d.r,0x4a4a5c);
      else if(d.t=='fake'){o=this.door(x,y);s.kill=true}
      else if(d.t=='saw'){o=this.add.star(x+w/2,y+h/2,8,10,20,0xffb347);s.kill=true;
        this.tweens.add({targets:o,angle:360,repeat:-1,duration:600});
        this.tweens.add({targets:o,x:d.to![0]+w/2,y:d.to![1]+h/2,yoyo:true,repeat:-1,ease:'Sine.inOut',
          duration:Math.hypot(d.to![0]-x,d.to![1]-y)/(d.v||120)*1000})}
      else if(d.t=='timed')o=box(d.r,0xff4d6d).setAlpha(.25);
      else if(d.t=='wall'){o=box(d.r,0xb0303f);s.kill=true;this.tweens.add({targets:o,x:d.to![0],y:d.to![1],yoyo:true,repeat:-1,ease:'Sine.inOut',hold:300,repeatDelay:300,
        duration:Math.hypot(d.to![0]-x,d.to![1]-y)/(d.v||120)*1000})}
      else if(d.t=='mover'){o=box(d.r,0x5a7bff);this.physics.add.existing(o);o.d=d;
        (o.body as Phaser.Physics.Arcade.Body).setAllowGravity(false).setImmovable(true).setVelocityX(d.v||100);this.movers.push(o)}
      s.o=o;this.ts.push(s);
      if(DEBUG&&s.trig)this.add.rectangle(s.trig[0],s.trig[1],s.trig[2],s.trig[3]).setOrigin(0).setStrokeStyle(1,0x00ff88);
    }
    this.ex=this.door(L.exit[0],L.exit[1]);
    this.p=this.add.rectangle(L.spawn[0],L.spawn[1],24,32,0xffe066);
    this.physics.add.existing(this.p);
    this.pb().setCollideWorldBounds(true).setMaxVelocity(260,900).setDragX(1500);
    this.physics.add.collider(this.p,this.plats);this.physics.add.collider(this.p,this.movers);
    const hud={fontFamily:'monospace',fontSize:'16px',color:'#8a8aa0'};
    this.add.text(12,8,`${Math.floor(this.i/6)+1}-${this.i%6+1}  ${L.name}`,hud).setDepth(10).setColor(['#ff4d6d','#4da6ff','#b266ff'][Math.floor(this.i/6)]);
    this.add.text(940,8,'deaths '+this.registry.get('deaths'),hud).setOrigin(1,0).setDepth(10);
    this.add.text(12,30,'',hud);
    this.add.text(930,36,'II',{...hud,fontSize:'26px'}).setOrigin(1,0).setInteractive().on('pointerdown',()=>this.pause(!this.paused));
    this.pt=txt(this,480,270,'PAUSED\n\ntap / Esc: resume · R: restart · M: menu',26).setDepth(20).setVisible(false).setInteractive().on('pointerdown',()=>this.pause(false));
    if(DEBUG)this.dbg=this.add.text(12,50,'',hud);
    this.k=this.input.keyboard!.addKeys('A,D,W,SPACE,LEFT,RIGHT,UP,R,ESC,M');
  }
  pause(on:boolean){this.paused=on;on?this.physics.pause():this.physics.resume();
    on?this.tweens.pauseAll():this.tweens.resumeAll();this.time.paused=on;this.pt.setVisible(on)}
  msg(t:string){const m=txt(this,480,80,t,22,'#ffd166');this.tweens.add({targets:m,alpha:0,y:60,duration:1500,onComplete:()=>m.destroy()})}
  fire(s:S){s.on=true;const{d,o}=s,[x,y,w,h]=d.r;beep(300,.12,'triangle',-120);
    d.chain?.forEach((j,n)=>this.time.delayedCall(250*(n+1),()=>{const t=this.ts[j];if(t&&!t.on)this.fire(t)}));
    if(d.t=='spike'){s.kill=true;o.setAlpha(1);this.tweens.add({targets:o,y,duration:80})}
    else if(d.t=='block'){s.kill=true;this.tweens.add({targets:o,y:d.to![1],duration:220,ease:'Quad.In'})}
    else if(d.t=='grav'){this.gf=d.v!;this.pb().setGravityY(this.gf<0?-3000:0);this.p.setFillStyle(this.gf<0?0x66ccff:0xffe066);
      this.msg(this.gf<0?'GRAVITY FLIPPED!':'gravity restored');if(!RM)this.cameras.main.flash(150,80,120,255)}
    else if(d.t=='rev'){this.rev=3000;this.msg('CONTROLS REVERSED!')}
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
    if(this.rev>0){dir=-dir;this.rev-=dt;if(this.rev<=0)this.msg('controls restored')}
    b.setAccelerationX(dir*1800);
    const gr=this.gf>0?(b.blocked.down||b.touching.down):(b.blocked.up||b.touching.up);this.coy=gr?100:this.coy-dt;
    const jd=K.W.isDown||K.UP.isDown||K.SPACE.isDown||touch.j;
    this.buf=(jd&&!this.jp)?120:this.buf-dt;this.jp=jd;
    if(this.buf>0&&this.coy>0){b.setVelocityY(-560*this.gf);this.buf=this.coy=0;beep(420,.08,'square',260)}
    if(!jd&&b.velocity.y*this.gf<-220)b.setVelocityY(-220*this.gf);
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
    beep(160,.3,'sawtooth',-120);
    for(let n=0;n<10;n++){const q=this.add.rectangle(this.p.x,this.p.y,6,6,0xffe066);
      this.tweens.add({targets:q,x:q.x+Phaser.Math.Between(-60,60),y:q.y+Phaser.Math.Between(-60,40),alpha:0,duration:350,onComplete:()=>q.destroy()})}
    this.p.setVisible(false);this.pb().enable=false;
    if(!RM)this.cameras.main.shake(120,.006);
    this.time.delayedCall(350,()=>this.scene.restart({i:this.i}));
  }
  win(){
    if(this.won||this.dead)return;this.won=true;this.pb().setVelocity(0,0).setAcceleration(0,0);
    if(!save.done.includes(this.i))save.done.push(this.i);
    save.unlocked=Math.max(save.unlocked,Math.min(this.i+1,LEVELS.length-1));store();
    beep(520,.4,'triangle',500);
    this.tweens.add({targets:this.ex,scaleX:.15,yoyo:true,duration:250});
    txt(this,480,260,`LEVEL CLEARED\ndeaths: ${this.registry.get('deaths')}`,40,'#66ffaa').setDepth(20);
    this.time.delayedCall(1200,()=>this.i+1<LEVELS.length?this.scene.start('Game',{i:this.i+1,fresh:true}):this.scene.start('Menu'));
  }
}
