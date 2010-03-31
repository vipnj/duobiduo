package com.duobiduo.audio.filters.sampleFilters 
{
	import com.duobiduo.audio.filters.sampleFilters.methods.Volume;
	import com.duobiduo.audio.utils.Sample;
	import com.duobiduo.audio.filters.sampleFilters.SampleFilter;
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class VolumeFilter extends SampleFilter
	{
		

		public function VolumeFilter(volume:Number=1) 
		{
			super();
			_leftFilter = new Volume(volume);
			_rightFilter = new Volume(volume);

		}
		
		public function configure(volume:Number):void 
		{
			_leftFilter.configure(volume);
			_rightFilter.configure(volume);
		}
		

	}
	
}