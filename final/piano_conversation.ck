// ==========================================
// piano_conversation.ck
// music 220b final
// basically u play a note, hit space, and it responds w an ambient thing
// hit space again to stop it, then play another note, repeat
//
// controls:
//   space    = switch turns (ur turn / system turn)
//   up/down  = adjust mic sensitivity
//   m        = mute/unmute mic
//   r        = reset everything
// ==========================================




//tracking whose turn it is
0 => int LISTENING;    
1 => int ANALYZING;    
2 => int RESPONDING;   
3 => int COOLDOWN;     


0 => int convState;

// --- analysis results ---
// filled in while listening, read when responding

// chroma = how much energy each of the 12 pitch classes has
// like a histogram 
float chroma[12];
float chromaAccum[12];

// which note 
0 => int detectedRoot;

// major or minor, but its random lol
0 => int detectedQuality;

// how loud the input is rn (rms = root mean square, standard loudness measure)
0.0 => float inputRMS;

// loudest moment during ur whole phrase, used to scale the response volume
0.0 => float inputPeakRMS;

// what range of notes played in (midi numbers)
// 60 = middle C for reference
0 => int inputLowNote;
127 => int inputHighNote;


0.0 => float inputDensity;
0.0 => float inputDuration;
0 => int onsetCount;
0 => int frameCount;


// these get shared between the audio analysis and the visuals
// so the graphics can react to whats happening in real time

// loudness for the visuals
0.0 => float vizRMS;

// chroma for the visuals 
float vizChroma[12];

// which state the visuals think we're in
0 => int vizState;

// how far thru the response we are 0-1
0.0 => float responseProgress;

//mic tuning
// too low = picks up noise, too high = doesnt hear soft playing
// adjust w up/down arrows while running
0.0001 => float SILENCE_THRESH;

// mic mute toggle (m)
0 => int micMuted;

// --- lookup tables ---
["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"] @=> string pcNames[];
["major","minor"] @=> string qualNames[];

// --- pad voicings ---
// chord shapes for the pad response
// each one is 4 notes, 3 options per quality


//   0: root, 5th, maj7, 9th 
//   1: root, 3rd, 9th up an octave, #11 
//   2: root, maj7, 9th, 13th 
[0, 7, 11, 14,   0, 4, 14, 18,   0, 11, 14, 21] @=> int majVoicings[];

// minor voicings 
//   0: root, 5th, b7, 9th 
//   1: root, b3, 9th up, 11th 
//   2: root, b7, 9th, 13th 
[0, 7, 10, 14,   0, 3, 14, 17,   0, 10, 14, 21] @=> int minVoicings[];


// bells and arps use these 


[0, 2, 4, 6, 7, 9, 11] @=> int scaleLydian[];


[0, 2, 3, 5, 7, 9, 10] @=> int scaleDorian[];


// =====================================================================
// audio input + fft setup
// =====================================================================

adc => Gain inputGain => blackhole;

// boosted gain 
5.0 => inputGain.gain;

// fft = fast fourier transform, turns audio into frequency info
adc => FFT fft => blackhole;

// 8192 samples per fft window
// at 44100hz sample rate this is ~186ms per window which is good
8192 => fft.size;

// hann window smooths the edges of each audio chunk
// prevents fake frequencies from showing up 
Windowing.hann(fft.size() / 2) => fft.window;

// number of frequency bins we get (always half fft)
// each bin covers about 5.4hz 
fft.size() / 2 => int NUM_BINS;


// =====================================================================
// response audio routing
// =====================================================================

// mix buses
Gain padBus => Gain mixBus;     
Gain bellBus => mixBus;          
Gain texBus => mixBus;           
Gain droneBus => mixBus;         

// bus volumes 
0.4 => padBus.gain;
0.3 => bellBus.gain;
0.2 => texBus.gain;
0.1 => droneBus.gain;

// master volume
0.6 => mixBus.gain;

// --- effects chain ---
mixBus => NRev masterRev => LPF masterLPF => dac;


0.15 => masterRev.mix;

// lpf at 5000hz makes everything warm
5000.0 => masterLPF.freq;

// --- delay (echo) ---

