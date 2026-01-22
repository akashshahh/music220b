Music 220b - HW1 README
Akash Shah

================================================================================
SOUND LOGO - Stanford Mendicants
================================================================================

Ideas/Comments:
- Sound logo for the Stanford Mendicants, Stanford's oldest a cappella group
- I am the Music Director of the group
- Based on a barbershop tag I arranged, modeled after "All The Things You Are" chord progression
- Transcribed my 4-part vocal arrangement into ChucK:
  - 4 sawtooth oscillators represent the 4 voice parts (top, lead, bari, bass)
  - Smooth frequency slides mimic how voices glide between notes
  - JCRev reverb mimick the warmth of singing in a resonant space
- 9-chord progression with varying durations to match the phrasing of the original tag
- Low reverb mix (0.1) keeps the harmonies clear 

================================================================================
CHUCKU 1: MAJOR 7TH (chucku1_major7.ck)
================================================================================

Ideas/Comments:
- Triangle oscillator through JCRev reverb (40% mix)
- Plays major 7th chord: A (220Hz), C# (277Hz), E (330Hz), G# (415Hz)
- Each note held for 500ms
- Simple ascending arpeggio demonstrating basic oscillator and timing


================================================================================
CHUCKU 2: REVERBEEP (chucku2_reverbeep.ck)
================================================================================

Ideas/Comments:
- Triangle oscillator at 220Hz (A3) through JCRev reverb
- Rhythmic on/off pattern: 100ms on, 100ms off, repeated 4 times
- Demonstrates gain control for creating rhythmic patterns
- Reverb adds tail to each beep

================================================================================
RUNNING INSTRUCTIONS
================================================================================

Requirements:
- ChucK audio programming language (https://chuck.cs.princeton.edu/)

To run any of the programs:
    chuck filename.ck

Examples:
    chuck soundlogo.ck
    chuck chucku1_major7.ck
    chuck chucku2_reverbeep.ck

================================================================================
DIFFICULTIES ENCOUNTERED
================================================================================

The only difficulty I really encountered was that it was a little cumbersome to transfer melodies/harmonies into chuck by transcribing frequencies, but that's by nature. 
