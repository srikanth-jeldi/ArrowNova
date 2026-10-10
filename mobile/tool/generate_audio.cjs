// Original synthesized feedback; no third-party recordings.
const fs = require('fs');
const path = require('path');
const rate = 44100;
for (const [name, notes, duration] of [
  ['clear', [1046.5, 1568, 2093], .28],
  ['blocked', [180, 240], .16],
  ['win', [523.25, 659.25, 783.99, 1046.5], .8],
]) {
  const count = Math.ceil(rate * duration);
  const buffer = Buffer.alloc(44 + count * 2);
  buffer.write('RIFF'); buffer.writeUInt32LE(36 + count * 2, 4);
  buffer.write('WAVEfmt ', 8); buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20); buffer.writeUInt16LE(1, 22);
  buffer.writeUInt32LE(rate, 24); buffer.writeUInt32LE(rate * 2, 28);
  buffer.writeUInt16LE(2, 32); buffer.writeUInt16LE(16, 34);
  buffer.write('data', 36); buffer.writeUInt32LE(count * 2, 40);
  for (let i = 0; i < count; i++) {
    const t = i / rate;
    let value = 0;
    notes.forEach((note, j) => {
      const local = t - (name === 'win' ? j * .10 : 0);
      if (local >= 0) value += Math.sin(local * Math.PI * 2 * note) *
        Math.min(1, local * 600) * Math.exp(-local * (name === 'win' ? 7 : 20)) / notes.length;
    });
    value *= Math.min(1, (duration - t) * 80);
    buffer.writeInt16LE(Math.round(value * 16000), 44 + i * 2);
  }
  fs.writeFileSync(path.join(__dirname, '../assets/audio', name + '.wav'), buffer);
}

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
