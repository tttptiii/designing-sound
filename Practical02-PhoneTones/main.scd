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


// 1. add SynthDef
(
// Approximation of transmission medium: phone line and handset
Task({
	SynthDef(\tline, {
		arg in, out;
		var sig;
		sig = In.ar(in ,1);
		sig = Clip.ar(sig, -0.9, 0.9);
		sig = BPF.ar(sig, 2000, 1/12);
		sig = Mix.new([
			BPF.ar(sig * 0.5, 400, 1/3), // remove low freqencies
			Clip.ar(sig, -0.4, 0.4) * 0.15 // loudspeaker distortion
		]);
		sig = HPF.ar(sig, 90);
		sig = HPF.ar(sig, 90);
		// BPF makes sound smaller, so add mul!
		// I picked a custom value that sounds right.
		Out.ar(out, sig * 120);
	}).add;

	0.2.wait;

	~tlineBus = Bus.audio(s, 1);
	~tline = Synth.new(\tline, [\in, ~tlineBus, \out, ~stereoBus]);
}).play;
)

(
// dial tone, ringing tone, busy tone
SynthDef(\dialTone, {
	arg out;
    var freq, amp, sig;
	// Table of signalling tones in the book says 440Hz + 350Hz,
	// but the puredata implementaion says 350Hz + 450Hz.
	// This implementation follows the former specification.
	freq = [440, 350];
	amp = 0.125;
	sig = Mix.new(freq.collect(SinOsc.ar(_))) * amp;
	Out.ar(out, sig);
}).add;

SynthDef(\ringingTone, {
	arg out;
    var freq, amp, sig;
	freq = [480, 440];
	// Table of signalling tones in the book says 2s on - 4s off,
	// but the puredata implementaion says 2s off - 4s on.
	// This implementation follows the former specification.
	amp = LFPulse.ar(1/6, width: 1/3) * 0.125;
	sig = Mix.new(freq.collect(SinOsc.ar(_))) * amp;
	Out.ar(out, sig);
}).add;

SynthDef(\busyTone, {
	arg out;
    var freq, amp, sig;
	freq = [480, 620];
	amp = SinOsc.ar(2) * 10000;
	amp = Clip.ar(amp, 0, 1);
	amp = LPF.ar(amp, 100);
	sig = Mix.new(freq.collect(SinOsc.ar(_))) * amp * 0.1;
	Out.ar(out, sig);
}).add;

// pulse dial
SynthDef(\pulseOnce, {
	arg out;
	var env, sig;
	env = EnvGen.kr(
		Env([0, 1, 1 ,0], [0, 0.04, 0]),
		doneAction: Done.freeSelf
	); // 40ms click sound
	sig = Trig1.ar(1, 0.1) * env;
	Out.ar(out, sig);
}).add;
)


// 2. play and free

// test dialTone sound
//    1) original source
~dialOriginal = Synth.new(\dialTone, [\out, ~stereoBus]);
~dialOriginal.free;
//    2) over telephone line
~dialOverLine = Synth.new(\dialTone, [\out, ~tlineBus]);
~dialOverLine.free;

// ringingTone over line
~ringingOverLine = Synth.new(\ringingTone, [\out, ~tlineBus]);
~ringingOverLine.free;

// busyTone original source
~busyOriginal = Synth.new(\busyTone, [\out, ~stereoBus]);
~busyOriginal.free;

// dialling numbers
(
//    set seven random numbers(0~9) in an array
~dialNumbers = Array.fill(7, {rand(10)});
~dialNumbers.postln;
//    play
//    ref: https://stackoverflow.com/questions/43948695/how-to-wait-within-array-iteration
Routine({
	~dialNumbers.do{
		arg n;
		var clickNum, interval;
		// if you see the dial, 0 comes after 9,
		// so ten clicks for number 0.
		clickNum = [10, 1, 2, 3, 4, 5, 6, 7, 8, 9][n];
		{
			clickNum.do({
				Synth.new(\pulseOnce, [\out, ~tlineBus]);
				0.1.wait;
			});
		}.fork();

		// set interval(in sec) between dialling each number
		interval = 1;
		(0.1 * clickNum + interval).wait;
	}
}).play(AppClock);
)

// 3. reset

(
~stereo.free;
~tline.free;
s.newBusAllocators;
)