// first delay: 400ms echo
masterRev => DelayL del1 => Gain delWet => masterLPF;
500::ms => del1.max;
400::ms => del1.delay;
0.15 => delWet.gain;

// second delay: 750ms, fed from the first one 
delWet => DelayL del2 => Gain delFb2 => masterLPF;
750::ms => del2.max;
750::ms => del2.delay;
0.1 => delFb2.gain;

// --- pad voices ---
SawOsc padSawA[4];
SawOsc padSawB[4];
LPF padLPF[4];
ADSR padEnv[4];

for( 0 => int i; i < 4; i++ )
{
    // saws -> filter -> envelope -> bus
    padSawA[i] => padLPF[i] => padEnv[i] => padBus;
    padSawB[i] => padLPF[i];

    // quiet 
    0.15 => padSawA[i].gain;
    0.15 => padSawB[i].gain;

    // warm filter starting point
    1200.0 => padLPF[i].freq;
    1.0 => padLPF[i].Q;

    // slow attack and release for dreamy fade in/out
    padEnv[i].set( 800::ms, 400::ms, 0.7, 2500::ms );
}

// --- bell voice ---
SinOsc bellOsc => LPF bellLPF => ADSR bellEnv => NRev bellRev => bellBus;

0.5 => bellOsc.gain;
5000.0 => bellLPF.freq;
// fast attack
bellEnv.set( 5::ms, 200::ms, 0.5, 400::ms );
0.3 => bellRev.mix;   // extra reverb for shimmer

// --- arp voice ---
SinOsc arpOsc => LPF arpLPF => ADSR arpEnv => NRev arpRev => bellBus;

0.5 => arpOsc.gain;
5000.0 => arpLPF.freq;
// slightly shorter than bells
arpEnv.set( 5::ms, 150::ms, 0.5, 300::ms );
0.2 => arpRev.mix;

// --- texture voice ---
// white noise thru a bandpass filter 
Noise texNoise => BPF texBPF => ADSR texEnv => texBus;

0.4 => texNoise.gain;
400.0 => texBPF.freq;   
3.0 => texBPF.Q;        
// slow fades for atmospheric effect
texEnv.set( 400::ms, 200::ms, 0.6, 600::ms );

// --- drone ---

// root note
SinOsc droneSin => droneBus;
// fifth above root 
TriOsc droneFifth => droneBus;
// sub bass one octave below 
SinOsc droneSub => droneBus;

0.04 => droneSin.gain;
0.03 => droneFifth.gain;
0.03 => droneSub.gain;

// start in C
// mtof converts midi note number to frequency 
Std.mtof( 48 ) => droneSin.freq;    // C3
Std.mtof( 55 ) => droneFifth.freq;  // G3
Std.mtof( 36 ) => droneSub.freq;    // C2



// =====================================================================
// analysis functions
// =====================================================================

0.0 => float frameRMS;

// harmonic series intervals and relative strengths
// used to cancel out harmonics so we find the fundamental
[12, 19, 24, 28, 31, 34, 36] @=> int harmonicSemitones[];
[0.35, 0.25, 0.18, 0.14, 0.10, 0.08, 0.06] @=> float harmonicStrength[];
float bassChroma[12];
float bassChromaAccum[12];

// grabs the fft data and computes rms loudness
fun void analyzeFrame()
{
    fft.upchuck();
    fft.size() / 2 => int numBins;
    0.0 => float sum;
    for( 0 => int i; i < numBins; i++ )
    {
        fft.cval(i) => complex c;
        c.re * c.re + c.im * c.im +=> sum;
    }
    Math.sqrt( sum / numBins ) => frameRMS;
}

