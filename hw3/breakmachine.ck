// ==========================================
// breakmachine.ck - Breakcore Drum Machine
// Music 220b HW3 - Milestone 1
// ==========================================

//things to add: sidechain, mutation knob/touchpad listener,
//drop function, more toggles to add/remove stuff

350::ms => dur Q; // ~170 BPM quarter note
Q/4 => dur S;     // sixteenth note


class MyEvent extends Event
{
    0 => int measure;
    0 => int n;
    16 => int max;
    1 => int keepGoing;

    fun void next()
    { n++; if( n >= max ) { 0 => n; measure++; } }
}
MyEvent boom;


NRev rL => dac.left;
NRev rR => dac.right;
.03 => rL.mix => rR.mix;

// record output to WAV
dac => WvOut2 rec => blackhole;
"recording" => rec.wavFilename;


SndBuf bank[9];
Pan2 pan[9];

me.dir() + "BANGER DNB KIT 2/" => string kit;
kit + "Dark_Kick13.wav" => bank[0].read;        // kick 1 (heavy)
kit + "Temple_Kick01.wav" => bank[1].read;       // kick 2 (punchy)
kit + "Dark_Snare02.wav" => bank[2].read;        // snare 1
kit + "Future_Snare10.wav" => bank[3].read;      // snare 2
kit + "Liquid_Snare20.wav" => bank[4].read;      // snare 3
kit + "Future_Hat16.wav" => bank[5].read;        // closed hat
kit + "Liquid_Hat34.wav" => bank[6].read;        // open hat
kit + "Liquid_Crash11.wav" => bank[7].read;      // crash
kit + "Liquid_Percussion43.wav" => bank[8].read; // perc


for( int i; i < 9; i++ )
{
    0 => bank[i].gain;
    bank[i] => pan[i];
    pan[i].left => rL;
    pan[i].right => rR;
}

-.3 => pan[0].pan;  // kick heavy left
 .3 => pan[1].pan;  // kick punchy right
-.2 => pan[2].pan;  // snare 1
 .2 => pan[3].pan;  // snare 2
  0 => pan[4].pan;  // snare 3 center
-.5 => pan[5].pan;  // closed hat left
 .5 => pan[6].pan;  // open hat right
  0 => pan[7].pan;  // crash center
-.4 => pan[8].pan;  // perc left


fun void play( int n )
{ play( n, Math.random2f(.8, 1) ); }

fun void play( int n, float v )
{ play( n, v, Math.random2f(.98, 1.02) ); }

fun void play( int n, float v, float r )
{
    if( n < 0 || n >= 9 ) return;
    0 => bank[n].pos;
    v => bank[n].gain;
    r => bank[n].rate;
}


class Pattern
{
    1 => float volume;
    float probs[16];
}

class DrumPattern extends Pattern
{
    int sound;
    1 => int active;

    fun void run( int N )
    {
        int n;
        while( N != 0 && boom.keepGoing )
        {
            if( N > 0 ) N--;
            boom => now;
            boom.n => n;
            if( probs[n] > 0 && active )
            { play( sound, probs[n] * volume ); }
        }
    }
}


fun void copyPat( float src[], float dst[] )
{
    for( 0 => int i; i < 16; i++ )
    { src[i] => dst[i]; }
}



[ 1.0, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.8, 0.0,
  0.0, 0.0, 1.0, 0.0,
  0.0, 0.0, 0.0, 0.0 ] @=> float kickP0[];

[ 1.0, 0.0, 0.7, 0.0,
  0.0, 0.0, 1.0, 0.0,
  0.8, 0.0, 0.0, 0.9,
  0.0, 0.0, 0.7, 0.0 ] @=> float kickP1[];

[ 1.0, 0.0, 0.0, 0.7,
  0.0, 0.0, 0.0, 0.8,
  0.0, 0.0, 1.0, 0.0,
  0.0, 0.7, 0.0, 0.0 ] @=> float kickP2[];

[ 1.0, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.0, 0.0,
  0.9, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.0, 0.0 ] @=> float kickP3[];



[ 0.0, 0.0, 0.0, 0.0,
  1.0, 0.0, 0.0, 0.3,
  0.0, 0.0, 0.0, 0.0,
  1.0, 0.0, 0.2, 0.5 ] @=> float snareP0[];

[ 0.0, 0.0, 0.3, 0.5,
  1.0, 0.7, 0.5, 0.3,
  0.0, 0.2, 0.4, 0.6,
  1.0, 0.8, 0.6, 0.4 ] @=> float snareP1[];

