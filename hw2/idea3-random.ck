// Idea 3: Slowed Pitch Pipe Layers
// Pitch pipe random slowed way down with a second voice a major third up

// ===== CONFIGURATION =====
"pitch pipe random.wav" => string RANDOM_FILE;

// Playback rate (lower = slower)
.5 => float BASE_RATE;

// Major third = 4 semitones
Math.pow(2.0, 4.0 / 12.0) => float MAJOR_THIRD;

// ===== AUDIO CHAIN =====
SndBuf voice1 => NRev rev => dac;
SndBuf voice2 => rev;

// Load sounds
RANDOM_FILE => voice1.read;
RANDOM_FILE => voice2.read;

// Set rates
BASE_RATE => voice1.rate;
BASE_RATE * MAJOR_THIRD => voice2.rate;

// Gains
0.5 => voice1.gain;
0.5 => voice2.gain;

// Reverb
0.0 => rev.mix;

// ===== LOOPING =====
fun void loopVoice(SndBuf @ buf, float rate) {
    while (true) {
        if (buf.pos() >= buf.samples() - 1000 || buf.pos() < 0) {
            0 => buf.pos;
        }
        10::ms => now;
    }
}

// ===== MAIN =====
<<< "Idea 3: Slowed Pitch Pipe Layers" >>>;
<<< "Base rate:", BASE_RATE >>>;
<<< "Voice 2 rate:", BASE_RATE * MAJOR_THIRD, "(major third up)" >>>;

// Start both voices
0 => voice1.pos;
0 => voice2.pos;

// Loop both
spork ~ loopVoice(voice1, BASE_RATE);
spork ~ loopVoice(voice2, BASE_RATE * MAJOR_THIRD);

// Play for a while then fade out
10::second => now;

// Fade out
<<< "Fading out..." >>>;
100 => int fadeSteps;
3::second / fadeSteps => dur fadeStep;
for (0 => int s; s < fadeSteps; s++) {
    voice1.gain() * 0.95 => voice1.gain;
    voice2.gain() * 0.95 => voice2.gain;
    fadeStep => now;
}

<<< "Done!" >>>;
