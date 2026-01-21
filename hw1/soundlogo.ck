SawOsc saw1 => JCRev reverb => dac;
SawOsc saw2 => reverb;
SawOsc saw3 => reverb;
SawOsc saw4 => reverb;


0.1 => reverb.mix;

0.15 => saw1.gain => saw2.gain => saw3.gain => saw4.gain;

[[207.01, 207.01, 207.01, 207.01],  
 [116.5, 207.01, 261.63, 277.18],   
 [116.5, 207.01, 207.01, 277.18],   
 [116.5, 155.56, 196.00, 311.13],   
 [103.83, 174.61, 261.63, 311.13],  
 [103.83, 155.56, 196.00, 311.13],  
 [138.59, 174.61, 174.61, 349.23],  
 [97.999, 174.61, 246.94, 392.00],  
 [130.81, 196.00, 246.94, 329.63]]  
 @=> float chords[][];


[2.0, 3.0, 1.0, 2.0, 1.0, 1.0, 1.5, 1.5, 5.0] @=> float durations[];


0.5 => float slideTime;


fun void slide(SawOsc osc, float startFreq, float endFreq, dur slideTime) {
    startFreq => osc.freq;
    (endFreq - startFreq) / (slideTime / 1::ms) => float step;
    for(0 => int i; i < (slideTime / 1::ms); i++) {
        osc.freq() + step => osc.freq;
        1::ms => now;
    }
    endFreq => osc.freq;
}


for(0 => int i; i < chords.size(); i++) {

    if(i > 0) {
        spork ~ slide(saw1, chords[i-1][0], chords[i][0], slideTime::second);
        spork ~ slide(saw2, chords[i-1][1], chords[i][1], slideTime::second);
        spork ~ slide(saw3, chords[i-1][2], chords[i][2], slideTime::second);
        spork ~ slide(saw4, chords[i-1][3], chords[i][3], slideTime::second);
        slideTime::second => now;
    } else {

        chords[i][0] => saw1.freq;
        chords[i][1] => saw2.freq;
        chords[i][2] => saw3.freq;
        chords[i][3] => saw4.freq;
    }
    

    durations[i]::second => now;
}



