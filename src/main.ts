import Phaser from 'phaser';
import {Menu,Levels,Game} from './scenes';
import {touch} from './core';
const boot=()=>{
  const game=new Phaser.Game({type:Phaser.AUTO,parent:'game',width:960,height:540,backgroundColor:'#7656a6',
    scale:{mode:Phaser.Scale.FIT,autoCenter:Phaser.Scale.CENTER_BOTH},input:{activePointers:4},
    physics:{default:'arcade',arcade:{gravity:{x:0,y:1500},debug:location.search.includes('debug')}},scene:[Menu,Levels,Game]});
  if(location.search.includes('test')){(window as any).__g=game;(window as any).__t=touch}
};
// Wait (briefly) for the rounded font so Phaser text renders with it from the first frame.
const fonts:any=(document as any).fonts;
Promise.race([fonts?Promise.all([fonts.load('700 20px Nunito'),fonts.load('800 20px Nunito')]):0,new Promise(r=>setTimeout(r,1500))]).then(boot,boot);
// Move pad: one touch zone; slide between halves without lifting the finger.
const pad=document.getElementById('pad')!,jb=document.getElementById('bj')!;
let act=-1;
const dir=(e:PointerEvent)=>{const r=pad.getBoundingClientRect(),x=(e.clientX-r.left)/r.width;
  touch.l=x<.46;touch.r=x>.54;pad.dataset.d=touch.l?'l':touch.r?'r':''};
const stop=()=>{act=-1;touch.l=touch.r=false;pad.dataset.d=''};
pad.addEventListener('pointerdown',e=>{e.preventDefault();act=e.pointerId;try{pad.setPointerCapture(e.pointerId)}catch{}dir(e)});
pad.addEventListener('pointermove',e=>{if(e.pointerId===act)dir(e)});
['pointerup','pointercancel','lostpointercapture'].forEach(n=>pad.addEventListener(n,stop));
let jid=-1;const jstop=()=>{jid=-1;touch.j=false;jb.classList.remove('on')};
jb.addEventListener('pointerdown',e=>{e.preventDefault();jid=e.pointerId;try{jb.setPointerCapture(e.pointerId)}catch{}touch.j=true;jb.classList.add('on');navigator.vibrate?.(8)});
['pointerup','pointercancel','lostpointercapture'].forEach(n=>jb.addEventListener(n,jstop));
addEventListener('blur',()=>{stop();jstop()});
document.addEventListener('contextmenu',e=>e.preventDefault());
['gesturestart','dblclick'].forEach(n=>document.addEventListener(n,e=>e.preventDefault()));
