// ====================
// Notoligotoma
//
// OSC Listener and Sound Function
//
// OSC Listener: listens for contact mic hits (coming from a server SendReply).
// Sound Function: what to do once a contact mic hit is detected.
// ====================



/////////////////
// OSC Listener
/////////////////

OSCdef(\listener, {arg msg;
	var hitNumber = ~hitNumber.next; // keep running count of all contact mic hits
	var amp = msg[3].round(0.0001);
	["HIT NUMBER", hitNumber].postln;
	["hit amp", amp].postln;
	// Check if parameters need updating, and if yes, update them now.
	~checkForUpdates.value(hitNumber);
	~soundFunc.value(amp)
}, '/analysis');



///////////////////////////////////////
// Running count for contact mic hits
///////////////////////////////////////

~hitNumber = Pseries(~startFrom, 1, inf).asStream;


/////////////////////////////////////////////
// Sound Function
// => what happens each time there's a hit
/////////////////////////////////////////////

~soundFunc = { arg amp = 0.5;

	var midinote = ~markovStream.next;
	var klankFreq = ~klankFreq.value(midinote);
	var klankRingTime = ~klankRingTime.value(midinote);
	var sineFreq = ~sineFreq.value(midinote);
	var sineReleaseTime = ~sineReleaseTime.value;
	var sineGlissEnd = ~sineGlissEnd.value;


	["klankFreq", klankFreq.round(1)].postln;
	["klankRingTime", klankRingTime.round(0.01)].postln;
	["sineFreq", sineFreq.round(1)].postln;
	["sineReleaseTime", sineReleaseTime.round(0.01)].postln;
	["sineGlissEnd", sineGlissEnd.round(0.1)].postln;
	"==================".postln;
	// Post current count




	Synth(\dynKlank,
		[
			\freq, klankFreq,
			\klankPartials, { Array.fill(
				size: 4,
				function: { rrand(-0.01, 0.01) }) + [1, 1.0001, 1.99998, 1.999] }.value,
			\klankAmps, [1, 1/2, 1/3, 1/4],
			\klankRings, [1, 1/2, 1, 1/2],
			\klankGliss, [0, 0, 0, 0, 1].choose,
			\whenGliss, 0.5,
			\amp, amp; // * min(klankRingTime, 1), // global amp scaling factor
			\ring, klankRingTime; // global ring scaling factor
		]
	); // end of Klank Synth

	Synth(\siney,
		[
			\freq, sineFreq,
			\amp, amp,
			\att, 0.01,
			\rel, sineReleaseTime,
			\cur, wchoose([-10, -4, -1], [0.3, 0.6, 0.1]),
			\glissEnd, sineGlissEnd
		]
	); // end of Siney synth

}; // end of soundFunc


"Noto-Sound-Function.scd loaded!".postln;