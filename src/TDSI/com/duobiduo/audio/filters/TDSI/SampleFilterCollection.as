package com.duobiduo.audio.filters.TDSI 
{
	import com.duobiduo.audio.filters.TDSI.MemoryAgent;
	import com.joa_ebert.apparat.memory.Memory;
	import com.duobiduo.audio.utils.Sample;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author efishocean
	 */
	public class SampleFilterCollection
	{
		private static const MAX_SAMPLES:uint = 8192;
		
		private static var $input:MemoryAgent;
		private static var $inited:Boolean = false;
		
		private var _filters:Array;
		private var _processSize:int;
		
		private var _input:MemoryAgent;
		private var _zeroMemAgent:MemoryAgent;
		
		public function SampleFilterCollection(filters:Array,length:int) 
		{
			if ( !$inited )
			{
				$input = new MemoryAgent(MAX_SAMPLES);
				$inited = true;
			}
			_filters = filters;
			_processSize = length;
			
			_input = $input;
			_zeroMemAgent = new MemoryAgent(0);
		}

		
		public function process(bytes:ByteArray=null):int
		{

			if (null == bytes)
			{
				//执行滤镜处理
				processMain( _processSize );
			}
			else
			{
				var pos:uint = bytes.position;
				var value:Number = new Number();
				var i:int;
				//填充新采样
				for ( i = 0; i < _processSize; ++i)
				{
					
					value = bytes.readFloat();
					Memory.writeFloat(value, _input.pos + ((2 * i) << 2));

					value = bytes.readFloat();
					Memory.writeFloat(value, _input.pos + ((2 * i + 1) <<2));
				}
				
				//执行filter处理
				processMain( _processSize);
				
				//内存归位，写入处理过的采样
				bytes.position = pos;
				for (i = 0; i < _processSize; ++i)
				{
					bytes.writeFloat(Memory.readFloat(_input.pos + ((2 * i)<<2)));
					bytes.writeFloat(Memory.readFloat(_input.pos + ((2 * i + 1)<<2)));
				}
				//内存归位
				bytes.position = pos;
				
			}
			return _input.pos;
		}
		
		/**
		 * Get input memory entry point
		 * @return position of input memory buffer.
		 */
		public function get entryPosition():int
		{
			_input = $input;
			return $input.pos;
		}
		public function set entryPosition(value:int):void
		{
			_input = _zeroMemAgent;
			_input.pos = value;
		}
		
		
		private function processMain(length:int):void
		{
			var sample:Sample = new Sample();
			for (var i:uint = 0; i < length ;++i )
			{
				sample.left = Memory.readFloat(_input.pos + ((2 * i) << 2));
				sample.right = Memory.readFloat(_input.pos + ((2 * i + 1) << 2));
				for each(var filter:* in _filters)
				{
					filter.process(sample);
				}
				Memory.writeFloat(sample.left, _input.pos + ((2 * i) << 2));
				Memory.writeFloat(sample.right, _input.pos + ((2 * i + 1) << 2));
			}
		}
		
	}

}