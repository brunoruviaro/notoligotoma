// WHAT THIS FILE DOES
//
//
// loads data
// identifies unique step names (there are 27 of them), sort them alphabetically
// converts data into numbers based on alphabetical order
// filters data to exclude immediate repeats (like a Pxrand)
// treats that ordering as pitches (diatonic, white keys of piano)
// creates markov stream based on it
// saving it into global variable to be used by main code


// === CSV FILE PATH to NOTO_02 === //
var csv_path = "Noto_02F + Noto_02R.csv".resolveRelative;
var data0, data3;
var alphabeticallySortedStepNames;
var data3excludingImmediateRepeats;
var markov;
var previous;

~thisFile = \loaded;
~markovStream = nil;

// === LOAD CSV FILE === //
data0= CSVFileReader.read(csv_path, skipEmptyLines: true, skipBlanks: true).collect({ |item| item.asString.toUpper.asSymbol });

// === IDENTIFY UNIQUE STEPS, SORT ALPHABETICALLY === //
alphabeticallySortedStepNames = data0.copy.as(Set).asArray.sort;

// === CONVERT DATA TO NUMBERS === //
// midinote numbers, diatonic scale from middle C
data3 = data0.copy.collect({arg step;
	case
	{step=='[ D LT BACK ]'}  {60} // 127 appearances
	{step=='[ D LT CROSS ]'}  {62} // 8 appearances
	{step=='[ D LT NEAR ]'}    {64} // 789 appearances
	{step=='[ D LT OVERBACK ]'} {65} // 98 appearances
	{step=='[ D LT PAW ]'}       {67} // 6 appearances
	{step=='[ D LT REACH ]'}      {69} // 316 appearances
	{step=='[ D LT SIDE ]'}        {71} // 162 appearances
	{step=='[ D RT BACK ]'}  {72} // 149 appearances
	{step=='[ D RT CROSS ]'}  {74} // 8 appearances
	{step=='[ D RT NEAR ]'}    {76} // 795 appearances
	{step=='[ D RT OVERBACK ]'} {77} // 130 appearances
	{step=='[ D RT REACH ]'}     {79} // 347 appearances
	{step=='[ D RT SIDE ]'}       {81} // 332 appearances
	{step=='[ V LT BACK ]'}        {83} // 53 appearances
	{step=='[ V LT CROSS ]'}  {84} // 7 appearances
	{step=='[ V LT NEAR ]'}    {86} // 374 appearances
	{step=='[ V LT OVERBACK ]'} {88} // 91 appearances
	{step=='[ V LT PAW ]'}       {89} // 33 appearances
	{step=='[ V LT REACH ]'}      {91} // 284 appearances
	{step=='[ V LT SIDE ]'}        {93} // 161 appearances
	{step=='[ V RT BACK ]'}         {95} // 62 appearances
	{step=='[ V RT CROSS ]'}  {96} // 1 appearances
	{step=='[ V RT NEAR ]'}    {98} // 364 appearances
	{step=='[ V RT OVERBACK ]'} {100} // 10 appearances
	{step=='[ V RT PAW ]'}       {101} // 3 appearances
	{step=='[ V RT REACH ]'}      {103} // 428 appearances
	{step=='[ V RT SIDE ]'}        {105} // 93 appearances
});

// === EXCLUDE IMMEDIATE REPEATS === //
previous = data3[0];
data3excludingImmediateRepeats = List.new.add(previous);
data3.copy.do({arg item, index;
	if(item != previous,
		{
			data3excludingImmediateRepeats.add(item);
			previous = item;
		},
		{ /*[index, "removed repeat"].postln*/ }
	);
});

// data3excludingImmediateRepeats.postln;

// === LISTEN: MAPPING IT TO WHITE KEYS OF PIANO === //
// Pbind(\midinote, Pseq(data3excludingImmediateRepeats, inf), \dur, 0.12).play;

// === CREATE MARKOV FROM IT (ORDER 2) === //
markov = MarkovSetN.fill(
	n: data3excludingImmediateRepeats.size,
	stream: Pseq(data3excludingImmediateRepeats, inf).asStream,
	order: 2
);

markov.makeSeeds;

~markovStream = markov.asStream;


"Noto-Data-Reader.scd loaded!";

// yay
// Pbind(\degree, Pfunc({ ~markovStream.next }), \dur, 0.12).play;



