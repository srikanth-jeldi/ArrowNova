// Original gentle harp cues plus real CC0 applause; see audio-source/README.md.
const fs=require('fs'),path=require('path'),{execFileSync}=require('child_process');
const rate=44100,out=path.join(__dirname,'../assets/audio'),tmp=path.join(__dirname,'../.build-tmp/audio');
fs.mkdirSync(tmp,{recursive:true});
function wav(name,a){const b=Buffer.alloc(44+a.length*2); b.write('RIFF');b.writeUInt32LE(b.length-8,4);b.write('WAVEfmt ',8);b.writeUInt32LE(16,16);b.writeUInt16LE(1,20);b.writeUInt16LE(1,22);b.writeUInt32LE(rate,24);b.writeUInt32LE(rate*2,28);b.writeUInt16LE(2,32);b.writeUInt16LE(16,34);b.write('data',36);b.writeUInt32LE(a.length*2,40);const peak=a.reduce((p,v)=>Math.max(p,Math.abs(v)),.001);a.forEach((v,i)=>b.writeInt16LE(Math.round(v/Math.max(1,peak/.82)*32767),44+i*2));const file=path.join(tmp,name+'.wav');fs.writeFileSync(file,b);return file;}
function note(a,start,midi,duration,gain=.25){const f=440*Math.pow(2,(midi-69)/12);for(let i=0;i<duration*rate;i++){const j=Math.floor(start*rate)+i;if(j>=a.length)break;const t=i/rate,env=(1-Math.exp(-t*180))*Math.exp(-t*3/duration)*Math.min(1,(duration-t)/.12);let v=0;for(let h=1;h<=5;h++)v+=Math.sin(2*Math.PI*f*h*t)*Math.exp(-h*t*2)/Math.pow(h,2.1);a[j]+=v*gain*env;}}
function encode(input,name){execFileSync('ffmpeg',['-hide_banner','-loglevel','error','-y','-i',input,'-codec:a','libmp3lame','-b:a','96k',path.join(out,name+'.mp3')]);}
// Non-tonal air movement: filtered noise with a rounded envelope, no bell notes.
let seed=19283;
function noise(){seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/2147483648-1;}
let low=0,lower=0;
let a=new Array(Math.floor(rate*.22)).fill(0);
for(let i=0;i<a.length;i++){
 const t=i/a.length;
 low+=.09*(noise()-low); lower+=.012*(low-lower);
 a[i]=(low-lower)*1.2*Math.pow(Math.sin(Math.PI*t),1.7);
}
encode(wav('clear',a),'clear');
// Short rounded error double-pulse. No metallic harmonics, ringing or sharp attack.
function error(a){
 for(const start of [0,.085])for(let i=0;i<rate*.065;i++){
  const t=i/rate,j=Math.floor(start*rate)+i;
  const env=Math.pow(Math.sin(Math.PI*t/.065),2);
  a[j]+=.25*env*(Math.sin(2*Math.PI*175*t)+.08*Math.sin(2*Math.PI*525*t));
 }
}
// A low, brief downward heartbeat when a heart disappears.
function heart(a,start,gain=.24){
 for(let i=0;i<rate*.24;i++){
  const t=i/rate,j=Math.floor(start*rate)+i;if(j>=a.length)break;
  const env=Math.pow(Math.sin(Math.PI*t/.24),2);
  a[j]+=gain*env*Math.sin(2*Math.PI*(240*t-220*t*t));
 }
}
a=new Array(Math.floor(rate*.26)).fill(0);heart(a,0);encode(wav('life_lost',a),'life_lost');
// A single composite file guarantees error then heart-loss without player races.
a=new Array(Math.floor(rate*.44)).fill(0);error(a);heart(a,.18);encode(wav('blocked',a),'blocked');
a=new Array(Math.floor(rate*.7)).fill(0);error(a);heart(a,.18);heart(a,.43,.16);encode(wav('lost',a),'lost');
// Major-key victory flourish plus an actual human applause recording.
a=new Array(Math.floor(rate*4.6)).fill(0);[[0,72],[.14,76],[.28,79],[.44,84]].forEach(([t,n])=>note(a,t,n,1.6,.30));
execFileSync('ffmpeg',['-hide_banner','-loglevel','error','-y','-i',wav('fanfare',a),'-i',path.join(__dirname,'audio-source/applause.flac'),'-filter_complex','[1:a]aresample=44100,highpass=f=100,lowpass=f=9500,volume=1.4,afade=t=in:d=0.03,afade=t=out:st=3.3:d=0.7,adelay=280:all=1[claps];[0:a][claps]amix=inputs=2:normalize=0,alimiter=limit=0.89:level=false[mix]','-map','[mix]','-t','4.6','-codec:a','libmp3lame','-b:a','128k',path.join(out,'win.mp3')]);
// Sparse 32-second original harp phrase; silent boundaries, no sustained drone.
a=new Array(rate*32).fill(0);const chords=[[60,64,67,72],[57,60,64,69],[53,57,60,65],[55,59,62,67]];
for(let bar=0;bar<8;bar++){const c=chords[bar%4];[0,1,2,3,2,1].forEach((n,k)=>note(a,bar*4+k*.5,c[n]+12,1.8,.12));note(a,bar*4,c[0],2.8,.12);}
for(let i=0;i<a.length;i++)a[i]*=Math.min(1,i/(rate*.12),(a.length-i)/(rate*.8));encode(wav('ambient',a),'ambient');
