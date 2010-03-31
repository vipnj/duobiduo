package com.duobiduo.audio.filters.sampleFilters.methods  
{
	import com.duobiduo.audio.utils.Sample;
	
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class CutOff implements IMethod
	{
		private const steep:Number=0.99;
		private const r:Number=steep * 0.99609375;
		private var f:Number;
		private var a0:Number, b1:Number, b2:Number, x1:Number, x2:Number;
		private var _cufOff:Number;

		public function configure(cutoff:Number):void
		{
			_cufOff = cutoff;
			f = Math.cos(Math.PI * cutoff / 44100);
			a0 = (1 - r) * Math.sqrt( r * (r - 4 * (f * f) + 2) + 1);
			b1 = 2 * f * r;
			b2 = -(r * r);
			reset();
		}
		public function reset():void
		{
			x1 = 0.0;
			x2 = 0.0;
		}
		public function process(sample:Number):Number
		{
			var outp:Number = a0 * sample + b1 * x1 + b2 * x2;
			x2 = x1;
			x1 = outp;
			return outp;
		}
		public function clone():IMethod
		{
			return new CutOff(_cufOff);
		}
		public function toString():String
		{
			return String("cutOff~"+_cufOff);
		}
	}
}