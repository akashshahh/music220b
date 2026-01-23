
"pitch pipe static.wav" => string PITCH_PIPE_FILE;


200 => float BPM;
(60.0 / BPM)::second => dur BEAT;


4 => int NUM_VOICES;

500::ms => dur GLIDE_TIME;


SndBuf voices[NUM_VOICES];
NRev rev => dac;
0.85 => rev.mix;


float currentRates[NUM_VOICES];
float targetRates[NUM_VOICES];


for (0 => int i; i < NUM_VOICES; i++) {
    voices[i] => rev;
    PITCH_PIPE_FILE => voices[i].read;
    0.4 => voices[i].gain;  
    1.0 => currentRates[i];
    1.0 => targetRates[i];
}


fun float semitoneToRatio(int semitones) {
    return Math.pow(2.0, semitones / 12.0);
}


fun void glideVoices() {
    50 => int steps;
    GLIDE_TIME / steps => dur stepDur;

    for (0 => int s; s < steps; s++) {
        for (0 => int i; i < NUM_VOICES; i++) {
            currentRates[i] + (targetRates[i] - currentRates[i]) * 0.1 => currentRates[i];
            currentRates[i] => voices[i].rate;

            if (voices[i].pos() >= voices[i].samples() - 1000) {
                0 => voices[i].pos;
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

fun void startVoices() {
    for (0 => int i; i < NUM_VOICES; i++) {
        0 => voices[i].pos;
        1 => voices[i].rate;
    }
}


fun void loopBuffers() {
    while (true) {
        for (0 => int i; i < NUM_VOICES; i++) {
            if (voices[i].pos() >= voices[i].samples() - 1000) {
                0 => voices[i].pos;
            }
        }
        10::ms => now;
    }
}


fun void holdChord(dur holdTime) {
    holdTime => dur remaining;
    while (remaining > 0::ms) {
        for (0 => int i; i < NUM_VOICES; i++) {
            if (voices[i].pos() >= voices[i].samples() - 1000) {
                0 => voices[i].pos;
            }
        }
        10::ms => now;
        remaining - 10::ms => remaining;
    }
}


// C E G C (2 octaves down)
[-24, -20, -17, -12] @=> int chord1[];

// C E G A (2 octaves down)
[-24, -20, -17, -15] @=> int chord2[];

// C E G B (2 octaves down)
[-24, -20, -17, -13] @=> int chord3[];

// C E G A (2 octaves down)
[-24, -20, -17, -15] @=> int chord4[];


[chord1, chord2, chord3, chord4] @=> int progression[][];

[4, 4, 4, 4] @=> int durations[];


<<< "Idea 2: Sliding Pitch Pipe Chords" >>>;
<<< "BPM:", BPM >>>;


2 => int repeats;


startVoices();


for (0 => int i; i < NUM_VOICES && i < progression[0].size(); i++) {
    semitoneToRatio(progression[0][i]) => currentRates[i];
    currentRates[i] => targetRates[i];
    currentRates[i] => voices[i].rate;
}

for (0 => int r; r < repeats; r++) {
    <<< "--- Pass", r + 1, "of", repeats, "---" >>>;

    for (0 => int c; c < progression.size(); c++) {
        <<< "Chord", c + 1 >>>;

        setTargetChord(progression[c]);

        glideVoices();

        durations[c] * BEAT - GLIDE_TIME => dur holdTime;
        if (holdTime > 0::ms) {
            holdChord(holdTime);
        }
    }
}


<<< "Fading out..." >>>;
100 => int fadeSteps;
2::second / fadeSteps => dur fadeStep;
for (0 => int s; s < fadeSteps; s++) {
    for (0 => int i; i < NUM_VOICES; i++) {
        voices[i].gain() * 0.95 => voices[i].gain;
    }
    fadeStep => now;
}

<<< "Done!" >>>;
