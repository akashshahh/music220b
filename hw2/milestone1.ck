"pitch pipe c.wav" => string PITCH_PIPE_FILE;
"pitch pipe static.wav" => string CHORD_FILE;

45 => float INTRO_BPM;  
90 => float MAIN_BPM;   

(60.0 / INTRO_BPM)::second => dur INTRO_BEAT;
(60.0 / MAIN_BPM)::second => dur BEAT;
BEAT / 2 => dur EIGHTH;
BEAT / 4 => dur SIXTEENTH;
BEAT / 8 => dur THIRTYSECOND;



3 => int NUM_VOICES;

500::ms => dur GLIDE_TIME;

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
    [0, 4, 7, 11, 14, 19],
    [4, 7, 10, 14, 16, 19],
    [2, 5, 9, 12, 16, 19],
    [2, 5, 8, 11, 14, 16]
] @=> int chords[][];


[
    [0, 4, 7],
    [4, 7, 10],
    [2, 5, 9],
    [2, 5, 8]
] @=> int padChordsBase[][];


fun void shiftChordDown(int chord[], int octaves) {
    for (0 => int i; i < chord.size(); i++) {
        chord[i] - (12 * octaves) => chord[i];
    }
}


int padChords[4][3];
for (0 => int c; c < padChordsBase.size(); c++) {
    for (0 => int n; n < padChordsBase[c].size(); n++) {
        padChordsBase[c][n] - 24 => padChords[c][n];
    }
}

SndBuf pitchBuf => NRev arpRev => dac;
0.3 => arpRev.mix;
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
        <<< "--- Arp Pass", r + 1, "of", NUM_REPEATS, "---" >>>;
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



<<< "=== MILESTONE 1 ===" >>>;
<<< "Chord Intro at", INTRO_BPM, "BPM" >>>;
<<< "Arp Section at", MAIN_BPM, "BPM" >>>;


<<< "--- Starting Chord Section ---" >>>;

startChordVoices();


for (0 => int i; i < NUM_VOICES && i < padChords[0].size(); i++) {
    semitoneToRatio(padChords[0][i]) => currentRates[i];
    currentRates[i] => targetRates[i];
    currentRates[i] => chordVoices[i].rate;
}


for (0 => int c; c < 4; c++) {
    <<< "Chord", c + 1 >>>;

    setTargetChord(padChords[c]);
    glideChordVoices();

    4 * INTRO_BEAT - GLIDE_TIME => dur holdTime;
    if (holdTime > 0::ms) {
        holdChord(holdTime);
    }
}


<<< "--- Transitioning to Arp ---" >>>;
fadeOutChords();

<<< "--- Starting Arp Section ---" >>>;

spork ~ drumLoop();
arpLoop();
