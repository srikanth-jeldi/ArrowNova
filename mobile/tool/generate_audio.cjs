// Original procedural audio; no third-party recordings. Fixed seed is reproducible.
const fs = require('fs');
const path = require('path');
const rate = 44100;
let seed = 89127;
function noise() { seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0; return seed / 2147483648 - 1; }
function wav(name, samples) {
  const buffer = Buffer.alloc(44 + samples.length * 2);
  buffer.write('RIFF'); buffer.writeUInt32LE(36 + samples.length * 2, 4);
  buffer.write('WAVEfmt ', 8); buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20); buffer.writeUInt16LE(1, 22);
  buffer.writeUInt32LE(rate, 24); buffer.writeUInt32LE(rate * 2, 28);
  buffer.writeUInt16LE(2, 32); buffer.writeUInt16LE(16, 34);
  buffer.write('data', 36); buffer.writeUInt32LE(samples.length * 2, 40);
  const peak = samples.reduce((m,v)=>Math.max(m,Math.abs(v)), .001);
  samples.forEach((v,i)=>buffer.writeInt16LE(Math.round(v / Math.max(1,peak/.8)*32767),44+i*2));
  fs.writeFileSync(path.join(__dirname,'../assets/audio',name+'.wav'),buffer);
}
// A smooth air swipe: no hard attack, metallic note or impact sound.
let low = 0;
const swipe = Array.from({length: Math.floor(rate*.3)}, (_,i)=> {
  const t=i/rate, phase=t/.3;
  low += .16*(noise()-low);
  return low*.65*Math.pow(Math.sin(Math.PI*phase),2);
});
wav('clear',swipe);
wav('blocked',Array.from({length:Math.floor(rate*.16)},(_,i)=> {
  const t=i/rate;
  return .2*Math.sin(2*Math.PI*220*t)*Math.pow(Math.sin(Math.PI*t/.16),2);
}));
// Layered crowd handclaps, with three soft firework pops and falling crackles.
const win = new Array(Math.floor(rate*3.6)).fill(0);
function burst(start,duration,gain,decay) {
  let smooth=0;
  for(let i=0;i<rate*duration;i++) {
    const index=Math.floor(start*rate)+i;
    if(index>=win.length) break;
    const t=i/rate, n=noise();
    smooth += .24*(n-smooth);
    const envelope=Math.min(1,t/.003)*Math.exp(-t*decay)*Math.min(1,(duration-t)/.012);
    win[index]+=(n*.25+smooth*.75)*gain*envelope;
  }
}
for(let person=0;person<9;person++) {
  for(let clap=0;clap<10;clap++) {
    const start=.06+person*.019+clap*(.24+person*.007)+(noise()+1)*.025;
    const fade=Math.max(0,1-start/3.5);
    burst(start,.105,.36*fade,32);
    burst(start+.012,.075,.16*fade,48);
  }
}
for(const start of [.55,1.2,1.85]) {
  burst(start,.28,.7,19);
  for(let j=0;j<14;j++) burst(start+.10+j*.055,.045,.13*(1-j/17),65);
}
for(let i=0;i<win.length;i++) win[i]*=Math.min(1,(win.length-i)/(.25*rate));
wav('win',win);
// Original 16-second seamless ambient phrase. Whole-cycle carriers and a
// cosine envelope return to silence at each boundary without a loop click.
{
  const sampleRate = 22050, duration = 16, count = sampleRate * duration;
  const buffer = Buffer.alloc(44 + count * 2);
  buffer.write('RIFF'); buffer.writeUInt32LE(36 + count * 2, 4);
  buffer.write('WAVEfmt ', 8); buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20); buffer.writeUInt16LE(1, 22);
  buffer.writeUInt32LE(sampleRate, 24); buffer.writeUInt32LE(sampleRate * 2, 28);
  buffer.writeUInt16LE(2, 32); buffer.writeUInt16LE(16, 34);
  buffer.write('data', 36); buffer.writeUInt32LE(count * 2, 40);
  const chords = [[261.625,329.625,392],[220,261.625,329.625],[174.625,220,261.625],[196,246.9375,293.6875]];
  for(let i=0;i<count;i++) {
    const t=i/sampleRate, phase=t%4, chord=chords[Math.floor(t/4)];
    const envelope=Math.pow(Math.sin(Math.PI*phase/4),2);
    const value=chord.reduce((sum,f)=>sum+Math.sin(2*Math.PI*f*t),0)/3;
    buffer.writeInt16LE(Math.round(value*envelope*10000),44+i*2);
  }
  fs.writeFileSync(path.join(__dirname,'../assets/audio/ambient.wav'),buffer);
}
