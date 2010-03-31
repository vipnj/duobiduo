package com.duobiduo.audio.filters.sampleFilters 
{
	import com.duobiduo.audio.filters.sampleFilters.SampleFilter;
	import com.duobiduo.audio.filters.sampleFilters.methods.Smooth;
	import com.duobiduo.audio.utils.Sample;
	
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class SmoothFilter extends SampleFilter
	{

		public function SmoothFilter() 
		{
			super();
			_leftFilter = new Smooth();
			_rightFilter = new Smooth();

		}
		
		public function configure(detect:Number, reject:Number):void 
		{
			_leftFilter.configure(detect, reject);
			_rightFilter.configure(detect, reject);
		}
		
	}
	
}