[ 0.2, 0.0, 0.15, 0.0,
  1.0, 0.1, 0.2,  0.3,
  0.1, 0.0, 0.2,  0.1,
  1.0, 0.2, 0.3,  0.15 ] @=> float snareP2[];

[ 0.0, 0.0, 0.5, 0.0,
  0.0, 1.0, 0.0, 0.5,
  0.0, 0.0, 0.5, 0.0,
  0.0, 1.0, 0.0, 0.5 ] @=> float snareP3[];



[ 0.6, 0.3, 0.5, 0.3,
  0.6, 0.3, 0.5, 0.3,
  0.6, 0.3, 0.5, 0.3,
  0.6, 0.3, 0.5, 0.3 ] @=> float hatP0[];

[ 0.7, 0.0, 0.5, 0.3,
  0.0, 0.5, 0.0, 0.3,
  0.7, 0.0, 0.4, 0.3,
  0.0, 0.5, 0.3, 0.0 ] @=> float hatP1[];

[ 0.5, 0.0, 0.0, 0.3,
  0.5, 0.0, 0.7, 0.0,
  0.5, 0.0, 0.0, 0.3,
  0.5, 0.0, 0.7, 0.0 ] @=> float hatP2[];

[ 0.6, 0.0, 0.0, 0.0,
  0.5, 0.0, 0.0, 0.0,
  0.6, 0.0, 0.0, 0.0,
  0.5, 0.0, 0.0, 0.3 ] @=> float hatP3[];


[ 0.0, 0.0, 0.4, 0.0,
  0.0, 0.3, 0.0, 0.0,
  0.5, 0.0, 0.0, 0.3,
  0.0, 0.0, 0.4, 0.0 ] @=> float percP0[];


SawOsc padSaw[7];
Gain padOscG[7];
Noise padNz[7];
Gain padNzG[7];
Gain padMix[7];
LPF padLpf[7];
ADSR padEnv[7];
Gain padBus => Pan2 padPan => Gain padOut;
padOut => rL;
padOut => rR;
0.0 => padOut.gain;  // pad starts muted, toggle with 'g'


for( 0 => int i; i < 7; i++ )
{
    padSaw[i] => padOscG[i] => padMix[i];
    padNz[i] => padNzG[i] => padMix[i];
    padMix[i] => padLpf[i] => padEnv[i] => padBus;
    0.7 => padOscG[i].gain;
    0.35 => padNzG[i].gain;
    2000.0 => padLpf[i].freq;
    1.5 => padLpf[i].Q;
    padEnv[i].set( 150::ms, 50::ms, 0.7, 400::ms );
}

[ 48, 51, 55, 58, 62, 65, 69 ] @=> int chord0[];  // Cm13:  C Eb G Bb D F A
[ 44, 48, 51, 55, 58, 62, 65 ] @=> int chord1[];  // AbM13: Ab C Eb G Bb D F
[ 51, 55, 58, 62, 65, 69, 72 ] @=> int chord2[];  // EbM13: Eb G Bb D F A C
[ 43, 46, 50, 53, 57, 60, 64 ] @=> int chord3[];  // Gm13:  G Bb D F A C E
[ 41, 44, 48, 51, 55, 58, 62 ] @=> int chord4[];  // Fm13:  F Ab C Eb G Bb D


[ 0, 1, 2, 3, 4 ] @=> int progression[];
// shuffle initial order
for( progression.size() - 1 => int i; i > 0; i-- )
{
    Math.random2( 0, i ) => int j;
    progression[i] => int tmp;
    progression[j] => progression[i];
    tmp => progression[j];
}
0 => int progIdx;     // current position in progression
0 => int padActive;   // pad starts off


DrumPattern kick;
0 => kick.sound;
1.0 => kick.volume;
copyPat( kickP0, kick.probs );

DrumPattern snare;
2 => snare.sound;
0.85 => snare.volume;
copyPat( snareP0, snare.probs );

DrumPattern hat;
5 => hat.sound;
0.7 => hat.volume;
copyPat( hatP0, hat.probs );

DrumPattern perc;
8 => perc.sound;
0.6 => perc.volume;
copyPat( percP0, perc.probs );

0 => int curKick;
0 => int curSnare;
0 => int curHat;

// sidechain state
0 => int sidechainOn;
0 => int sidechainSource;  // 0=kick, 1=snare, 2=hat, 3=perc

// riser UGen chain
Noise riserNz => BPF riserBpf => Gain riserGain;
riserGain => rL;
riserGain => rR;
0.0 => riserGain.gain;
500.0 => riserBpf.freq;
4.0 => riserBpf.Q;
0 => int dropping;


