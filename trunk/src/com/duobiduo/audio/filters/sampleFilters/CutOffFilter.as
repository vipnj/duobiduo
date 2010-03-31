package com.duobiduo.audio.filters.sampleFilters 
{
	import com.duobiduo.audio.filters.sampleFilters.SampleFilter;
	import com.duobiduo.audio.utils.Sample;
	import com.duobiduo.audio.filters.sampleFilters.methods.CutOff;
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class CutOffFilter extends SampleFilter
	{
		public function CutOffFilter() 
		{
			super();
			_leftFilter = new CutOff();
			_rightFilter = new CutOff();

		}
		
		public function configure(cutoff:Number):void
		{
			_leftFilter.configure(cutoff);
			_rightFilter.configure(cutoff);
		}

	}
	
}