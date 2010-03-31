package com.duobiduo.audio.filters.sampleFilters 
{
	import com.duobiduo.audio.filters.sampleFilters.SampleFilter;
	import com.duobiduo.audio.utils.Sample;
	import com.duobiduo.audio.filters.sampleFilters.methods.BiQuad;
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class BiQuadFilter extends SampleFilter
	{
		public function BiQuadFilter()
		{
			super();
			_leftFilter = new BiQuad();
			_rightFilter = new BiQuad();
		}

		
		public function configure(type:int,frequence:Number,quality:Number,bandwidth:Number):void
		{
			_leftFilter.configure(type,frequence,quality,bandwidth);
			_rightFilter.configure(type,frequence,quality,bandwidth);
		}

		
	}
	
}