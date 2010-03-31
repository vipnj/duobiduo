package com.duobiduo.audio.filters.sampleFilters.methods  
{
	
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class NotchPeak implements IMethod
	{
		private var _notch:int;
		private var f:Number,r:Number;
		private var outp:Number, outp1:Number, outp2:Number; // init these with 0!
		private const p4:Number=1.0e-24; // Pentium 4 denormal problem elimination
		private var _cutFreq:Number;
		private var _steep:Number;
		private var a0:Number, b1:Number, b2:Number;
		public function NotchPeak() 
		{
			configure();
			
		}
		public function configure(cutFreq:Number, steep:Number=0.99, type:int = 1):void
		{
			reset();
			_cutFreq = cutFreq;
			_steep = steep;
			_notch = type;
			r = _steep * 0.99609375;
			f = Math.cos(Math.PI * _cutFreq);	
			a0 = (1 - r) * Math.sqrt(r * (r - 4 * (f * f) + 2) + 1);
			b1 = 2 * f * r;
			b2 = -(r * r);
		}
		public function reset():void
		{
			outp = outp1 = outp2 = 0;
		}
		public function process(inp:Number ):Number
		{

			outp = a0 * inp + b1 * outp1 + b2 * outp2 + p4;
			outp2 = outp1;
			outp1 = outp;
			if( _notch==1 ) 
			  return inp - outp; //notch
			else 
			  return outp; //peak
		}
	}
	
}