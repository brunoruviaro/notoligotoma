 // NOT FUNCTIONAL

// I'm just using this as a copy/paste source to create cleaner, neatly separated files. Eventually this file will be deprecated.

// Currently the working file for testing is V3.


// 4 or 6 contact mics
// going to a mixer or audio interface
// getting to SC as 2, 4, or 6 separate channels
// (decide which is best)


// Load data file
if(~thisFile == \loaded, { "done".postln }, { "data-source.scd".loadRelative });

// this variable affects when larger rel times and gliss ranges start to show up;
~numberOfHitsUntilSomethingChanges = 100;

// Everything else
s.waitForBoot({

	// KLANK ringing factor increases over time
	var ring = Pgeom(0.05, 1.01, inf).asStream;
	// var ring = Pseq([Pgeom(0.1, 1.005, 100), Pwhite(0.1, 10)], inf).asStream;

	// SINE release: occasional long notes amidst mostly staccato notes
	var rel = Pseq([
		Pwhite(0.01, 0.02, ~numberOfHitsUntilSomethingChanges), // stay small for a while
		Pwrand( // then alternate 90% smalls with a 10% longs, growing
			[
				Pwhite(0.01, 0.02, 1),
				Pwhite(1, 2.0, 1)
			],
			[0.9, 0.1], inf) * Pseries(1, 0.01)
	]).asStream;

	// SINE glissando controls: range increases over time; [0.5, 3] is maximum allowed
	var glissLo = Pseries(1, -0.01).asStream;
	var glissHi = Pseries(1, 0.01).asStream;
	var glissEnd = Pseq([
		Pwhite(0.9, 1.2, ~numberOfHitsUntilSomethingChanges),
		Prand([
			Pwhite(0.9, 1.1, 1),
			Pwhite(max(Pfuncn(glissLo), 0.5), min(Pfuncn(glissHi), 3))
		], inf)
	], inf).asStream;

	// multiplier used to sometimes alter fundamental away from markov chain notes
	var sinFreqDeviation = Pseq([
		Pwhite(0.9, 1.1, ~numberOfHitsUntilSomethingChanges*2), // stay small for a while
		Pwrand( // then alternate 90% "in tune" with markov notes with 10% off those notes
			[
				1,
				Pwhite(0.9, 1.3, 1)
			],
			[0.9, 0.1], inf)
	]).asStream;


	// quick function for transposing sine freqs to a constrained high octave
	~transp = { arg freq, min, max;
		while({ freq < min }, { freq = freq * 2 });
		if(freq > max, { freq = freq / 2 });
		freq;
	};


	// soundFunc => what happens each time there's a hit
	// this function will be called from amplitude follower

	~soundFunc = { arg amp = 0.5;
		var note = ~markovStream.next;
		var fundamental = note.midicps;
		var ringing = ring.next;
		var releasing = rel.next;
		var glissing = glissEnd.next;
		var favoriteNotes = [60, 64, 65, 69, 71]; // harmony to be emphasized over time

		// emphasis on favorite note harmony through longer rings
		if(favoriteNotes.includes(note) && (ringing > 6),
			{ ringing = ringing * rrand(1, 1.5) },
			{ ringing = min(ringing * rrand(0.5, 1), 20) }
		);

		// keep favorite notes at original lower octave; everybody else goes octave above, with maybe a large detuning
		if(favoriteNotes.includes(note).not,
			{ fundamental = fundamental * 2 * sinFreqDeviation.next },
			{ "keep fundamental at original octave" }
		);

		// after a slow increase of ring time, boost it after ring=2sec
		// (skip from around 2 seconds to 4-5 seconds and longer)
		if(ringing > 2.0, { ringing = ringing * rrand(1.5, 2) });

		// cap ring time to 30 seconds
		ringing = min(ringing, 20);

		// similar cap control for rel (a little more relaxed)
		// releasing = if(releasing < 15, { releasing }, { releasing * rrand(0.3, 1)});

		[note, ringing, releasing, glissing].round(0.01).postln;

		Synth(\dynKlank,
			[
				\freq, fundamental,
				\klankPartials, { Array.fill(4, { rrand(-0.01, 0.01) }) + [1, 1.0001, 1.99998, 1.999] }.value,
				\klankAmps, [1, 1/2, 1/3, 1/4],
				\klankRings, [1, 1/2, 1, 1/2],
				\klankGliss, [0, 0, 0, 0, 1].choose,
				\whenGliss, 0.5,
				\amp, amp * min(ringing, 1), // global amp scaling factor
				\ring, ringing, // global ring scaling factor
			]
		); // end of Klank Synth

		Synth(\siney,
			[
				\freq, ~transp.value(freq: fundamental, min: 2000, max: 15000) * sinFreqDeviation.next,
				\amp, amp,
				\att, 0.01,
				\rel, releasing,
				\cur, wchoose([-10, -4, -1], [0.3, 0.6, 0.1]),
				\glissEnd, glissing

			]
		); // end of Siney synth

	}; // end of soundFunc



	// Listen for hits:
	OSCdef(\listener, {arg msg;
		var amp = msg[3].round(0.0001);
		amp.postln;
		~soundFunc.value(amp)
	}, '/analysis');

}); // end of waitForBoot






















// try other values if needed
// ~amplitudeAnalysis.set(\amp, 0.1, \time, 0.02);






/*

// ~soundFunc.value(0.1)

// testing only
/* (
p = Pbind(
\instrument, \playSample,
\buf, Pseq(~newDataMapping, 1),
\dur, 0.15 + Pwhite(0.009, 0.008) * Prand([Pn(Pgeom(1, 1.1, 13)), Pn(1, 4)], inf),
// \dur, 1/3,
// \amp, Pfunc({arg ev; if(ev[\buf]==140 , {0.0}, {0.3}) }) * Pn(Pseries(1, -0.1, 8)),
\amp, Pwrand([0, 0.2], [0.5, 0.5], inf),
// \rate, Pseries([0.5, 1], [0.0001, 0], inf),
\name, Pfunc({ arg ev; [
~soundFunc.value(ev[\amp]);
~dustin[ev[\buf]].bufnum,
~dustin[ev[\buf]].path.drop(~dropChars)
].postln }),
).play;
)
*/

(
Synth(\dynKlank,
[
\freq, rrand(1, 5).round(1) * [1000, 2050].choose,
\klankPartials, { Array.fill(4, { rrand(-0.01, 0.01) }) + [1, 1.0001, 1.99998, 1.999] }.value,
\klankAmps, [1, 1/2, 1/3, 1/4],
\klankRings, [1, 1/2, 1, 1/2],
\klankGliss, [1, 0].choose,
\whenGliss, rrand(0.1, 0.2),
\whereGliss, [rrand(1.5, 2), rrand(0.5, 0.65)].choose,
\amp, 0.4, // global amp scaling factor
\ring, rrand(15, 10), // global ring scaling factor
]
);
)
*/