// builds a chroma vector from the fft
// also does harmonic cancellation 
// and tracks bass-weighted chroma separately to help find the root
fun void computeChroma()
{
    for( 0 => int i; i < 12; i++ ) { 0.0 => chroma[i]; 0.0 => bassChroma[i]; }
    second / samp => float sr;
    fft.size() => int fftSize;
    fftSize / 2 => int numBins;

    // only look at bins between 55hz and 2100hz 
    (55.0 * fftSize / sr) $ int => int lowBin;
    (2100.0 * fftSize / sr) $ int => int highBin;
    if( lowBin < 1 ) 1 => lowBin;
    if( highBin >= numBins ) numBins - 1 => highBin;

    0.0 => float totalEnergy;
    0.0 => float bassTotal;
    for( lowBin => int b; b < highBin; b++ )
    {
        fft.cval(b) => complex c;
        c.re * c.re + c.im * c.im => float mag2;
        if( mag2 < 0.0000001 ) continue;
        Math.sqrt( mag2 ) => float mag;
        b * sr / fftSize => float freq;
        if( freq < 30.0 ) continue;
        Std.ftom( freq ) => float midi;

        // weight higher notes less 
        1.0 => float weight;
        if( midi > 60.0 ) Math.pow( 0.85, (midi - 60.0) / 12.0 ) => weight;

        // fold into pitch class 0-11
        (Math.round( midi ) $ int) % 12 => int pc;
        if( pc < 0 ) pc + 12 => pc;
        mag * weight +=> chroma[pc];
        mag * weight +=> totalEnergy;

        // extra weight for bass 
        if( midi < 65.0 )
        {
            Math.pow( 2.0, (60.0 - midi) / 12.0 ) => float bassWeight;
            mag * bassWeight +=> bassChroma[pc];
            mag * bassWeight +=> bassTotal;
        }
    }

    // normalize
    if( totalEnergy > 0.0 )
        for( 0 => int i; i < 12; i++ ) chroma[i] / totalEnergy => chroma[i];
    if( bassTotal > 0.0 )
        for( 0 => int i; i < 12; i++ ) bassChroma[i] / bassTotal => bassChroma[i];

    float cleaned[12];
    for( 0 => int i; i < 12; i++ ) chroma[i] => cleaned[i];
    for( 0 => int i; i < 12; i++ )
    {
        if( chroma[i] < 0.06 ) continue;
        for( 0 => int h; h < harmonicSemitones.size(); h++ )
        {
            (i + harmonicSemitones[h]) % 12 => int harmPC;
            chroma[i] * harmonicStrength[h] -=> cleaned[harmPC];
        }
    }
    // clamp negatives 
    0.0 => float cleanTotal;
    for( 0 => int i; i < 12; i++ )
    {
        if( cleaned[i] < 0.0 ) 0.0 => cleaned[i];
        cleaned[i] +=> cleanTotal;
    }
    if( cleanTotal > 0.0 )
        for( 0 => int i; i < 12; i++ ) cleaned[i] / cleanTotal => chroma[i];
    else
        for( 0 => int i; i < 12; i++ ) 0.0 => chroma[i];
}

// finds the root note by blending bass/full chroma
fun int findRoot()
{
    0 => int best;
    0.0 => float bestVal;
    for( 0 => int i; i < 12; i++ )
    {
        bassChromaAccum[i] * 0.6 + chromaAccum[i] * 0.4 => float combined;
        if( combined > bestVal )
        {
            combined => bestVal;
            i => best;
        }
    }
    return best;
}

// so the response can play in a complementary range
fun void findPitchRange()
{
    second / samp => float sr;
    fft.size() => int fftSize;
    fftSize / 2 => int numBins;
    127 => int lo;
    0 => int hi;
    (55.0 * fftSize / sr) $ int => int lowBin;
    (2100.0 * fftSize / sr) $ int => int highBin;
    if( lowBin < 1 ) 1 => lowBin;
    if( highBin >= numBins ) numBins - 1 => highBin;
    for( lowBin => int b; b < highBin; b++ )
    {
        fft.cval(b) => complex c;
        c.re * c.re + c.im * c.im => float mag2;
        if( mag2 < 0.001 ) continue;
        b * sr / fftSize => float freq;
        if( freq < 30.0 ) continue;
        Math.round( Std.ftom( freq ) ) $ int => int midi;
        if( midi < lo ) midi => lo;
        if( midi > hi ) midi => hi;
    }
    lo => inputLowNote;
    hi => inputHighNote;
}


// =====================================================================
// input analyzer
// =====================================================================

