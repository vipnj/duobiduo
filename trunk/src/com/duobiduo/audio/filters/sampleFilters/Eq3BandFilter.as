package com.duobiduo.audio.filters.sampleFilters 
{
	import com.duobiduo.audio.filters.ISampleFilter;
	import com.duobiduo.audio.utils.Sample;
	import com.duobiduo.audio.filters.sampleFilters.SampleFilter;
	import com.duobiduo.audio.filters.sampleFilters.methods.Eq3Band;
	
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class Eq3BandFilter extends SampleFilter
	{
		public function Eq3BandFilter() 
		{
			super();
			_leftFilter = new Eq3Band();
			_rightFilter = new Eq3Band();
			(_leftFilter as Eq3Band).init3BandState(880, 5000, 44100);
			(_rightFilter as Eq3Band).init3BandState(880, 5000, 44100);
			configure();
		}
		
		/**	
		 * 三段均衡器配置，输入数值应大于等于0. 数值最好以对数曲线增长，效果较好。
		 * 例如。输入值从log2(1)变化到log2(3)，取值范围0 - 1 - 1.58的对数曲线变化效果就比较平滑。
		 * @param	lowGain		低音增益
		 * @param	midGain		中音增益
		 * @param	highGain	高音增益
		 * @param	stereo		双声道处理
		 */
		public function configure(lowGain:Number=1, midGain:Number=1, highGain:Number=1):void
		{
			(_leftFilter as Eq3Band).configure(lowGain, midGain, highGain);
			(_rightFilter as Eq3Band).configure(lowGain, midGain, highGain);
		}
		
	}
	
}