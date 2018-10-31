// ================================================
// Notoligotoma
// Piece for percussion and electronics
// October 2018
// Bruno Tucunduva Ruviaro
//
// PLAYER file
//
// TO RUN:
// Select all (Ctrl+A) and evaluate (Ctrl+Enter)
//
// TO STOP: Ctrl + Period
//
// BEFORE YOU RUN - REQUIREMENT: wslib quark and MathLib quark
// Quarks.install("MathLib");
// Quarks.install("wslib");
// =================================================


{
	// Choose which contact mic hitNumber to start from
	~startFrom = 1;

	// =================================
	// Read raw data and process it
	"Noto-Data-Reader.scd".loadRelative;

	0.1.wait;
	// =================================
	// Load sections dictionary
	"Noto-Sections-Dictionary.scd".loadRelative;

	0.1.wait;
	// =================================
	// Load sound function
	"Noto-Sound-Function.scd".loadRelative;

	0.1.wait;
	// =================================
	// Boot server and load Synth Definitions
	"Noto-SynthDefs.scd".loadRelative;

	"wait...".postln;
	3.wait;
	// =================================
	// Start amp detection synth
	"Noto-Amplitude-Synth.scd".loadRelative;

}.fork;





// use this for testing without contact mic
x = { Out.ar(2, WhiteNoise.ar(LFPulse.ar(freq: MouseX.kr(1, 20), width: 0.1))) }.play;
x.free;


