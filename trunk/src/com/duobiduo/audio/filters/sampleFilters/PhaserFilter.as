package com.duobiduo.audio.filters.sampleFilters 
{
	import com.duobiduo.audio.filters.sampleFilters.SampleFilter;
	import com.duobiduo.audio.utils.Sample;
	import com.duobiduo.audio.filters.sampleFilters.methods.Phaser;
	/**
	 * ...
	 * @author efishocean
	 */
	public class PhaserFilter extends SampleFilter
	{
		

		public function PhaserFilter()
		{
			super();
			_leftFilter = new Phaser();
			_rightFilter = new Phaser();

		}

		
		public function configure(fmin:Number,fmax:Number,rate:Number,fb:Number,depth:Number,left:Boolean=true,right:Boolean=true):void
		{
			_leftFilter.configure(fmin,fmax,rate,fb,depth);
			_rightFilter.configure(fmin, fmax, rate, fb, depth);
		}
		

	}

}