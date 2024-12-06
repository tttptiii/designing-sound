// 0. initialize

s.reboot;

(
~stereoBus = Bus.audio(s, 1);
SynthDef(\stereo, {
	arg in, out;
	var sig;
	sig = In.ar(in ,1);
	sig = Splay.ar(sig);
	Out.ar(out, sig);
}).add;
~stereo = Synth.new(\stereo, [\in, ~stereoBus, \out, 0]);
)


// 1. add SynthDef

(
SynthDef(\pedestrian, {
	arg out;
    var freq, amp, sig;
	freq = 2500;
	amp = LFPulse.ar(5) * 0.2;
	sig = SinOsc.ar(freq) * amp;
	Out.ar(out, sig);
}).add;
)


// 2. play and free

~pedestrian = Synth.new(\pedestrian, [\out, ~stereoBus]);

~pedestrian.free;


// 3. finalize

(
~stereo.free;
s.newBusAllocators;
)
