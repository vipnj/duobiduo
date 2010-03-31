package com.duobiduo.audio.filters.sampleFilters.methods  
{
	
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class WaveShaper implements IMethod
	{

		private var a:Number;
		public function WaveShaper(a:Number) 
		{
			configure(a);
		}
		

		public function configure(shaper:Number):void
		{
			a = shaper;
		}

		
		public function process(x:Number):Number
		{
			//return x * (Math.abs(x) + a) / (x * x + (a - 1) * Math.abs(x) + 1);
			if (x > 0)
				return x * (x + a) / (x * x + (a - 1) * x + 1);
			else
				return x * (-x + a) / (x * x + (a - 1) * -x + 1);
		}
		
		public function reset():void
		{
			;
		}
		public function clone():IMethod
		{
			return new WaveShaper(a);
		}
		public function toString():String
		{
			return String("shaper~"+a);
		}
	}
	
}