"pitch pipe c.wav" => string PITCH_PIPE_FILE;

90 => float BPM;
(60.0 / BPM)::second => dur BEAT;
BEAT / 2 => dur EIGHTH;
BEAT / 4 => dur SIXTEENTH;
BEAT / 8 => dur THIRTYSECOND;


SndBuf pitchBuf => NRev rev => dac;
0.3 => rev.mix;
0.5 => pitchBuf.gain;

SndBuf kick => dac;
SndBuf snare => dac;
SndBuf hihat => dac;

"pitch pipe drop.wav" => kick.read;  
"pitch pipe flick.wav" => snare.read;  
"pitch pipe tap.wav" => hihat.read; 

0.4 => kick.gain;
0.3 => snare.gain;
0.15 => hihat.gain;


PITCH_PIPE_FILE => pitchBuf.read;

fun float semitoneToRatio(int semitones) {
    return Math.pow(2.0, semitones / 12.0);
}


[
    [0, 4, 7, 11, 14, 19],
    [4, 7, 10, 14, 16, 19],
    [2, 5, 9, 12, 16, 19],
    [2, 5, 8, 11, 14, 16]
] @=> int chords[][];


[0, 2, 4, 1, 3, 5, 0, 2, 4, 1, 3, 5, 0, 3, 5, 4] @=> int arpPattern[];


[1, 0, 0, 0, 0, 0, 0, 0] @=> int kickPattern[];
[0, 0, 0, 0, 1, 0, 0, 0] @=> int snarePattern[];
[0, 0, 1, 1, 0, 0, 1, 1] @=> int hihatPattern[];


fun void playArpNote(int semitones) {
    0 => pitchBuf.pos;

    semitoneToRatio(semitones) => pitchBuf.rate;
}

fun void triggerDrum(SndBuf @ buf) {
    0 => buf.pos;
    1 => buf.rate;
}

4 => int NUM_REPEATS;

fun void drumLoop() {
    while (true) {
        for (0 => int i; i < kickPattern.size(); i++) {
            if (kickPattern[i]) triggerDrum(kick);
            if (snarePattern[i]) triggerDrum(snare);
            if (hihatPattern[i]) triggerDrum(hihat);
            SIXTEENTH => now;
        }
    }
}


fun void arpLoop() {
    for (0 => int r; r < NUM_REPEATS; r++) {
        <<< "--- Pass", r + 1, "of", NUM_REPEATS, "---" >>>;
        for (0 => int c; c < chords.size(); c++) {
            chords[c] @=> int currentChord[];

            for (0 => int i; i < arpPattern.size(); i++) {
                arpPattern[i] => int toneIndex;
                currentChord[toneIndex] => int semitones;

                playArpNote(semitones);
                THIRTYSECOND => now;
            }
        }
    }
    <<< "Done!" >>>;
}


<<< "Idea 1: Pitch Pipe Arpeggio with Drums" >>>;
<<< "BPM:", BPM >>>;


spork ~ drumLoop();


arpLoop();
