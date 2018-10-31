// ====================
// Notoligotoma
// Synth Definitions
// (includes amplitude follower synth at the bottom)
// ====================

s.waitForBoot({
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
		snd = LPF.ar(snd, 18500);
		Out.ar(0, [snd, snd]);
	}).add;

	SynthDef("amplitudeAnalysis", {arg rate = 20, amp = 0.1, time = 0.05;
		var input, inAmp, trig;
		input = Mix.ar(SoundIn.ar([0, 1]));
		inAmp = Amplitude.kr(input);
		// var trig = Impulse.kr(rate);
		trig = 1 - DetectSilence.ar(in: input + Impulse.kr(0), amp: amp, time: time);
		SendReply.ar(trig, '/analysis', [inAmp]);
	}).add;

	"Noto-SynthDefs.scd loaded!".postln;

}); // end of waitForBoot

