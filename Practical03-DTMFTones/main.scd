// 0. initialize

s.reboot;

(
Task({
	SynthDef(\stereo, {
		arg in, out;
		var sig;
		sig = In.ar(in ,1);
		sig = Splay.ar(sig);
		Out.ar(out, sig);
	}).add;

	0.2.wait;

	~stereoBus = Bus.audio(s, 1);
	~stereo = Synth.new(\stereo, [\in, ~stereoBus, \out, 0]);
}).play;
)

(
// button table
// ┌───┬───┬───┬───┐                 ┌─────┬─────┬─────┬─────┐
// │ 1 │ 2 │ 3 │ A │                 │  0  │  1  │  2  │  3  │
// ├───┼───┼───┼───┤                 ├─────┼─────┼─────┼─────┤
// │ 4 │ 5 │ 6 │ B │                 │  4  │  5  │  6  │  7  │
// ├───┼───┼───┼───┤  --(maps to)--> ├─────┼─────┼─────┼─────┤
// │ 7 │ 8 │ 9 │ C │                 │  8  │  9  │  10 │  11 │
// ├───┼───┼───┼───┤                 ├─────┼─────┼─────┼─────┤
// │ * │ 0 │ # │ D │                 │  12 │  13 │  14 │  15 │
// └───┴───┴───┴───┘                 └─────┴─────┴─────┴─────┘

d = Dictionary();
d.putPairs([
	"1", 0, "2", 1, "3", 2, "A", 3,
	"4", 4, "5", 5, "6", 6, "B", 7,
	"7", 8, "8", 9, "9", 10, "C", 11,
	"*", 12, "0", 13, "#", 14, "D", 15]);

// low, hi frequency maps to rows and columns
//
//         hi[0] hi[1] hi[2] hi[3]
//        ┌─────┬─────┬─────┬─────┐
// low[0] │  0  │  1  │  2  │  3  │
//        ├─────┼─────┼─────┼─────┤
// low[1] │  4  │  5  │  6  │  7  │
//        ├─────┼─────┼─────┼─────┤
// low[2] │  8  │  9  │  10 │  11 │
//        ├─────┼─────┼─────┼─────┤
// low[3] │  12 │  13 │  14 │  15 │
//        └─────┴─────┴─────┴─────┘
//
// hi: n % 4 (modulo)
// low: n // 4 (int division) or floor(n/4)

~hiFreq = [1209, 1336, 1477, 1633];
~lowFreq = [697, 770, 852, 941];
)


// 1. add SynthDef

(
// Dual Tone Multi Frequency
SynthDef(\dualTone, {
	arg n, out, gate=1;
    var freq, amp, sig, env;
	// Table of signalling tones in the book says 440Hz + 350Hz,
	// but the puredata implementaion says 350Hz + 450Hz.
	// This implementation follows the former specification.
	freq = [
		Select.kr(floor(n / 4), ~lowFreq),
		Select.kr(n % 4, ~hiFreq)
	];
	amp = 0.125;
	env = EnvGen.ar(Env.asr(0.001, 1, 0.001), gate, doneAction: Done.freeSelf);
	sig = Mix.new(freq.collect(SinOsc.ar(_))) * env * amp;
	Out.ar(out, sig);
}).add;
)


// 2. play and free

// random eleven buttons
(
~numbers = Array.fill(11, {rand(15)});
~numbers.postln;
Pbind(
	\instrument, \dualTone,
	\out, ~stereoBus,
	\dur, Pwhite(0.35, 0.5, inf),
	\sustain, Pwhite(0.2, 0.3, inf),
	\n, Pseq(~numbers)
).play;
)

// given string
(
~aa = "*021234567#".as(Array);
~numbers = ~aa.collect({arg i; d[i.asString];});

Pbind(
	\instrument, \dualTone,
	\out, ~stereoBus,
	\dur, Pwhite(0.35, 0.5, inf),
	\sustain, Pwhite(0.2, 0.3, inf),
	\n, Pseq(~numbers)
).play;
)

// mary had a little lamb
(
~aa = "3212333222333321233322321".as(Array);
~numbers = ~aa.collect({arg i; d[i.asString];});

Pbind(
	\instrument, \dualTone,
	\out, ~stereoBus,
	\dur, Pwhite(0.35, 0.5, inf),
	\sustain, Pwhite(0.2, 0.3, inf),
	\n, Pseq(~numbers)
).play;
)

// 3. reset

(
~stereo.free;
s.newBusAllocators;
)
