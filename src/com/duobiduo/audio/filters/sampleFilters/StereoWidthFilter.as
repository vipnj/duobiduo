package com.duobiduo.audio.filters.sampleFilters 
{
	import com.duobiduo.audio.utils.Sample;
	import com.duobiduo.audio.filters.sampleFilters.SampleFilter;
	/**
	 * ...
	 * @author efishocean
	 */
	public class StereoWidthFilter extends SampleFilter
	{
		private var coef:Number=0;

		public function StereoWidthFilter(width:Number) 
		{
			super();
			this.configure(width);
		}
		
		/**
		 * change stereo width
		 * @param	width
		 * width < 1: decrease in stereo width
		 * width = 1: no change
		 * width > 1: increase in stereo width
		 * width = 0: mono
		 */
		public function configure(width:Number):void
		{


			// calculate scale coefficient
			coef = width * 0.5;
		}
		
		override public function process(sample:Sample):void
		{
			// Do this per sample
			var left:Number = sample.left;
			var right:Number = sample.right;

			// then do this per sample
			var m:Number = (left  + right)*0.5;
			var s:Number = (right - left )*coef;

			sample.left  = m - s;
			sample.right = m + s;
		}
		
		override public function reset():void
		{
			this.configure(1);
		}
		
	}

}



