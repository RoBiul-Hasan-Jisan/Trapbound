import Phaser from 'phaser';

// Soft dusk palette ------------------------------------------------------------------
export const C={
  ink:'#fdf6ff',mute:'#c9bde0',plum:'#3b2d5c',gold:'#ffe3a8',
  rose:0xff9eb5,peach:0xffc9a3,mint:0x9ff0c8,sky:0x9cc8ff,lilac:0xc9a8ff,
  roseS:'#ff9eb5',mintS:'#9ff0c8'};
export const WORLD=[0xff9eb5,0x9cc8ff,0xc9a8ff];
export const WORLDS=['#ff9eb5','#9cc8ff','#c9a8ff'];
export const FONT="Nunito,Quicksand,'Trebuchet MS',ui-rounded,system-ui,sans-serif";
export const RM=matchMedia('(prefers-reduced-motion: reduce)').matches;
export const TEST=location.search.includes('test');
const RES=Math.min(2,Math.max(1,Math.ceil(window.devicePixelRatio||1)));

export const txt=(s:Phaser.Scene,x:number,y:number,t:string,sz=20,c=C.ink,w='700')=>
  s.add.text(x,y,t,{fontFamily:FONT,fontSize:sz+'px',fontStyle:w,color:c,align:'center',resolution:RES}).setOrigin(.5);

// Soft rounded button: gentle shadow, glossy top, press feedback. Hit area is a separate
// near-invisible rectangle so it behaves exactly like the old plain buttons.
export function btn(s:Phaser.Scene,x:number,y:number,w:number,h:number,label:string,fn:()=>void,
  o:{kind?:'primary'|'ghost';color?:number;size?:number;into?:Phaser.GameObjects.Container}={}){
  const primary=o.kind=='primary',col=o.color??C.rose,r=Math.min(26,h/2.4);
  const c=s.add.container(x,y),g=s.add.graphics();
  g.fillStyle(0x140a28,.28).fillRoundedRect(-w/2,-h/2+5,w,h,r);
  if(primary){
    g.fillStyle(col,1).fillRoundedRect(-w/2,-h/2,w,h,r);
    g.fillStyle(0xffffff,.22).fillRoundedRect(-w/2+5,-h/2+4,w-10,h*.4,{tl:r-4,tr:r-4,bl:r/3,br:r/3});
  }else{
    g.fillStyle(0xffffff,.14).fillRoundedRect(-w/2,-h/2,w,h,r);
    g.lineStyle(2,0xffffff,.3).strokeRoundedRect(-w/2,-h/2,w,h,r);
  }
  const t=txt(s,0,-1,label,o.size||26,primary?C.plum:C.ink,'800');
  c.add([g,t]);
  const hit=s.add.rectangle(x,y,w,h,0xffffff,.001).setInteractive({useHandCursor:true});
  if(o.into){o.into.add(c);o.into.add(hit)}
  hit.on('pointerover',()=>c.setScale(1.03)).on('pointerout',()=>c.setScale(1))
    .on('pointerup',()=>c.setScale(1.03)).on('pointerdown',()=>{c.setScale(.96);fn()});
  return t;
}

// Frosted rounded card.
export function card(s:Phaser.Scene,x:number,y:number,w:number,h:number,a=.55,stroke=0xffffff,into?:Phaser.GameObjects.Container){
  const g=s.add.graphics();
  g.fillStyle(0x1b1530,a).fillRoundedRect(x-w/2,y-h/2,w,h,28);
  g.lineStyle(2,stroke,.28).strokeRoundedRect(x-w/2,y-h/2,w,h,28);
  into?.add(g);return g;
}

// Dreamy background: soft gradient + drifting glow orbs + twinkling stars.
export function backdrop(s:Phaser.Scene,n=7){
  if(TEST)return;
  if(!s.textures.exists('sky')){
    const t=s.textures.createCanvas('sky',4,540)!,c=t.getContext(),g=c.createLinearGradient(0,0,0,540);
    g.addColorStop(0,'#4a3d82');g.addColorStop(.55,'#7656a6');g.addColorStop(1,'#a56fa8');
    c.fillStyle=g;c.fillRect(0,0,4,540);t.refresh();
  }
  s.add.image(480,270,'sky').setDisplaySize(960,540).setDepth(-30);
  if(!s.textures.exists('glow')){
    const t=s.textures.createCanvas('glow',128,128)!,c=t.getContext(),g=c.createRadialGradient(64,64,0,64,64,64);
    g.addColorStop(0,'rgba(255,255,255,1)');g.addColorStop(1,'rgba(255,255,255,0)');
    c.fillStyle=g;c.fillRect(0,0,128,128);t.refresh();
  }
  const cols=[0xff9eb5,0x9cc8ff,0xc9a8ff,0xffc9a3,0x9ff0c8];
  for(let i=0;i<n;i++){
    const sz=Phaser.Math.Between(180,340);
    const o=s.add.image(Phaser.Math.Between(0,960),Phaser.Math.Between(60,520),'glow')
      .setTint(cols[i%5]).setAlpha(.15).setDisplaySize(sz,sz).setDepth(-20);
    if(!RM)s.tweens.add({targets:o,x:o.x+Phaser.Math.Between(-90,90),y:o.y+Phaser.Math.Between(-50,50),
      alpha:.07+Math.random()*.1,yoyo:true,repeat:-1,duration:Phaser.Math.Between(4500,8000),ease:'Sine.inOut'});
  }
  for(let i=0;i<24;i++){
    const d=s.add.circle(Phaser.Math.Between(0,960),Phaser.Math.Between(0,300),Phaser.Math.FloatBetween(.8,1.8),0xffffff,Phaser.Math.FloatBetween(.25,.7)).setDepth(-19);
    if(!RM)s.tweens.add({targets:d,alpha:.1,yoyo:true,repeat:-1,duration:Phaser.Math.Between(1400,3200),delay:Phaser.Math.Between(0,2000)});
  }
}