fun void setKickPreset( int idx )
{
    idx % 4 => idx => curKick;
    // some presets use punchy kick (sound 1) for variety
    if( idx == 0 )      { copyPat( kickP0, kick.probs ); 0 => kick.sound; }
    else if( idx == 1 ) { copyPat( kickP1, kick.probs ); 1 => kick.sound; }
    else if( idx == 2 ) { copyPat( kickP2, kick.probs ); 0 => kick.sound; }
    else                { copyPat( kickP3, kick.probs ); 1 => kick.sound; }
    <<< "KICK preset:", idx >>>;
}

fun void setSnarePreset( int idx )
{
    idx % 4 => idx => curSnare;
    // cycle through snare sounds
    if( idx == 0 )      { copyPat( snareP0, snare.probs ); 2 => snare.sound; }
    else if( idx == 1 ) { copyPat( snareP1, snare.probs ); 3 => snare.sound; }
    else if( idx == 2 ) { copyPat( snareP2, snare.probs ); 4 => snare.sound; }
    else                { copyPat( snareP3, snare.probs ); 2 => snare.sound; }
    <<< "SNARE preset:", idx >>>;
}

fun void setHatPreset( int idx )
{
    idx % 4 => idx => curHat;
    // preset 2 uses open hat (sound 6)
    if( idx == 0 )      { copyPat( hatP0, hat.probs ); 5 => hat.sound; }
    else if( idx == 1 ) { copyPat( hatP1, hat.probs ); 5 => hat.sound; }
    else if( idx == 2 ) { copyPat( hatP2, hat.probs ); 6 => hat.sound; }
    else                { copyPat( hatP3, hat.probs ); 5 => hat.sound; }
    <<< "HAT preset:", idx >>>;
}


fun void shuffleProgression()
{
    // Fisher-Yates shuffle
    for( progression.size() - 1 => int i; i > 0; i-- )
    {
        Math.random2( 0, i ) => int j;
        progression[i] => int tmp;
        progression[j] => progression[i];
        tmp => progression[j];
    }
    <<< "PAD: shuffled progression" >>>;
}


fun void randomizePattern( float probs[], float density )
{
    for( 0 => int i; i < 16; i++ )
    {
        if( Math.random2f(0, 1) < density )
            Math.random2f(0.3, 1.0) => probs[i];
        else
            0.0 => probs[i];
    }
}

fun void mutatePattern( float probs[] )
{
    Math.random2(2, 4) => int flips;
    for( 0 => int i; i < flips; i++ )
    {
        Math.random2(0, 15) => int step;
        if( probs[step] > 0 )
            0.0 => probs[step];
        else
            Math.random2f(0.3, 1.0) => probs[step];
    }
}

fun void fullRandomize()
{
    randomizePattern( kick.probs, 0.25 );  // kicks sparse
    randomizePattern( snare.probs, 0.35 ); // snares moderate
    randomizePattern( hat.probs, 0.6 );    // hats dense
    randomizePattern( perc.probs, 0.2 );   // perc sparse
    shuffleProgression();
    <<< ">>> FULL RANDOMIZE <<<" >>>;
}

fun void mutateAll()
{
    mutatePattern( kick.probs );
    mutatePattern( snare.probs );
    mutatePattern( hat.probs );
    mutatePattern( perc.probs );
    <<< ">>> MUTATE <<<" >>>;
}

fun void resetAll()
{
    setKickPreset( 0 );
    setSnarePreset( 0 );
    setHatPreset( 0 );
    copyPat( percP0, perc.probs );
    1 => kick.active => snare.active => hat.active => perc.active;
    // reset pad progression
    0 => progression[0]; 1 => progression[1]; 2 => progression[2];
    3 => progression[3]; 4 => progression[4];
    0 => progIdx;
    <<< ">>> RESET <<<" >>>;
}


fun int[] chordForIdx( int idx )
{
    if( idx == 0 ) return chord0;
    if( idx == 1 ) return chord1;
    if( idx == 2 ) return chord2;
    if( idx == 3 ) return chord3;
    return chord4;
}

fun void playChord( int chordIdx )
{
    // key off all envelopes
    for( 0 => int i; i < 7; i++ )
    { padEnv[i].keyOff(); }
    80::ms => now; // brief gap for release

    chordForIdx( chordIdx ) @=> int notes[];
    for( 0 => int i; i < 7; i++ )
    {
        // MIDI to freq with slight detuning (±3-8 cents)
        Math.random2f( -8.0, 8.0 ) => float cents;
        Std.mtof( notes[i] + cents / 100.0 ) => padSaw[i].freq;
        padEnv[i].keyOn();
    }
}

