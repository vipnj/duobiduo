package com.duobiduo.audio.filters.sampleFilters.methods 
{
	
	/**
	 * very simple 1 pole LPF
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class Smooth  implements IMethod
	{
		private var detect:Number, reject:Number;
		private var diff1:Number, diff2:Number,diff:Number;
		private var out:Number, out1:Number;
		private var x1:Number, x2:Number;
		private var delta1:Number, delta:Number;
		private var run:Boolean;
		
		private static const SC:Number = 0.75;
		private static const SC2:Number = 0.5625;
		private var _d:Number;
		private var _r:Number;
		public function Smooth() 
		{
			reset();
		}
		
		public function configure(d:Number,r:Number):void
		{
			_d = d;
			_r = r;
			detect = 1+d;
			reject = 1+r;
		}
		
		public function process(x:Number):Number
		{
		
			if ( !run ) 
			{
				diff = Math.abs(x - x1);
				delta = Math.abs(diff - diff1);
				if ( delta > delta1 * reject && delta1 != 0)
				{
					run = true;
				}
				diff2 = diff1;
				diff1 = diff;
		
				delta1 = delta;
				x2 = x1;
				x1 = x;
				out = x;
			}
			else
			{
				diff = Math.abs(x - x1);
				delta = Math.abs(diff - diff1);
				if ( delta < delta1 * detect && delta != 0)
				{
					run = false;
					
					diff2 = diff1;
					diff1 = diff;
			
					delta1 = delta;
					x2 = x1;
					x1 = x;
				}
				
				out = (x*SC+x1)*0.5;
			}
			return out;
		}

		public function reset():void
		{
			diff = diff1 = diff2 = x1 = x2 = delta = delta1 = out = out1 = 0;
			run = false;
		}
		
		
		public function clone():IMethod
		{
			return new Smooth(_d, _r);
		}
		public function toString():String
		{
			return String("detect "+_d+", reject "+_r);
		}
	}
	
}