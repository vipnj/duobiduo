package com.duobiduo.audio.filters.TDSI 
{
	import com.joa_ebert.apparat.memory.MemoryBlock;
	/**
	 * The MemoryChunk class represents a chunk of memory for a strategy making
	 * use of static or dynamic chunks.
	 * 
	 * @private
	 * 
	 * @author efishocean
	 */
	internal final class MemoryChunk
	{
		/**
		 * Creates and returns a new MemoryChunk object.
		 */
		public static function create(): MemoryChunk
		{
			return new MemoryChunk();
		}
		
		/**
		 * Releases a given MemoryChunk object.
		 * 
		 * @param memoryChunk The object to release.
		 */
		private static function release( memoryChunk: MemoryChunk ): void
		{
		}
		
		/**
		 * The block of the chunk.
		 */
		public var block:MemoryBlock;
		
		/**
		 * The next chunk in a free-list.
		 */
		public var next: MemoryChunk;
		
		/**
		 * The previous chunk in a free-list.
		 */
		public var prev: MemoryChunk;
		
		/**
		 * Creates and returns a string representation of the current object.
		 * 
		 * @return The string representation of the current object.
		 */
		public function toString(): String
		{
			return '[MemoryChunk position: 0x' + block.position.toString( 0x10 ) +
				', size: 0x' + block.length.toString( 0x10 ) + ']';
		}
		
		/**
		 * @private
		 */
		public function dispose() : void
		{
			release( this );

			block = null;
			next = null;
			prev = null;
		}
	}
}
