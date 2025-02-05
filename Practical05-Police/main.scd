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
SynthDef(\police1, {
	arg sweepFreq, out;
    var freq, sig, wet;

	// We can use Lag for logarithmic rise and fall.
	// freq in range (300, 300+800).
	freq = Lag.kr(LFPulse.kr(sweepFreq), 0.5 / sweepFreq, 800, 300);

	sig = Lag.ar(Pulse.ar(freq), 0.5 / freq);

	// plastic horn
	sig = BPF.ar(Clip.ar(sig, -0.2, 0.2), 1500, 1/4);

	// environment
	// echo + delay implementation
	// ref: https://www.reddit.com/r/supercollider/comments/10jf7mz/comment/j5l7ez8/
	wet = sig + LocalIn.ar(~stereoBus);
	wet = Mix.ar([
		DelayC.ar(sig, 1, 0.033),
		DelayC.ar(sig, 1, 0.121),
		DelayC.ar(sig, 1, 0.165)
	]) * 0.1;
	LocalOut.ar(wet);
	sig = sig + wet * 0.25;

	Out.ar(out, sig * 10);

}).add;
)


// 1.5. plot waveform
(
{
	var sweepFreq, freq, sig;
	sweepFreq = 1;
	freq = Lag.kr(LFPulse.kr(1), 1/2 / sweepFreq, 800, 300);
	sig = Lag.ar(Pulse.ar(freq), 1/2 / freq);
}.plot();
)


// 2. play and free

~police1 = Synth.new(\police1, [\sweepFreq, 0.1, \out, ~stereoBus]);
~police1.set(\sweepFreq, 3);
~police1.set(\sweepFreq, 0.1);
~police1.free;


// 3. reset

(
~stereo.free;
s.newBusAllocators;
)
