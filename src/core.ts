export const touch={l:false,r:false,j:false};
const KEY='trapbound.v2';
export type Save={unlocked:number;done:number[];sound:boolean};
function load():Save{
  try{const s=JSON.parse(localStorage.getItem(KEY)||'');
    if(Number.isInteger(s.unlocked)&&s.unlocked>=0&&Array.isArray(s.done)&&s.done.every(Number.isInteger)&&typeof s.sound==='boolean')return s;
  }catch{}
  return {unlocked:0,done:[],sound:true};
}
export const save:Save=load();
export const store=()=>{try{localStorage.setItem(KEY,JSON.stringify(save))}catch{}};
let ac:AudioContext|undefined;
export function beep(f:number,d=0.1,type:OscillatorType='square',slide=0){
  if(!save.sound)return;
  try{ac??=new AudioContext();const o=ac.createOscillator(),g=ac.createGain(),t=ac.currentTime;
    o.type=type;o.frequency.setValueAtTime(f,t);if(slide)o.frequency.linearRampToValueAtTime(Math.max(30,f+slide),t+d);
    g.gain.setValueAtTime(0.06,t);g.gain.linearRampToValueAtTime(0,t+d);o.connect(g).connect(ac.destination);o.start(t);o.stop(t+d);
  }catch{}
}
