package com.duobiduo.audio.filters.sampleFilters.methods 
{
	
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class Volume  implements IMethod
	{
		private var _v:Number = 1.0;
		public function Volume(volume:Number) 
		{
			configure(volume);
		}
		public function configure(volume:Number):void
		{
			if ( !( volume > 1.0 || volume < 0 ) )
			{
				_v = volume;
			}
		}
		public function reset():void
		{
			_v = 1.0;
		}
		public function process(x:Number):Number
		{
			return x*_v;
		}
		public function clone():IMethod
		{
			return new Volume(_v);
		}
		public function toString():String
		{
			return String("volume~"+_v);
		}

	}
	
}