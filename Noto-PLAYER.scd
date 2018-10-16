// Noto SynthDefs


// =================================
// Read raw data and process it
"Noto-Data-Reader.scd".loadRelative;


// =================================
// Boot server and load Synth Definitions
"Noto-SynthDefs.scd".loadRelative;








// if I keep a running COUNT of contact mic hits, I could specify state changes at certain points

// 1, 2, 3....100.... 400...

// note that these would be trigger (mic hits), not absolute data points (as not all instruments have a mic).

// so for example mic hit #500 might actually be data point 2000 or something.

// so it would be nice to have a counter on Post window, at what mic hit # are we at?


/*
what would state info look like?



klankRing - klank ringing time

sineRelease - basically duration of percussive hit for sine waves

sineGlissEndPoint - the desired end point of sine glissando (1=nogliss, 2=octave above, etc)

sineGlissEndPointDeviation = how much deviation allowed from EndPoint (+ or - X)

another way of stating gliss would be simply sineGlissMin and sineGlissMax

sineFreqDetune - how much to deviate from Markov freqs (1=in tune, 2=octave above, etc)

*/


~hitNumber = 0;
~klankRingTime =
~sineReleaseTime =
~sineGlissMin =
~sineGlissMax =
~sineFreqDetune =