fun void inputAnalyzer()
{
    0 => int hasPlayed;
    0.0 => float prevRMS;
    now => time phraseStart;
    0 => int dbgCount;

    while( true )
    {
        // wait for next window
        (fft.size() / 2)::samp => now;

        // skip if mic is muted or not turn to listen
        if( micMuted || convState != LISTENING )
        {
            10::ms => now;
            continue;
        }

        // run analysis
        analyzeFrame();
        computeChroma();
        frameRMS => float rms;
        rms => inputRMS;
        rms => vizRMS;

        // copy to visuals
        for( 0 => int i; i < 12; i++ )
            chroma[i] => vizChroma[i];

        // print 
        dbgCount++;
        if( dbgCount % 22 == 0 )
            <<< "RMS:", rms, "| thresh:", SILENCE_THRESH >>>;

        
        if( rms > SILENCE_THRESH )
        {
            // first frame of sound reset accumulators
            if( !hasPlayed )
            {
                1 => hasPlayed;
                now => phraseStart;
                0.0 => inputPeakRMS;
                for( 0 => int i; i < 12; i++ ) { 0.0 => chromaAccum[i]; 0.0 => bassChromaAccum[i]; }
                0 => frameCount;
            }
            // accumulate chroma data across frames 
            for( 0 => int i; i < 12; i++ )
            {
                chroma[i] +=> chromaAccum[i];
                bassChroma[i] +=> bassChromaAccum[i];
            }
            frameCount++;
            if( rms > inputPeakRMS ) rms => inputPeakRMS;
            findPitchRange();
        }
        else if( hasPlayed )
        {
            (now - phraseStart) / second => inputDuration;
            0 => hasPlayed;
        }
    }
}


// =====================================================================
// state machine
// =====================================================================

fun void stateMachine()
{
    while( true )
    {
        10::ms => now;

        if( convState == ANALYZING )
        {
            <<< ">> Analyzing..." >>>;
            // brief pause so the visuals can show the state
            300::ms => now;

            // start response
            RESPONDING => convState;
            RESPONDING => vizState;
            0.0 => responseProgress;

            // spork it
            spork ~ generateResponse();
        }
    }
}


// =====================================================================
// response generation
// =====================================================================

// lydian for major, dorian for minor
fun int[] getStrongScale( int quality )
{
    if( quality == 1 ) return scaleDorian;
    return scaleLydian;
}

// pad response - sustained w filter sweep
fun void respondPad( int root, int quality, float gain )
{
    int notes[4];

    // if played high, respond low and vice versa
    48 => int baseOctave;
    if( inputHighNote > 72 ) 36 => baseOctave;
    else if( inputLowNote < 52 ) 60 => baseOctave;

    // pick one of the voicings randomly
    Math.random2(0, 2) * 4 => int vOff;
    for( 0 => int i; i < 4; i++ )
    {
        if( quality == 0 )
            root + majVoicings[vOff + i] + baseOctave => notes[i];
        else
            root + minVoicings[vOff + i] + baseOctave => notes[i];
    }

    // set frequencies w slight random detuning 
    for( 0 => int i; i < 4; i++ )
    {
        Math.random2f( -10.0, 10.0 ) => float centsA;
        Math.random2f( -10.0, 10.0 ) => float centsB;
        Std.mtof( notes[i] + centsA / 100.0 ) => padSawA[i].freq;
        Std.mtof( notes[i] + centsB / 100.0 ) => padSawB[i].freq;
        padEnv[i].keyOn();
    }

    // sweep filter back and forth 
    0.0 => float phase;
    while( convState == RESPONDING )
    {
        0.02 :: second => now;
        phase + 0.03 => phase;
        Math.max( 300.0, 600.0 + 900.0 * Math.sin( phase ) ) => float cutoff;
        for( 0 => int i; i < 4; i++ )
            cutoff => padLPF[i].freq;
    }

    // release when done
    for( 0 => int i; i < 4; i++ )
        padEnv[i].keyOff();
}

// bell response - random sparkly notes from the scale

fun void respondBells( int root, int scale[], float gain )
{
    while( convState == RESPONDING )
    {
        scale[ Math.random2(0, scale.size() - 1) ] => int interval;
        root + interval + 72 + Math.random2(0,2) * 12 => int note;
        Std.mtof( note ) => bellOsc.freq;
        gain * 0.5 => bellOsc.gain;
        bellEnv.keyOn();
        150::ms => now;
        bellEnv.keyOff();
        // random wait between notes 
        Math.random2f( 0.8, 2.5 ) :: second => now;
    }
}

