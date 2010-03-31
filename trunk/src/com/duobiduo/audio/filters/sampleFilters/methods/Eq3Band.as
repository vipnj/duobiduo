package com.duobiduo.audio.filters.sampleFilters.methods  
{
	
	/**
	 * ...
	 * @author DefaultUser (Tools . Custom Arguments...)
	 */
	public class Eq3Band implements IMethod
	{
		private static const vsa:Number = 1.0 / 4294967295.0; // Very small amount (Denormal Fix)
		private var _lowfreq:Number, _highfreq:Number, _mixfreq:Number, _lowGain:Number, _midGain:Number, _highGain:Number;
		public function Eq3Band() 
		{
			es = new EQSTATE();
			es.zero();
		}
		private var es:EQSTATE;
		
		/**
		 * reset eq state
		 */
		public function reset():void
		{
			es.zero();
		}
		// ---------------
		//| Initialise EQ |
		// ---------------
		// Recommended frequencies are ...
		//
		// lowfreq = 880 Hz
		// highfreq = 5000 Hz
		//
		// Set mixfreq to whatever rate your system is using (eg 48Khz)
		public function init3BandState( lowfreq:Number, highfreq:Number, mixfreq:Number):void
		{
			_lowfreq = lowfreq;
			_highfreq = highfreq;
			_mixfreq = mixfreq;
			// Clear state 
			es.zero();
			// Set Low/Mid/High gains to unity
			es.lg = 1;
			es.mg = 1;
			es.hg = 1;
			// Calculate filter cutoff frequencies
			es.lf = 2 * Math.sin(Math.PI * (lowfreq / mixfreq)); 
			es.hf = 2 * Math.sin(Math.PI * (highfreq / mixfreq));
		}
		public function configure( lowGain:Number, midGain:Number, highGain:Number):void
		{
			_lowGain = lowGain;
			_midGain = midGain;
			_highGain = highGain;
			es.lg = lowGain;
			es.mg = midGain;
			es.hg = highGain;
		}
		// ---------------
		//| EQ one sample |
		// ---------------
		// - sample can be any range you like :)
		//
		// Note that the output will depend on the gain settings for each band 
		// (especially the bass) so may require clipping before output, but you 
		// knew that anyway :)
		public function process( sample:Number):Number
		{
			// Locals
			var l:Number,m:Number,h:Number; // Low / Mid / High - Sample Values

			// Filter #1 (lowpass)
			es.f1p0 += (es.lf * (sample - es.f1p0)) + vsa;
			es.f1p1 += (es.lf * (es.f1p0 - es.f1p1));
			es.f1p2 += (es.lf * (es.f1p1 - es.f1p2));
			es.f1p3 += (es.lf * (es.f1p2 - es.f1p3));

			l = es.f1p3;

			// Filter #2 (highpass)
			es.f2p0 += (es.hf * (sample - es.f2p0)) + vsa;
			es.f2p1 += (es.hf * (es.f2p0 - es.f2p1));
			es.f2p2 += (es.hf * (es.f2p1 - es.f2p2));
			es.f2p3 += (es.hf * (es.f2p2 - es.f2p3));

			h = es.sdm3 - es.f2p3;

			// Calculate midrange (signal - (low + high))
			m = es.sdm3 - (h + l);

			// Scale, Combine and store
			l *= es.lg;
			m *= es.mg;
			h *= es.hg;

			// Shuffle history buffer 

			es.sdm3 = es.sdm2;
			es.sdm2 = es.sdm1;
			es.sdm1 = sample; 

			// Return result
			return(l + m + h);
		}
		public function clone():IMethod
		{
			var eq3:Eq3Band = new Eq3Band();
			eq3.init3BandState(_lowfreq, _highfreq, _mixfreq);
			eq3.configure(_lowGain, _midGain, _highGain);
			return eq3;
		}
		public function toString():String
		{
			return String("lowfreq "+_lowfreq+", highfreq "+_highfreq+", mixfreq "+_mixfreq+", lowgain "+_lowGain+", midgain "+_midGain+", highgain "+_highGain);
		}
	}
	
}

class EQSTATE
{
	// Filter #1 (Low band)
	public var lf:Number; // Frequency
	public var f1p0:Number; // Poles ...
	public var f1p1:Number; 
	public var f1p2:Number;
	public var f1p3:Number;

	// Filter #2 (High band)
	public var hf:Number; // Frequency
	public var f2p0:Number; // Poles ...
	public var f2p1:Number;
	public var f2p2:Number;
	public var f2p3:Number;

	// Sample history buffer
	public var sdm1:Number; // Sample data minus 1
	public var sdm2:Number; // 2
	public var sdm3:Number; // 3

	// Gain Controls
	public var lg:Number; // low gain
	public var mg:Number; // mid gain
	public var hg:Number; // high gain
	
	public function zero():void
	{
		lf = f1p0 = f1p1 = f1p2 = f1p3 = hf = f2p0 = f2p1 = f2p2 = f2p3 = sdm1 = sdm2 = sdm3 = lg = mg = hg = 0;
	}
} 
//----------------------------------------------------------------------------
//
// 3 Band EQ :)
//
// EQ.C - Main Source file for 3 band EQ
//
// (c) Neil C / Etanza Systems / 2K6
//
// Shouts / Loves / Moans = etanza at lycos dot co dot uk 
//
// This work is hereby placed in the public domain for all purposes, including
// use in commercial applications.
//
// The author assumes NO RESPONSIBILITY for any problems caused by the use of
// this software.
//
//----------------------------------------------------------------------------
// NOTES :
//
// - Original filter code by Paul Kellet (musicdsp.pdf)
//
// - Uses 4 first order filters in series, should give 24dB per octave
//
// - Now with P4 Denormal fix :)
//
// - This version was migrated into Actionscript by Efishocean 09.04.13
//----------------------------------------------------------------------------