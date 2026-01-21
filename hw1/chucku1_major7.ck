TriOsc t => JCRev r => dac; .4 => r.mix;
[220, 277, 330, 415] @=> int notes[]; for(0 => int i; i < 4; i++) { notes[i] => t.freq; 500::ms => now; }