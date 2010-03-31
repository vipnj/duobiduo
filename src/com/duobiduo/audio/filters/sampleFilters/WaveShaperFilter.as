package com.duobiduo.audio.filters.sampleFilters 
{
	import com.duobiduo.audio.filters.sampleFilters.SampleFilter;
	import com.duobiduo.audio.filters.sampleFilters.methods.IMethod;
	import com.duobiduo.audio.utils.Sample;
	import com.duobiduo.audio.filters.sampleFilters.methods.WaveShaper;
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class WaveShaperFilter extends SampleFilter
	{

		public function WaveShaperFilter(shaper:Number=0) 
		{
			super();
			_leftFilter = new WaveShaper(shaper);
			_rightFilter = new WaveShaper(shaper);
			
		}
		
		public function configure(shaper:Number):void
		{
			_leftFilter.configure(shaper);
			_rightFilter.configure(shaper);
		}

		
	}
	
}