import Phaser from 'phaser';
import {Menu,Game} from './scenes';
import {touch} from './core';
const game=new Phaser.Game({type:Phaser.AUTO,parent:'game',width:960,height:540,backgroundColor:'#0e0e12',
  scale:{mode:Phaser.Scale.FIT,autoCenter:Phaser.Scale.CENTER_BOTH},
  physics:{default:'arcade',arcade:{gravity:{x:0,y:1500},debug:location.search.includes('debug')}},scene:[Menu,Game]});
(['l','r','j'] as const).forEach(k=>{
  const el=document.getElementById('b'+k)!,set=(v:boolean)=>(e:Event)=>{e.preventDefault();touch[k]=v};
  el.addEventListener('pointerdown',set(true));
  ['pointerup','pointercancel','pointerleave'].forEach(n=>el.addEventListener(n,set(false)));
});
addEventListener('blur',()=>{touch.l=touch.r=touch.j=false});
if(location.search.includes('test')){(window as any).__g=game;(window as any).__t=touch}
