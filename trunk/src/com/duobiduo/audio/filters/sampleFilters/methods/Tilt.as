package com.duobiduo.audio.filters.sampleFilters.methods 
{
	
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class Tilt implements IMethod
	{
		//=======================
		// tilt eq settings
		//
		// srate -> sample rate
		// f0 -> 20-20khz
		// gain -> -6 / +6 db
		//=======================
		private const amp:Number = 6/Math.log(2);
		private const denorm:Number = Math.pow(10,-30);
		private const PI:Number = Math.PI;
		private var sr3:Number;
		private var lgain:Number;
		private var hgain:Number;
		private var a0:Number;
		private var b1:Number;
		private var lp_out:Number = 0;
		private var _srate:Number, _f0:Number, _gain:Number;
		public function Tilt() 
		{

		}
		
		public function configure(srate:Number,f0:Number, gain:Number):void
		{
			_srate = srate;
			_f0 = f0;
			_gain = gain;
			
			sr3 = 3 * srate;
			// conditition:
			// gfactor is the proportional gain
			//
			var g1:Number;
			var g2:Number;
			var gfactor:Number = 5;
			if (gain > 0) {
				g1 = -gfactor*gain;
				g2 = gain;
			} else {
				g1 = -gain;
				g2 = gfactor*gain;
			}
			//two separate gains
			lgain = Math.exp(g1/amp)-1;
			hgain = Math.exp(g2/amp)-1;
			//filter
			var omega:Number = 2*PI*f0;
			var n:Number = 1/(sr3 + omega);
			a0 = 2*omega*n;
			b1 = (sr3 - omega)*n;
		}
		public function reset():void
		{
			lp_out=0;
		}
		public function process(x:Number):Number
		{
			//==================================
			// sample loop
			// x -> input sample
			// out -> output sample
			//==================================
			lp_out = a0*x + b1*lp_out;
			out = x + lgain*lp_out + hgain*(x - lp_out);
			return out;
		}
		
		public function clone():IMethod
		{
			return new Tilt(_srate, _f0, _gain);
		}
		
		public function toString():String
		{
			return String("srate "+_srate+", f0"+_f0+", gain "+_gain);
		}
	}
	
}








