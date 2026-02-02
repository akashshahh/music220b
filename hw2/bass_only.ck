"pitch pipe c.wav" => string SAMPLE_FILE;
60 => int ROOT_NOTE;

90 => float BPM;
(60.0 / BPM)::second => dur BEAT;

dac => WvOut wv => blackhole;
"bass.wav" => wv.wavFilename;

SndBuf voice => dac;
SAMPLE_FILE => voice.read;
voice.samples() => voice.pos;
0.6 => voice.gain;

fun float semitoneToRatio(int semitones) {
    return Math.pow(2, semitones / 12.0);
}

fun void playNote(int midiPitch) {
    semitoneToRatio(midiPitch - ROOT_NOTE) => voice.rate;
    0 => voice.pos;
}

fun void stopNote() {
    voice.samples() => voice.pos;
}

MidiFileIn min;
if (!min.open("homebrew bass.mid")) {
    <<< "Error: couldn't open MIDI file" >>>;
    me.exit();
}

<<< "=== BASS ONLY ===" >>>;

min.ticksPerQuarter() => float tpq;

MidiMsg msg;
while (min.read(msg)) {
    if (msg.when > 0::second) {
        msg.when => now;
    }

    if ((msg.data1 & 0xF0) == 0x90 && msg.data3 > 0) {
        playNote(msg.data2);
    }
    if ((msg.data1 & 0xF0) == 0x80 || ((msg.data1 & 0xF0) == 0x90 && msg.data3 == 0)) {
        stopNote();
    }
}

wv.closeFile();
<<< "Saved bass.wav" >>>;