// arp response - steps thru the scale sequentially
fun void respondArp( int root, int scale[], float gain )
{
    0.35 => float baseInterval;
    0 => int step;
    while( convState == RESPONDING )
    {
        scale[ step % scale.size() ] => int interval;
        root + interval + 60 => int note;
        Std.mtof( note ) => arpOsc.freq;
        gain * 0.5 => arpOsc.gain;
        arpEnv.keyOn();
        100::ms => now;
        arpEnv.keyOff();
        (baseInterval - 0.04) :: second => now;
        step++;
    }
}

// texture response filtered noise 

fun void respondTexture( int root, float gain )
{
    Std.mtof( root + 60 ) => float centerFreq;
    centerFreq => texBPF.freq;
    gain => texNoise.gain;
    texEnv.keyOn();

    // slowly sweep the bandpass filter w sine
    centerFreq * 0.3 => float sweepDepth;
    0.0 => float phase;
    while( convState == RESPONDING )
    {
        0.03 :: second => now;
        phase + 0.04 => phase;
        centerFreq + sweepDepth * Math.sin( phase ) => texBPF.freq;
    }

    texEnv.keyOff();
}

// kills all sound immediately when space 
fun void killAllSound()
{
    for( 0 => int i; i < 4; i++ )
    {
        padEnv[i].keyOff();
        0.0 => padSawA[i].gain;
        0.0 => padSawB[i].gain;
    }
    bellEnv.keyOff();
    arpEnv.keyOff();
    texEnv.keyOff();
    0.0 => bellOsc.gain;
    0.0 => arpOsc.gain;
    0.0 => texNoise.gain;
    0.0 => mixBus.gain;
}

// puts all the gains back to normal after a kill

fun void restoreGains()
{
    for( 0 => int i; i < 4; i++ )
    {
        0.15 => padSawA[i].gain;
        0.15 => padSawB[i].gain;
    }
    0.5 => bellOsc.gain;
    0.5 => arpOsc.gain;
    0.4 => texNoise.gain;
    0.6 => mixBus.gain;
}

// main response coordinator
fun void generateResponse()
{
    restoreGains();
    getStrongScale( detectedQuality ) @=> int strongScale[];

    // response volume scales w how loud played
    Math.min( 0.5, Math.max( 0.25, inputPeakRMS * 2.0 ) ) => float respGain;

    // set drone to root
    Std.mtof( detectedRoot + 48 ) => droneSin.freq;
    Std.mtof( detectedRoot + 55 ) => droneFifth.freq;
    Std.mtof( detectedRoot + 36 ) => droneSub.freq;

    // launch response voices as sporks
    spork ~ respondPad( detectedRoot, detectedQuality, respGain );
    spork ~ respondTexture( detectedRoot, respGain );
    spork ~ respondBells( detectedRoot, strongScale, respGain );
    spork ~ respondArp( detectedRoot, strongScale, respGain );

    // wait for space
    while( convState == RESPONDING )
        20::ms => now;
}


// =====================================================================
// drone modulation
// =====================================================================

fun void ambientDrone()
{
    0.0 => float phase;

    while( true )
    {
        20::ms => now;
        phase + 0.01 => phase;

        // each drone voice wobbles between slightly different gains
        0.05 + 0.02 * Math.sin( phase ) => droneSin.gain;
        0.03 + 0.015 * Math.sin( phase * 0.7 ) => droneFifth.gain;
        0.04 + 0.02 * Math.sin( phase * 1.3 ) => droneSub.gain;
    }
}


// =====================================================================
// chugl visuals
// =====================================================================

// scene and camera setup
GG.scene() @=> GScene @ scene;
scene.backgroundColor( @(0.0, 0.0, 0.02) );  // almost black w hint of blue

GG.camera() @=> GCamera @ cam;
cam.pos( @(0, 0, 16) );       // pulled back to see everything
cam.lookAt( @(0, 0, 0) );     // looking at center

// bloom 
GG.bloom( 1 );
GG.bloomPass().threshold( 0.2 );
GG.bloomPass().intensity( 1.5 );
GG.bloomPass().radius( 0.8 );
GG.bloomPass().levels( 6 );

