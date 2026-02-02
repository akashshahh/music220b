90 => float MAIN_BPM;
(60.0 / MAIN_BPM)::second => dur BEAT;
BEAT / 4 => dur SIXTEENTH;

dac => WvOut wv => blackhole;
"drums.wav" => wv.wavFilename;

SndBuf kick => dac;
SndBuf snare => dac;
SndBuf hihat => dac;

"pitch pipe drop.wav" => kick.read;
"pitch pipe flick.wav" => snare.read;
"pitch pipe tap.wav" => hihat.read;

0.4 => kick.gain;
0.3 => snare.gain;
0.15 => hihat.gain;

[1, 0, 0, 0, 0, 0, 0, 0] @=> int kickPattern[];
[0, 0, 0, 0, 1, 0, 0, 0] @=> int snarePattern[];
[0, 0, 1, 1, 0, 0, 1, 1] @=> int hihatPattern[];

fun void triggerDrum(SndBuf @ buf) {
    0 => buf.pos;
    1 => buf.rate;
}

16 => int NUM_BARS;

<<< "=== DRUMS ONLY ===" >>>;

for (0 => int bar; bar < NUM_BARS; bar++) {
    for (0 => int i; i < kickPattern.size(); i++) {
        if (kickPattern[i]) triggerDrum(kick);
        if (snarePattern[i]) triggerDrum(snare);
        if (hihatPattern[i]) triggerDrum(hihat);
        SIXTEENTH => now;
    }
}

wv.closeFile();
<<< "Saved drums.wav" >>>;
