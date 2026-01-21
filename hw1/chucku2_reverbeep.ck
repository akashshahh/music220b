TriOsc t => JCRev r => dac; 220 => t.freq;
for(0 => int i; i < 4; i++) { .5 => t.gain; 100::ms => now; 0 => t.gain; 100::ms => now; }