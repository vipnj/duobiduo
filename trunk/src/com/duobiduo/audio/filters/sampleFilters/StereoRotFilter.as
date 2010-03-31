package com.duobiduo.audio.filters.sampleFilters 
{
	import com.duobiduo.audio.utils.Sample;
	import com.duobiduo.audio.filters.sampleFilters.SampleFilter;
	/**
	 * ...
	 * @author efishocean
	 */
	public class StereoRotFilter extends SampleFilter
	{
		private var cos_coef:Number=1;
		private var sin_coef:Number=0;
		public function StereoRotFilter(angle:Number) 
		{
			super();
			this.configure(angle);
		}
		
		public function configure(angle:Number):void
		{
			// Calculate transformation matrix's coefficients
			cos_coef = Math.cos(angle/180*Math.PI);
			sin_coef = Math.sin(angle/180*Math.PI);
		}
		
		override public function process(sample:Sample):void
		{
			// Do this per sample
			var left:Number = sample.left;
			var right:Number = sample.right;
			sample.left  = left * cos_coef - right * sin_coef;
			sample.right = left * sin_coef + right * cos_coef;
		}
		
		override public function reset():void
		{
			this.configure(0);
		}
		
	}

}


