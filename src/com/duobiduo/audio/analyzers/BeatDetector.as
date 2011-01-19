package com.duobiduo.audio.analyzers
{
	
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class BeatDetector 
	{
		
		private var _FREQ_LP_BEAT:Number =150.0;		// Low Pass filter frequency
		private var T_FILTER:Number = 1.0 / (2.0 * Math.PI * _FREQ_LP_BEAT);	// Low Pass filter time constant
		private var BEAT_RTIME:Number = 0.02;			// Release time of enveloppe detector in second
		public function set FREQ_LP_BEAT(value:Number):void
		{
			_FREQ_LP_BEAT = value;
			T_FILTER = 1.0 / (2.0 * Math.PI * _FREQ_LP_BEAT);
		}
		//public function get FREQ_LP_BEAT():Number{
		private var _kBeatFilter:Number=0; // Filter coefficient

		private var _filter1Out:Number=0, _filter2Out:Number=0;

		private var _beatRelease:Number=0; // Release time coefficient

		private var _peakEnv:Number=0; // Peak enveloppe follower

		private var _beatTrigger:Boolean; // Schmitt trigger output

		private var _prevBeatPulse:Boolean; // Rising edge memory
		
		public var beatPulse:Boolean; // Beat detector output
		
		public function BeatDetector(sampleRate:Number=44100) 
		{
			_filter1Out=0.0;

			_filter2Out=0.0;

			_peakEnv=0.0;

			_beatTrigger=false;

			_prevBeatPulse=false;

			setSampleRate(sampleRate);
		}
		
		public function setSampleRate(sampleRate:Number=44100):void 
		{
			_kBeatFilter=1.0/(sampleRate*T_FILTER);

			_beatRelease=Math.exp(-1.0/(sampleRate*BEAT_RTIME));
		}
		
		public function AudioProcess(input:Number):void
		{
			var EnvIn:Number=0;



			// Step 1 : 2nd order low pass filter (made of two 1st order RC filter)

			_filter1Out = _filter1Out + (_kBeatFilter * (input - _filter1Out));

			_filter2Out = _filter2Out + (_kBeatFilter * (_filter1Out - _filter2Out));



			// Step 2 : peak detector

			EnvIn = Math.abs(_filter2Out);

			if (EnvIn > _peakEnv)
			{
				_peakEnv = EnvIn; // Attack time = 0
			}
			else
			{

				_peakEnv *= _beatRelease;

				_peakEnv += (1.0 - _beatRelease) * EnvIn;

			}



			// Step 3 : Schmitt trigger

			if (!_beatTrigger)
			{

				if (_peakEnv > 0.3) _beatTrigger = true;

			}
			else
			{

				if (_peakEnv < 0.15) _beatTrigger = false;

			}



			// Step 4 : rising edge detector

			beatPulse = false;

			if ((_beatTrigger)&&(!_prevBeatPulse))
			{
				beatPulse = true;
			}
			
			_prevBeatPulse = _beatTrigger;
		}
		
	}
	
}

