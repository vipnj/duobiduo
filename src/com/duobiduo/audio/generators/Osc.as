package com.duobiduo.audio.generators 
{
	
	/**
	 * arithmetic from AudioSandbox, Andre Michelle - http://blog.andre-michelle.com
	 * @author efishocean v1.09.0420
	 */

	import flash.display.Sprite;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;	

	public class Osc implements IGenerator
	{
		public static const SINUS:int = 0;
		public static const TRIANGLE:int = 1;
		public static const SAWTOOTH:int = 2;
		public static const SQUARE:int = 3;
		private static const TWO_PI:Number = Math.PI * 2;
		private var _phase: Number;
		private var _freq:Number;
		private var _type:int;
		public function Osc()
		{
			restart();
			setOsc();
		}

		public function restart(): void
		{
			_phase = 0.0;
		}
		

		public function setOsc(freq:Number=220,type:int=SINUS):void
		{
			// osc frequency
			_freq = freq / 44100; // 相对于固定44100采样率
			// oscillator type
			_type = type;	

		}
		
		public function tick():Number 
		{
			if( _phase > 1.0 )
			{
				--_phase;
			}
			_phase += _freq;
			
			if (_type == SINUS) 
			{
				return Math.sin( _phase * TWO_PI);
			}
			else if(_type== TRIANGLE)
			{
				var t: Number = ( _phase - int( _phase ) ) * 4;
				if( t < 2 ) --t;
				else t = 3 - t;
				return t;
			}
			else if(_type == SAWTOOTH)
			{
				return ( _phase - int( _phase ) ) * 2 - 1;
			}
			else if(_type == SQUARE)
			{
				return ( _phase - int( _phase ) ) < .5 ? 1 : -1;
			}
			return 0;//source.next
		}
		
			
		/**
		 * returns a bipolar ~ sinus
		 * 正弦波
		 */
		public function sinus(): Number
		{
			return Math.sin( _phase * TWO_PI);
		}
		
		/**
		 * returns a bipolar /\ waveform
		 * 三角波
		 */
		public function triangle(): Number
		{
			var t: Number = ( _phase - int( _phase ) ) * 4;
			if( t < 2 ) --t;
			else t = 3 - t;
			return t;
		}

		/**
		 * returns a bipolar / sawtooth
		 * 锯齿波
		 */
		public function sawtooth(): Number
		{
			return ( _phase - int( _phase ) ) * 2 - 1;
		}

		/**
		 * returns a bipolar [ square
		 * 方波
		 */
		public function square(): Number
		{
			return ( _phase - int( _phase ) ) < .5 ? 1 : -1;
		}
	}
}
