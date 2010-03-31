package com.duobiduo.audio.filters.sampleFilters 
{
	import com.duobiduo.audio.utils.Sample;
	import com.duobiduo.audio.filters.sampleFilters.SampleFilter;
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class PanFilter extends SampleFilter
	{
		private var _pan:Number;
		private var _crossing:Boolean;
		public function PanFilter(pan:Number=0.0) 
		{
			super();
			configure(pan);
		}
		
		/**
		 * 配置声道偏移滤镜
		 * @param	pan	偏移值-1 .. 1。-1表示全部偏移左声道，1表示全部偏移右声道。
		 * @param	crossing 是否交叉左右声道。
		 * 			默认为false的时候效果与flash.media.SoundTransform.pan相同。
		 * 			当true的时候，波形会向左右偏移。但此时pan值无法做乘法叠加。
		 */
		public function configure(pan:Number,crossing:Boolean=false):void 
		{
			_pan = pan;
		}
		
		override public function process(sample:Sample):void
		{
			if (_crossing)
			{
				if (_pan<0.0 && _pan>=-1.0)
				{
					sample.left = sample.left - sample.right * _pan;
					sample.left = sample.left > 1.0 ? 1.0 : ( sample.left < -1.0 ? -1.0 : sample.left);
					sample.right = sample.right + sample.right * _pan;
				}
				else if (_pan>0.0 && _pan<=1.0)
				{
					sample.right = sample.right + sample.left * _pan;
					sample.right = sample.right > 1.0 ? 1.0 : ( sample.right < -1.0 ? -1.0 : sample.right);
					sample.left = sample.left - sample.left * _pan;
				}
			}
			else
			{
				sample.left *= Math.sqrt(1 - _pan);
				sample.right *= Math.sqrt(1 + _pan);
			}
		}
		
		override public function reset():void
		{
			_pan = 0.0;
		}
	}
}