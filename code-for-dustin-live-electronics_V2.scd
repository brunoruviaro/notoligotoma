// 4 or 6 contact mics
// going to a mixer or audio interface
// getting to SC as 2, 4, or 6 separate channels
// (decide which is best)

// each mic acts as trigger
// once instrument is hit, amp spike is detected
// and a resulting bleep is played.

// electronics diffused through pair of studio monitors blended with percussion setup
// probably at chest level, behind percussion set up

// electronic notes are pulled from a markov chain of possible tones; derived from data
// ie, certain tones and sequences of tones have higher probability than others, etc

// electronic notes start very short and high pitched
// over time, electronic notes increase in release time (less short) and increase pitch range (octave span)

// over time, glissando is added (either going *into* the stable pitch, or going *out* of the stable pitch)

// percussion hit influences relative amp of electronic note

// ventral notes have no newly triggered electronics other than leftover decaying ringing from previous dorsal section


s.waitForBoot({

	var ring = Pgeom(0.05, 1.01, inf).asStream;
	// var ring = Pseq([Pgeom(0.1, 1.005, 100), Pwhite(0.1, 10)], inf).asStream;
	var rel = Pseq([
		Pwhite(0.01, 0.02, 10), // stay small for a while
		Pwrand( // then alternate 90% smalls with a 10% longs, growing
			[
				Pwhite(0.01, 0.02, 1),
				Pwhite(1, 2.0, 1)
			],
			[0.9, 0.1], inf) * Pseries(1, 0.01)
	]).asStream;
	var glissLo = Pseries(1, -0.01).asStream;
	var glissHi = Pseries(1, 0.01).asStream;
	var glissEnd = Prand([
		Pwhite(0.9, 1.1, 1),
		Pwhite(max(Pfuncn(glissLo), 0.5), min(Pfuncn(glissHi), 3))
	], inf).asStream;


	// quick function for transposing sine freqs to a constrained high octave
	~transp = { arg freq, min, max;
		while({ freq < min }, { freq = freq * 2 });
		if(freq > max, { freq = freq / 2 });
		freq;
	};


	// soundFunc => what happens each time there's a hit

	~soundFunc = { arg amp = 0.5;
		var note = ~markovStream.next;
		var fundamental = note.midicps;
		var ringing = ring.next;
		var releasing = rel.next;
		var glissing = glissEnd.next;
		var favoriteNotes = [60, 64, 65, 69, 71];

		if(favoriteNotes.includes(note) && (ringing > 6),
			{ ringing = ringing * rrand(1, 1.5) },
			{ ringing = min(ringing * rrand(0.5, 1), 20) }
		);

		if(favoriteNotes.includes(note).not,
			{ fundamental = fundamental * 2 },
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
				\klankGliss, [0, 0, 0, 0, 0, 1].choose,
				\amp, amp, // global amp scaling factor
				\ring, ringing, // global ring scaling factor
			]
		); // end of Klank Synth

		Synth(\siney,
			[
				\freq, ~transp.value(freq: fundamental, min: 2000, max: 15000),
				\amp, amp,
				\att, 0.01,
				\rel, releasing,
				\cur, wchoose([-10, -4, -1], [0.3, 0.6, 0.1]),
				\glissEnd, glissing

			]
		); // end of Siney synth

	};

	// load data
	"data-source.scd".loadRelative;

	// SynthDefs
	SynthDef("siney", { arg amp = 0.1, freq = 3000, att = 0.1, rel = 1, cur = -5, glissEnd = 1;
		var snd, env;
		var freqEnv = XLine.kr(start: 1, end: glissEnd, dur: rel);
		env = Env.perc(
			attackTime: att,
			releaseTime: rel,
			level: amp,
			curve: cur
		);
		snd = SinOsc.ar(
			freq: freq * freqEnv * Array.fill(20, { rrand(0.99, 1.01) }),
			mul: env.kr(doneAction: 2)
		);
		snd = Mix.ar(snd);
		snd = snd * AmpComp.kr(freq, 100);
		snd = LPF.ar(snd, 18000) * 0.1;
		Out.ar(0, [snd, snd]);
	}).add;

	SynthDef("dynKlank", { arg freq = 440, amp = 0.2, ring = 1, klankGliss = 0, whenGliss = 0.5, whereGliss = 2;
		var klank, source, frequencies, amplitudes, ringtimes, snd, ampEnv;

		frequencies = NamedControl.kr(\klankPartials, [1, 2, 3.5, 4]) * freq;
		amplitudes = NamedControl.kr(\klankAmps, [1, 0.4, 0.5, 0.8]).normalizeSum;
		ringtimes = NamedControl.kr(\klankRings, [0.5, 0.7, 0.4, 1]) * ring;

		frequencies = Select.kr(klankGliss,
			[
				frequencies,
				frequencies * Env.pairs([[0, 1], [ring * whenGliss, 1], [ring, whereGliss]], \sin).kr
			]
		);

		source = Select.ar(Rand(0, 1).round(1),
			[
				Blip.ar(20, 200, 0.1) * XLine.ar(1, 0.00001, 0.01),
				Impulse.ar(0, 0, 0.2),
			]
		);

		ampEnv = Env.linen(
			attackTime: 0.005,
			sustainTime: ring*2,
			releaseTime: 0.01,
			level: amp,
		).kr(doneAction: 2);

		klank = DynKlank.ar(
			specificationsArrayRef: `[frequencies, amplitudes, ringtimes],
			input: source
		);

		snd = klank * ampEnv;
		snd = Mix.ar(snd);
		// snd = LPF.ar(snd, 18500);
		Out.ar(0, [snd, snd]);
	}).add;


	s.sync;

	// amp follower stuff
	~amplitudeAnalysis = {arg in, rate = 20, amp = 0.1, time = 0.05;
		var input = SoundIn.ar(in);
		var inAmp = Amplitude.kr(input);
		// var trig = Impulse.kr(rate);
		var trig = 1 - DetectSilence.ar(in: input + Impulse.kr(0), amp: amp, time: time);
		SendReply.ar(trig, '/analysis', [inAmp]);
	}.play;

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
	