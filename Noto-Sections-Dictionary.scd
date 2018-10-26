// ====================
// Notoligotoma
//
// Sections Dictionary
// checkForUpdates function
//
// Sections Dictionary: holds data for each sound parameter for each section of the piece. Sections are named \a, \b, \c, etc.
//
// checkForUpdates function: used in Noto-Sound-Function.scd, this function takes in the current hitNumber and checks whether it's time to update parameters using Sections Dictionary.
// ====================



~favoriteNotes = [60, 64, 65, 69, 71]; // harmony to be emphasized over time

~transp = { arg freq, min, max;
	while({ freq < min }, { freq = freq * 2 });
	if(freq > max, { freq = freq / 2 });
	freq;
};

~dictionary = Dictionary.newFrom([

	// ------------
	// SECTION A
	// ------------
	\a, {

		var thisManyHits = 100;

		// KLANK FREQ
		~klankFreq = { arg midinote; midinote.midicps };

		// KLANK RING
		~krt = Pgeom(0.05, 1.01, inf).asStream;
		~klankRingTime = { arg midinote;
			var thisValue = ~krt.next;
			if(~favoriteNotes.includes(midinote) && (thisValue > 6),
				{ thisValue * rrand(1, 1.5) },
				{ min(thisValue * rrand(0.5, 1), 20) }
			);
		};

		// SINE FREQUENCY
		~sfdev = Pseq([
			Pwhite(0.9, 1.1, thisManyHits), // stay small for a while
			Pwrand( // then alternate 90% "in tune" with markov notes with 10% off those notes
				[1,	Pwhite(0.95, 1.13, 1)],
				[0.9, 0.1], inf)
		]).asStream;
		~sineFreq = { arg midinote;
			~transp.value(freq: midinote.midicps, min: 2000, max: 15000)
			*
			~sfdev.next;
		};

		// SINE RELEASE
		~srt = Pseq([
			Pwhite(0.01, 0.02, thisManyHits), // stay small for a while
			Pwrand( // then alternate 90% smalls with a 10% longs, growing
				[
					Pwhite(0.01, 0.02, 1),
					Pwhite(1, 2.0, 1)
				],
				[0.9, 0.1], inf) * Pseries(1, 0.01)
		]).asStream;
		~sineReleaseTime = { ~srt.next };

		// SINE GLISSANDO END POINT
		~glissLo = Pseries(1, -0.01).asStream;
		~glissHi = Pseries(1, 0.01).asStream;
		~sgep = Pseq([
			Pwhite(0.9, 1.2, thisManyHits),
			Prand([
				Pwhite(0.9, 1.1, 1),
				Pwhite(Pfuncn(~glissLo), Pfuncn(~glissHi), 3).clip(0.5, 3)
			], inf)
		], inf).asStream;
		~sineGlissEnd = { ~sgep.next };

	},

	// ------------
	// SECTION B
	// ------------

	\b, {



	},



]); // end of dictionary definition





// this function takes in the current hitNumber and checks whether any parameters need update. If yes, updates are made.

~checkForUpdates = { arg hitNumber;

	case
	{ hitNumber == 1 } { ~dictionary[\a].value }
	{ hitNumber == 200 } { ~dictionary[\b].value }
	{ hitNumber == 310 } { ~dictionary[\c].value }
	{ hitNumber == 400 } { ~dictionary[\d].value }
	{ hitNumber == 650 } { ~dictionary[\e].value }


};




"Noto-Sections-Dictionary.scd loaded!".postln;


/*

klankRingTime: klank ringing time, based on markov fundamental (preferred notes tend to get a longer ring)

klankFreq: klank frequency, based on fundamental but with some modifications (for example, preferred notes tend to stay at original octave, others transpose up)

sineFreq: freq of sine wave, based on markov fundamental + some detuning/deviation

sineReleaseTime: release time for each sine wave hit

sineGlissEnd: end point of sine wave glissando (1=nogliss, 2=octave above etc).








// emphasis on favorite note harmony through longer rings


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


*/