// tiny bit of ambient light 
scene.ambient( @(0.01, 0.005, 0.02) );

// colors for each pitch class, rainbow
[
    @(0.3, 0.5, 1.0),   // C  = blue
    @(0.2, 0.6, 0.9),   // C# = blue-cyan
    @(0.0, 0.8, 0.9),   // D  = cyan
    @(0.0, 0.9, 0.6),   // D# = cyan-green
    @(0.2, 0.9, 0.3),   // E  = green
    @(0.5, 1.0, 0.2),   // F  = lime
    @(0.8, 0.9, 0.1),   // F# = yellow-lime
    @(1.0, 0.8, 0.1),   // G  = gold
    @(1.0, 0.5, 0.1),   // G# = orange
    @(1.0, 0.2, 0.2),   // A  = red
    @(0.8, 0.1, 0.6),   // A# = magenta
    @(0.5, 0.2, 0.9)    // B  = violet
] @=> vec3 orbColors[];


// 12 spheres in a circle, each one lights up when its note is detected
GSphere pitchOrbs[12];
GPointLight orbLights[12];
float orbBaseScale[12];
float orbCurrentScale[12];

3.0 => float ORBIT_RADIUS;    // how far out the orbs are
1.0 => float ORBIT_Y_OFFSET;  // shift the circle up a bit

for( 0 => int i; i < 12; i++ )
{
    pitchOrbs[i] --> scene;

    // small
    0.12 => orbBaseScale[i];
    0.12 => orbCurrentScale[i];
    pitchOrbs[i].sca( 0.12 );

    // dim when inactive
    pitchOrbs[i].color( orbColors[i] * 0.15 );
    pitchOrbs[i].emission( orbColors[i] * 0.6 );

    // position in a circle 
    i * 2.0 * Math.PI / 12.0 => float angle;
    ORBIT_RADIUS * Math.cos( angle ) => float px;
    ORBIT_RADIUS * Math.sin( angle ) + ORBIT_Y_OFFSET => float py;
    pitchOrbs[i].pos( @(px, py, 0) );

    // point light at each orb 
    orbLights[i] --> scene;
    orbLights[i].color( orbColors[i] );
    orbLights[i].pos( @(px, py, 0.8) );
    orbLights[i].intensity( 0.0 );
    orbLights[i].radius( 5.0 );
}


// thin donut around the orbs, color shows state
stateRing.pos( @(0, ORBIT_Y_OFFSET, 0) );
stateRing.sca( @(3.8, 3.8, 0.04) );
stateRing.color( @(0.02, 0.04, 0.15) );
stateRing.emission( @(0.1, 0.2, 0.7) );

// ring colors per state
@(0.1, 0.3, 1.0) => vec3 stateColorListening;
@(0.8, 0.8, 0.9) => vec3 stateColorAnalyzing;
@(1.0, 0.8, 0.2) => vec3 stateColorResponding;
@(0.5, 0.1, 0.8) => vec3 stateColorCooldown;

//particles
150 => int NUM_PARTICLES;

GPoints particles --> scene;
particles.billboard( 1 );  // always face camera

vec3 particlePos[NUM_PARTICLES];
vec3 particleVel[NUM_PARTICLES];
vec3 particleColors[NUM_PARTICLES];
float particleSizes[NUM_PARTICLES];
float particleBaseSizes[NUM_PARTICLES];
float particlePhase[NUM_PARTICLES];

// randomize everything
for( 0 => int i; i < NUM_PARTICLES; i++ )
{
    @( Math.random2f(-6, 6), Math.random2f(-6, 6), Math.random2f(-3, 3) ) => particlePos[i];
    @( Math.random2f(-0.08, 0.08), Math.random2f(-0.08, 0.08), Math.random2f(-0.03, 0.03) ) => particleVel[i];
    @( Math.random2f(0.4, 0.7), Math.random2f(0.5, 0.8), Math.random2f(0.9, 1.0) ) => particleColors[i];
    Math.random2f( 0.02, 0.08 ) => particleSizes[i];
    particleSizes[i] => particleBaseSizes[i];
    Math.random2f( 0, 6.28 ) => particlePhase[i];  // random phase so they dont all twinkle together
}

