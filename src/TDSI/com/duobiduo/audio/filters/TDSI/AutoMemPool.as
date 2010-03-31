package com.duobiduo.audio.filters.TDSI 
{
	/**
	 * ...
	 * @author efishocean
	 */
	import com.joa_ebert.apparat.memory.MemoryBlock;
	import com.joa_ebert.apparat.memory.MemoryPool;
	import flash.utils.ByteArray;
	public class AutoMemPool
	{
		private static var _initialized:Boolean=false;
		private static var _cost:uint;
		public static function get initialized():Boolean
		{
			return _initialized;
		}
		
		/**
		 * 
		 * @param	length
		 * @return
		 */
		public static function allocate(length:uint):MemoryBlock
		{
			if (!_initialized)
			{
				//分配16m内存，使用紧密策略
				MemoryPool.initialize(0x1000000, new TightChunksStrategy());
				_initialized = true;
			}
			var mb:MemoryBlock = MemoryPool.allocate(length);
			_cost += mb.length;
			trace("Consumed "+(mb.position+mb.length)+" bytes, "+(0x1000000-_cost)+" bytes remain in total "+(0x1000000)+" bytes of MemoryPool");
			return mb;
		}
		
		public static function free(block:MemoryBlock):void
		{
			MemoryPool.free(block);
			_cost -= block.length;
		}
		
		public static function get buffer():ByteArray
		{
			if (!_initialized)
			{
				//分配16m内存，使用紧密策略
				MemoryPool.initialize(0x1000000, new TightChunksStrategy());
				_initialized = true;
			}
			return MemoryPool.buffer;
		}

	}

}