fun void togglePad()
{
    if( padActive )
    {
        0 => padActive;
        for( 0 => int i; i < 7; i++ )
        { padEnv[i].keyOff(); }
        0.0 => padOut.gain;
        <<< "PAD: OFF" >>>;
    }
    else
    {
        1 => padActive;
        0.25 => padOut.gain;
        <<< "PAD: ON" >>>;
    }
}

fun void padRunner()
{
    while( true )
    {
        boom => now;
        if( boom.n == 0 && padActive )
        {
            progression[ progIdx % progression.size() ] => int chordIdx;
            spork ~ playChord( chordIdx );
            progIdx++;
        }
    }
}

fun void padSweep()
{
    0.0 => float phase;
    0.3 => float rate;
    2000.0 => float center;
    1000.0 => float depth;
    while( true )
    {
        center + depth * Math.sin( phase ) => float cutoff;
        for( 0 => int i; i < 7; i++ )
        { cutoff => padLpf[i].freq; }
        phase + (2.0 * Math.PI * rate * 0.01) => phase;
        10::ms => now;
    }
}


fun string sidechainSourceName()
{
    if( sidechainSource == 0 ) return "KICK";
    if( sidechainSource == 1 ) return "SNARE";
    if( sidechainSource == 2 ) return "HAT";
    return "PERC";
}

fun void toggleSidechain()
{
    if( sidechainOn )
    {
        0 => sidechainOn;
        <<< "SIDECHAIN: OFF" >>>;
    }
    else
    {
        1 => sidechainOn;
        <<< "SIDECHAIN: ON ->", sidechainSourceName() >>>;
    }
}

fun void cycleSidechainSource()
{
    (sidechainSource + 1) % 4 => sidechainSource;
    <<< "SIDECHAIN source:", sidechainSourceName() >>>;
}

fun void duckPad( float intensity )
{
    0.25 => float baseGain;
    // duck depth proportional to hit intensity (nearly silent on hard hits)
    baseGain * (1.0 - 0.95 * intensity) => float duckGain;
    // fast attack
    duckGain => padOut.gain;
    // smooth release over ~4 sixteenth notes for big pump
    S * 4 => dur relTime;
    20 => int steps;
    relTime / steps => dur stepDur;
    for( 0 => int i; i < steps; i++ )
    {
        duckGain + (baseGain - duckGain) * ((i + 1) $ float / steps) => padOut.gain;
        stepDur => now;
    }
    baseGain => padOut.gain;
}

fun void toggleDrum( DrumPattern p, string name )
{
    if( p.active )
    {
        0 => p.active;
        <<< name, ": MUTED" >>>;
    }
    else
    {
        1 => p.active;
        <<< name, ": ON" >>>;
    }
}

fun void doDrop()
{
    if( dropping ) return;
    1 => dropping;
    <<< ">>> RISER (waiting for downbeat) <<<" >>>;

    // sync to top of next measure
    while( boom.n != 0 )
    { boom => now; }
    <<< ">>> RISER GO <<<" >>>;

    // riser: 4 bars (64 sixteenth notes)
    64 => int riserSteps;
    200.0 => float startFreq;
    10000.0 => float endFreq;

    for( 0 => int i; i < riserSteps; i++ )
    {
        i $ float / riserSteps => float t;
        // exponential frequency sweep
        startFreq * Math.pow( endFreq / startFreq, t ) => riserBpf.freq;
        // ramp gain up
        t * t * 0.8 => riserGain.gain;
        // tighten Q as it rises
        4.0 + t * 14.0 => riserBpf.Q;

        // gradually strip out drums
        if( i == riserSteps / 2 )     { 0 => hat.active; 0 => perc.active; }
        if( i == riserSteps * 3 / 4 ) { 0 => snare.active; }
        if( i == riserSteps * 7 / 8 ) { 0 => kick.active; }

        S => now;
    }

    // kill riser, mute everything for last bar of silence
    0.0 => riserGain.gain;
    0 => kick.active;
    0 => snare.active;
    0 => hat.active;
    0 => perc.active;
    0 => padActive;
    0.0 => padOut.gain;
    for( 0 => int i; i < 7; i++ )
    { padEnv[i].keyOff(); }
    // wait one full bar of silence (16 steps) so drop lands on downbeat
    S * 16 => now;

    // THE DROP - crash + hard reset on the 1
    play( 7, 1.0 );
    resetAll();
    1 => padActive;
    0.25 => padOut.gain;

    0 => dropping;
    <<< ">>> DROP <<<" >>>;
}


