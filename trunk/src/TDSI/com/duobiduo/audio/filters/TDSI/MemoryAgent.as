package com.duobiduo.audio.filters.TDSI 
{
	/**
	 * ...
	 * @author efishocean
	 */
	import com.duobiduo.audio.filters.TDSI.AutoMemPool;
	import com.joa_ebert.apparat.memory.MemoryBlock;
	public class MemoryAgent
	{
		public var pos:int;
		public var len:int;
		public var safeLen:int;
		private var _type:int;
		private var _mb:MemoryBlock;
		
		/**
		 * 
		 * 
		 * @param	length		length of this Memory clip
		 * @param	type		storage type, default type is float/int
		 * 										0: byte, char; 
		 * 										1: short;
		 * 										2: int, float;
		 * 										3: double;
		 */
		public function MemoryAgent(length:int, type:uint=2 ) 
		{
			_type = type;
			this.len = length << _type;
			_mb = AutoMemPool.allocate(this.len);
			this.pos = _mb.position;
			this.safeLen = _mb.length;
		}
		
		public function dispose():void
		{
			AutoMemPool.free(_mb);
		}
		
		/**
		 * position in selected Memory in bytes
		 */
		public function get typedPos():int
		{
			return pos>>_type;
		}
		/**
		 * length of Memory in bytes
		 */
		public function get typedLen():int
		{
			return len>>_type;
		}
		
		/**
		 * storage type
		 */
		public function get type():int
		{
			return _type;
		}
		
		/**
		 * storage type, presents the bytes size of each item 
		 */
		public function get typeSize():int
		{
			return 1<<_type;
		}
		
		public function toString():String
		{
			return "[MemoryAgent position: " + pos +
				", length: " + len + "]";
		}
	}

}