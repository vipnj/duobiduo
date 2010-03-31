package com.duobiduo.audio.filters.sampleFilters 
{
	import com.duobiduo.audio.filters.sampleFilters.SampleFilter;
	import com.duobiduo.audio.utils.Sample;
	import com.duobiduo.audio.filters.sampleFilters.methods.NotchPeak;
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class NotchPeakFilter extends SampleFilter
	{
		public function NotchPeakFilter() 
		{
			super();
			_leftFilter = new NotchPeak();
			_rightFilter = new NotchPeak();
		}

		
		public function configure(cut:Number,steep:Number,type:int=1):void
		{
			_leftFilter.configure(cut, steep, type);
			_rightFilter.configure(cut, steep, type);
		}

	}
	
}