fun void sidechainPump()
{
    while( true )
    {
        boom => now;
        if( !sidechainOn || !padActive ) continue;

        // check if selected pattern has a hit this step
        0.0 => float hitVol;
        if( sidechainSource == 0 )      kick.probs[boom.n] => hitVol;
        else if( sidechainSource == 1 ) snare.probs[boom.n] => hitVol;
        else if( sidechainSource == 2 ) hat.probs[boom.n] => hitVol;
        else                            perc.probs[boom.n] => hitVol;

        if( hitVol > 0 )
        { spork ~ duckPad( hitVol ); }
    }
}


fun void keyboardListener()
{
    HidIn hi;
    HidMsg msg;

    if( !hi.openKeyboard(0) )
    {
        <<< "WARNING: no keyboard found" >>>;
        return;
    }
    <<< "Keyboard connected for input" >>>;

    while( true )
    {
        hi => now;
        while( hi.recv( msg ) )
        {
            if( msg.isButtonDown() )
            {
                msg.ascii => int key;
                // normalize uppercase to lowercase
                if( key >= 65 && key <= 90 ) key + 32 => key;

                // kick presets: 1-4
                if( key == 49 )      setKickPreset( 0 );  // 1
                else if( key == 50 ) setKickPreset( 1 );  // 2
                else if( key == 51 ) setKickPreset( 2 );  // 3
                else if( key == 52 ) setKickPreset( 3 );  // 4

                // snare presets: q w e r
                else if( key == 113 ) setSnarePreset( 0 ); // q
                else if( key == 119 ) setSnarePreset( 1 ); // w
                else if( key == 101 ) setSnarePreset( 2 ); // e
                else if( key == 114 ) setSnarePreset( 3 ); // r

                // hat presets: a s d f
                else if( key == 97 )  setHatPreset( 0 );  // a
                else if( key == 115 ) setHatPreset( 1 );  // s
                else if( key == 100 ) setHatPreset( 2 );  // d
                else if( key == 102 ) setHatPreset( 3 );  // f

                // randomize / mutate / reset
                else if( key == 122 ) fullRandomize();     // z
                else if( key == 120 ) mutateAll();         // x
                else if( key == 99 )  resetAll();          // c

                // pad controls
                else if( key == 116 ) shuffleProgression(); // t
                else if( key == 103 ) togglePad();          // g

                // mute toggles: 5-8
                else if( key == 53 ) toggleDrum( kick,  "KICK" );   // 5
                else if( key == 54 ) toggleDrum( snare, "SNARE" );  // 6
                else if( key == 55 ) toggleDrum( hat,   "HAT" );    // 7
                else if( key == 56 ) toggleDrum( perc,  "PERC" );   // 8

                // sidechain controls
                else if( key == 118 ) toggleSidechain();       // v
                else if( key == 98 )  cycleSidechainSource();  // b

                // drop
                else if( key == 110 ) spork ~ doDrop();        // n

                // crash: space
                else if( key == 32 )  play( 7, 1.0 );     // space
            }
        }
    }
}


spork ~ kick.run( -1 );
spork ~ snare.run( -1 );
spork ~ hat.run( -1 );
spork ~ perc.run( -1 );
spork ~ keyboardListener();
spork ~ padRunner();
spork ~ padSweep();
spork ~ sidechainPump();

me.yield();

// === PRINT CONTROLS ===
<<< "=== BREAKCORE DRUM MACHINE ===" >>>;
<<< "170 BPM | 16-step sequencer" >>>;
<<< "---" >>>;
<<< "1-4 : kick presets" >>>;
<<< "5-8 : mute kick/snare/hat/perc" >>>;
<<< "q w e r : snare presets" >>>;
<<< "a s d f : hat presets" >>>;
<<< "t : shuffle pad chords" >>>;
<<< "g : toggle pad on/off" >>>;
<<< "v : toggle sidechain on/off" >>>;
<<< "b : cycle sidechain source (kick>snare>hat>perc)" >>>;
<<< "n : drop (riser + crash)" >>>;
<<< "z : full randomize" >>>;
<<< "x : mutate (subtle)" >>>;
<<< "c : reset to defaults" >>>;
<<< "space : crash hit" >>>;
<<< "---" >>>;


while( true )
{
    boom.broadcast();
    S => now;
    boom.next();
}
