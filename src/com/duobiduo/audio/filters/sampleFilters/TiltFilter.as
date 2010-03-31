package com.duobiduo.audio.filters.sampleFilters 
{
	import com.duobiduo.audio.filters.sampleFilters.methods.Tilt;
	import com.duobiduo.audio.filters.sampleFilters.SampleFilter;
	import com.duobiduo.audio.utils.Sample;
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class TiltFilter extends SampleFilter
	{
	
		public function TiltFilter() 
		{
			super();
			_leftFilter = new Tilt();
			_rightFilter = new Tilt();

		}
		
		public function configure(srate:Number, f0:Number, gain:Number):void 
		{
			_leftFilter.configure(srate,f0,gain);
			_rightFilter.configure(srate,f0,gain);
		}
		

	}
	
}