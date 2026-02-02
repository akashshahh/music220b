"pitch pipe static.wav" => string CHORD_FILE;

90 => float INTRO_BPM;
(60.0 / INTRO_BPM)::second => dur INTRO_BEAT;

3 => int NUM_VOICES;
500::ms => dur GLIDE_TIME;

dac => WvOut wv => blackhole;
"chords.wav" => wv.wavFilename;

SndBuf chordVoices[NUM_VOICES];
NRev chordRev => dac;
0.7 => chordRev.mix;

float currentRates[NUM_VOICES];
float targetRates[NUM_VOICES];

for (0 => int i; i < NUM_VOICES; i++) {
    chordVoices[i] => chordRev;
    CHORD_FILE => chordVoices[i].read;
    0.25 => chordVoices[i].gain;
    1.0 => currentRates[i];
    1.0 => targetRates[i];
}

fun float semitoneToRatio(int semitones) {
    return Math.pow(2.0, semitones / 12.0);
}

fun void glideChordVoices() {
    50 => int steps;
    GLIDE_TIME / steps => dur stepDur;

    for (0 => int s; s < steps; s++) {
        for (0 => int i; i < NUM_VOICES; i++) {
            currentRates[i] + (targetRates[i] - currentRates[i]) * 0.1 => currentRates[i];
            currentRates[i] => chordVoices[i].rate;

            if (chordVoices[i].pos() >= chordVoices[i].samples() - 1000) {
                0 => chordVoices[i].pos;
            }
        }
        stepDur => now;
    }
}

fun void setTargetChord(int chord[]) {
    for (0 => int i; i < NUM_VOICES && i < chord.size(); i++) {
        semitoneToRatio(chord[i]) => targetRates[i];
    }
}

fun void startChordVoices() {
    for (0 => int i; i < NUM_VOICES; i++) {
        0 => chordVoices[i].pos;
        1 => chordVoices[i].rate;
    }
}

fun void holdChord(dur holdTime) {
    holdTime => dur remaining;
    while (remaining > 0::ms) {
        for (0 => int i; i < NUM_VOICES; i++) {
            if (chordVoices[i].pos() >= chordVoices[i].samples() - 1000) {
                0 => chordVoices[i].pos;
            }
        }
        10::ms => now;
        remaining - 10::ms => remaining;
    }
}

fun void fadeOutChords() {
    50 => int fadeSteps;
    1::second / fadeSteps => dur fadeStep;
    for (0 => int s; s < fadeSteps; s++) {
        for (0 => int i; i < NUM_VOICES; i++) {
            chordVoices[i].gain() * 0.9 => chordVoices[i].gain;
        }
        fadeStep => now;
    }

    for (0 => int i; i < NUM_VOICES; i++) {
        0 => chordVoices[i].gain;
    }
}

[
    [0, 4, 7],
    [4, 7, 10],
    [2, 5, 9],
    [2, 5, 8]
] @=> int padChordsBase[][];

int padChords[4][3];
for (0 => int c; c < padChordsBase.size(); c++) {
    for (0 => int n; n < padChordsBase[c].size(); n++) {
        padChordsBase[c][n] - 24 => padChords[c][n];
    }
}

<<< "=== CHORDS ONLY ===" >>>;

startChordVoices();

for (0 => int i; i < NUM_VOICES && i < padChords[0].size(); i++) {
    semitoneToRatio(padChords[0][i]) => currentRates[i];
    currentRates[i] => targetRates[i];
    currentRates[i] => chordVoices[i].rate;
}

for (0 => int c; c < 4; c++) {
    setTargetChord(padChords[c]);
    glideChordVoices();

    4 * INTRO_BEAT - GLIDE_TIME => dur holdTime;
    if (holdTime > 0::ms) {
        holdChord(holdTime);
    }
}

fadeOutChords();

wv.closeFile();
<<< "Saved chords.wav" >>>;
