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
// LFO-Controlled Alarm
SynthDef(\LFOControlled, {
	arg out;
    var freq, amp, sig;
	freq = 800;
	amp = SinOsc.kr(2); // period of 0.5 seconds

	// multiply large number, then clip into the range 0.0 to 1.0
	amp = Clip.kr(amp * 1e6, 0, 1);

	// To remove the sharp edges a low-pass filter with a slope of 0.014 seconds
	// is used (the filter cuts above 70Hz), which gives a softer switching of the
	// amplitude and avoids sudden clicks.
	amp = LPF.kr(amp, 70);

	sig = SinOsc.ar(freq) * amp;
	Out.ar(out, sig);
}).add;

// Two-Tone Alarm
SynthDef(\twotone, {
	arg out;
    var freq1, freq2, amp, sig;
	freq1 = 600;
	freq2 = 800;
	amp = SinOsc.kr(2); // period of 0.5 seconds

	// multiply large number, then clip into the range 0.0 to 1.0
	amp = Clip.kr(amp * 1e6, 0, 1);

	// To remove the sharp edges a low-pass filter with a slope of 0.014 seconds
	// is used (the filter cuts above 70Hz), which gives a softer switching of the
	// amplitude and avoids sudden clicks.
	amp = LPF.kr(amp, 70);

	sig = Mix.ar([
		SinOsc.ar(freq1) * amp,
		SinOsc.ar(freq2) * (1 - amp)
	]);
	Out.ar(out, sig);
}).add;

// Three-Tone Alarm
SynthDef(\threetone1, {
	arg out;
    var freq1, freq2, freq3, amp, amp1, amp2, amp3, sig;
	freq1 = 723;
	freq2 = 932;
	freq3 = 1012;

	// 0 -> 1 -> 2 -> 0 -> 1 -> 2 -> ...
	// period is set to 0.5 seconds in the book, but according to the
	// sample provided at https://aspress.co.uk/sd/practical04.html,
	// it's more like 0.1 seconds.
	amp = Stepper.kr(Impulse.kr(10), 0, 0, 2);

	// equality check
	amp1 = amp |==| 0;
	amp2 = amp |==| 1;
	amp3 = amp |==| 2;

	// low-pass filter
	amp1 = LPF.kr(amp1, 70);
	amp2 = LPF.kr(amp2, 70);
	amp3 = LPF.kr(amp3, 70);

	sig = Mix.ar([
		SinOsc.ar(freq1) * amp1,
		SinOsc.ar(freq2) * amp2,
		SinOsc.ar(freq3) * amp3,
	]);
	Out.ar(out, sig);
}).add;
)


// 2. play and free
~alarm1 = Synth.new(\LFOControlled, [\out, ~stereoBus]);
~alarm1.free;

~alarm2 = Synth.new(\twotone, [\out, ~stereoBus]);
~alarm2.free;

~alarm3_1 = Synth.new(\threetone1, [\out, ~stereoBus]);
~alarm3_1.free;


// 1. add SynthDef
(

SynthDef(\multiAlarm, {
	// time: total length of sound, in milli-seconds
	// speed: number of times we iterate through freqs
	// freqs: four frequencies sequence
	// tone: timbre, 0 to 1
	arg time = 1, speed = 1, freqs = #[0, 0, 0, 0], tone = 1, out;
    var freq, amp, sig, iterTime, repeat;

	// repeat: number of times we iterate through freqs
	// iter time : time spent on one iteration
	repeat = speed;
	iterTime = time / repeat / 4 / 1000;

	// This works similar to 4phase-osc + timebase in the book.
	freq = Duty.ar(
		iterTime,
		0,
		Dseq(freqs, repeat),
		Done.freeSelf
	);

	// amp, which works as latter part of 4phase-osc
	amp = SinOsc.kr(1 / (iterTime * 2));

	sig = SinOsc.ar(freq);
	sig = HPF.ar(sig, 50);
	sig = sig + (0.25 * tone * 2 * pi);
	sig = (sig).cos;

	Out.ar(out, sig * amp);
}).add;
)

// 2. play and free

// Happy blips
~alarm = Synth.new(\multiAlarm, [\time, 380, \speed, 2, \out, ~stereoBus, \freqs, [349, 0, 0, 0], \tone, 1]);

// Affirmative
~alarm = Synth.new(\multiAlarm, [\time, 238, \speed, 1, \out, ~stereoBus, \freqs, [317, 0, 0, 476], \tone, 0]);

// Activate
~alarm = Synth.new(\multiAlarm, [\time, 317, \speed, 7, \out, ~stereoBus, \freqs, [300, 125, 0, 0], \tone, 1]);

// Invaders
~alarm = Synth.new(\multiAlarm, [\time, 1031, \speed, 9, \out, ~stereoBus, \freqs, [360, 238, 174, 158], \tone, 1]);

// Information
~alarm = Synth.new(\multiAlarm, [\time, 900, \speed, 4, \out, ~stereoBus, \freqs, [2000, 2010, 2000, 2010], \tone, 1]);

// Message alert
~alarm = Synth.new(\multiAlarm, [\time, 1428, \speed, 3, \out, ~stereoBus, \freqs, [619, 571, 365, 206], \tone, 1]);

// Finished
~alarm = Synth.new(\multiAlarm, [\time, 450, \speed, 1, \out, ~stereoBus, \freqs, [365, 571, 619, 206], \tone, 0.5]);

// Error code
~alarm = Synth.new(\multiAlarm, [\time, 714, \speed, 74, \out, ~stereoBus, \freqs, [1000, 0, 1000, 0], \tone, 1]);

// Wrong buzzer
(
Task({
	~alarm = Synth.new(\multiAlarm, [\time, 200, \speed, 30, \out, ~stereoBus, \freqs, [1000, 476, 159, 0], \tone, 1]);
	0.35.wait;
	~alarm = Synth.new(\multiAlarm, [\time, 634, \speed, 61, \out, ~stereoBus, \freqs, [1000, 476, 159, 0], \tone, 1]);
}).play;
)

// 3. reset

(
~stereo.free;
s.newBusAllocators;
)
