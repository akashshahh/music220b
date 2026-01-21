Music 220b - HW1 README
Akash Shah

================================================================================
SOUND LOGO
================================================================================

Ideas/Comments:
- Built using 4 sawtooth oscillators routed through JCRev reverb
- 9-chord progression with varying durations (2s, 3s, 1s, 2s, 1s, 1s, 1.5s, 1.5s, 5s)
- Smooth frequency slides (portamento) between chords using sporked slide functions
- Each voice glides independently over 0.5 seconds to create evolving harmonies
- Low reverb mix (0.1) for subtle spatial depth without washing out the sound

[TODO: Add your personal artistic intent and any additional comments]

================================================================================
CHUCKU 1: MAJOR 7TH (chucku1_major7.ck)
================================================================================

Ideas/Comments:
- Triangle oscillator through JCRev reverb (40% mix)
- Plays A major 7th chord: A (220Hz), C# (277Hz), E (330Hz), G# (415Hz)
- Each note held for 500ms
- Simple ascending arpeggio demonstrating basic oscillator and timing

[TODO: Add your thoughts on this chucku]

================================================================================
CHUCKU 2: REVERBEEP (chucku2_reverbeep.ck)
================================================================================

Ideas/Comments:
- Triangle oscillator at 220Hz (A3) through JCRev reverb
- Rhythmic on/off pattern: 100ms on, 100ms off, repeated 4 times
- Demonstrates gain control for creating rhythmic patterns
- Reverb adds tail to each beep

[TODO: Add your thoughts on this chucku]

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

[TODO: Describe any challenges you faced while creating these programs]

