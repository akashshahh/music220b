"pitch pipe c.wav" => string PITCH_PIPE_FILE;

90 => float MAIN_BPM;
(60.0 / MAIN_BPM)::second => dur BEAT;
BEAT / 8 => dur THIRTYSECOND;

dac => WvOut wv => blackhole;
"arp.wav" => wv.wavFilename;

SndBuf pitchBuf => NRev arpRev => dac;
0.3 => arpRev.mix;
0.5 => pitchBuf.gain;

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

fun void playArpNote(int semitones) {
    0 => pitchBuf.pos;
    semitoneToRatio(semitones) => pitchBuf.rate;
}

4 => int NUM_REPEATS;

<<< "=== ARP ONLY ===" >>>;

for (0 => int r; r < NUM_REPEATS; r++) {
    for (0 => int c; c < chords.size(); c++) {
        chords[c] @=> int currentChord[];

        for (0 => int rep; rep < 2; rep++) {
            for (0 => int i; i < arpPattern.size(); i++) {
                arpPattern[i] => int toneIndex;
                currentChord[toneIndex] => int semitones;

                playArpNote(semitones);
                THIRTYSECOND => now;
            }
        }
    }
}

wv.closeFile();
<<< "Saved arp.wav" >>>;