// send to gpu
particles.positions( particlePos );
particles.colors( particleColors );
particles.sizes( particleSizes );
particles.size( 1.0 );


// status text and chord name display
GText statusText --> scene;
statusText.text( "" );
statusText.pos( @(0, -4.8, 0) );
statusText.sca( 0.9 );
statusText.color( @(0.4, 0.5, 0.9, 0.8) );

GText chordText --> scene;
chordText.text( "" );
chordText.pos( @(0, -5.5, 0) );
chordText.sca( 0.8 );
chordText.color( @(0.9, 0.8, 0.5, 0.9) );



spork ~ inputAnalyzer();
spork ~ stateMachine();
spork ~ ambientDrone();

<<< "=== PIANO CONVERSATION ===" >>>;
<<< "SPACE to switch turns | UP/DOWN threshold | M mute | R reset" >>>;


// =====================================================================
// main render loop
// =====================================================================

0.0 => float camPhase;
float smoothChroma[12];  // smoothed chroma 

while( true )
{
    // wait for next video frame
    GG.nextFrame() => now;

    // seconds since last frame, use this to make animations not depend on fps
    GG.dt() => float dt;
    now / second => float timeS;


    // all key events come from the chugl window

    // SPACE: toggle turns
    if( GWindow.keyDown( GWindow.KEY_SPACE ) )
    {
        if( convState == LISTENING )
        {
            
            if( frameCount > 0 )
            {
                
                0.0 => float totalAccum;
                0.0 => float totalBassAccum2;
                for( 0 => int i; i < 12; i++ )
                {
                    chromaAccum[i] +=> totalAccum;
                    bassChromaAccum[i] +=> totalBassAccum2;
                }
                if( totalAccum > 0.0 )
                    for( 0 => int i; i < 12; i++ )
                        chromaAccum[i] / totalAccum => chromaAccum[i];
                if( totalBassAccum2 > 0.0 )
                    for( 0 => int i; i < 12; i++ )
                        bassChromaAccum[i] / totalBassAccum2 => bassChromaAccum[i];

                
                findRoot() => detectedRoot;
                Math.random2(0, 1) => detectedQuality;
                <<< pcNames[detectedRoot], qualNames[detectedQuality] >>>;
                ANALYZING => convState;
                ANALYZING => vizState;
            }
        }
        else if( convState == RESPONDING )
        {
            
            LISTENING => convState;
            LISTENING => vizState;
            killAllSound();
            0 => frameCount;
            0.0 => inputPeakRMS;
        }
    }

    // UP: raise threshold 
    if( GWindow.keyDown( GWindow.KEY_UP ) )
    {
        SILENCE_THRESH * 1.5 => SILENCE_THRESH;
        <<< "Silence thresh:", SILENCE_THRESH >>>;
    }

    // DOWN: lower threshold 
    if( GWindow.keyDown( GWindow.KEY_DOWN ) )
    {
        SILENCE_THRESH * 0.67 => SILENCE_THRESH;
        <<< "Silence thresh:", SILENCE_THRESH >>>;
    }

    // M: mute/unmute mic
    if( GWindow.keyDown( GWindow.KEY_M ) )
    {
        if( micMuted ) { 0 => micMuted; 5.0 => inputGain.gain; <<< "MIC: ON" >>>; }
        else { 1 => micMuted; 0.0 => inputGain.gain; <<< "MIC: MUTED" >>>; }
    }

    // R: reset 
    if( GWindow.keyDown( GWindow.KEY_R ) )
    {
        LISTENING => convState;
        LISTENING => vizState;
        killAllSound();
        0 => frameCount;
        <<< ">> RESET" >>>;
    }

    // each orb glows based on how much of its pitch class is in the audio
    for( 0 => int i; i < 12; i++ )
    {
        // smooth interpolation so orbs fade
        smoothChroma[i] + (vizChroma[i] - smoothChroma[i]) * Math.min(1.0, dt * 8.0) => smoothChroma[i];

        // scale orb size based on chroma 
        orbBaseScale[i] + smoothChroma[i] * 0.6 => float targetScale;
        orbCurrentScale[i] + (targetScale - orbCurrentScale[i]) * Math.min(1.0, dt * 6.0) => orbCurrentScale[i];
        pitchOrbs[i].sca( orbCurrentScale[i] );

        // brighter emission when active 
        pitchOrbs[i].emission( orbColors[i] * (0.6 + smoothChroma[i] * 4.0) );

        // light intensity scales w chroma
        orbLights[i].intensity( smoothChroma[i] * 5.0 );

        // slow rotation 
        dt * 0.3 => pitchOrbs[i].rotateY;

        // gentle bobbing
        i * 2.0 * Math.PI / 12.0 => float angle;
        ORBIT_RADIUS * Math.cos( angle ) => float bx;
        ORBIT_RADIUS * Math.sin( angle ) + ORBIT_Y_OFFSET + 0.1 * Math.sin( timeS * 0.5 + i * 0.5 ) => float by;
        pitchOrbs[i].pos( @(bx, by, 0) );
        orbLights[i].pos( @(bx, by, 0.8) );
    }

 
    // transitions color based on current state
    stateColorListening => vec3 ringTarget;
    if( vizState == ANALYZING ) stateColorAnalyzing => ringTarget;
    else if( vizState == RESPONDING ) stateColorResponding => ringTarget;
    else if( vizState == COOLDOWN ) stateColorCooldown => ringTarget;

    // toward target color
    stateRing.color() => vec3 curRingColor;
    curRingColor + (ringTarget - curRingColor) * Math.min(1.0, dt * 3.0) => vec3 newRingColor;
    stateRing.color( newRingColor );
    stateRing.emission( newRingColor * 0.3 );

    // ring pulses gently
    1.0 + 0.03 * Math.sin( timeS * 2.0 ) => float ringPulse;
    if( vizState == RESPONDING )
        1.0 + 0.06 * Math.sin( timeS * 4.0 ) => ringPulse;
    stateRing.pos( @(0, ORBIT_Y_OFFSET, 0) );
    stateRing.sca( @(3.8 * ringPulse, 3.8 * ringPulse, 0.04) );

    // slow rotation
    dt * 0.15 => stateRing.rotateZ;

    // update particles 
    for( 0 => int i; i < NUM_PARTICLES; i++ )
    {
        // move by velocity
        particlePos[i] + particleVel[i] * dt => particlePos[i];

        // wrap around edges 
        particlePos[i].x => float px;
        particlePos[i].y => float py;
        particlePos[i].z => float pz;
        if( px > 6 ) -6.0 => px;
        if( px < -6 ) 6.0 => px;
        if( py > 6 ) -6.0 => py;
        if( py < -6 ) 6.0 => py;
        @(px, py, pz) => particlePos[i];

        // twinkle w sine
        particlePhase[i] + dt * Math.random2f(1.5, 3.0) => particlePhase[i];
        particleBaseSizes[i] * (0.7 + 0.3 * Math.sin( particlePhase[i] )) => float twinkleSize;

        // get bigger when louder
        twinkleSize * (1.0 + vizRMS * 5.0) => particleSizes[i];

        // color shift
        if( vizState == RESPONDING )
        {
            // go to root color
            particleColors[i] + (orbColors[detectedRoot] - particleColors[i]) * dt * 0.5 => particleColors[i];
        }
        else
        {
            // otherwise go back to default
            @( Math.random2f(0.5, 1.0), Math.random2f(0.6, 1.0), Math.random2f(0.8, 1.0) ) => vec3 defaultColor;
            particleColors[i] + (defaultColor - particleColors[i]) * dt * 0.2 => particleColors[i];
        }
    }

    // upload updated particle data to gpu
    particles.positions( particlePos );
    particles.colors( particleColors );
    particles.sizes( particleSizes );


    // only show the chord name during response, nothing otherwise
    statusText.text( "" );

    if( convState == RESPONDING )
        chordText.text( pcNames[detectedRoot] + " " + qualNames[detectedQuality] );
    else
        chordText.text( "" );

    // --- camera sway ---
    camPhase + dt * 0.2 => camPhase;
    cam.posX( 0.4 * Math.sin( camPhase ) );
    cam.posY( 0.3 * Math.sin( camPhase * 0.7 ) );
}
