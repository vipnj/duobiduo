package com.duobiduo.audio.generators 
{
	
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class Drift implements IGenerator
	{
		private var _index:Number=0;
		private var _rate:Number = 0;
		private var _limit:Number = 0;
		private var _samples:uint = 0;
		private var _spi:Number = 0;
		public function Drift() 
		{
			_index = 0;
			setDrift(.01, 1,220);
		}
		public function setDrift(rate:Number,limit:Number,samples:uint):void
		{
			_rate = rate;
			_limit = limit;
			_samples = samples;
			_spi = _samples / 180 * Math.PI;
		}
		public function restart():void
		{
			_index = 0;
		}
		public function tick():Number
		{
			_index += _rate * Math.random();

			if (_index >= 1.0) _index -= 1.0;
			else if (_index < 0.0) _index += 1.0;
			return  _limit * Math.sin(_index * _spi );
		}
	}
	
}