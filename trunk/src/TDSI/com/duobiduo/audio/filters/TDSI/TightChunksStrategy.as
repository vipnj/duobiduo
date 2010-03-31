package com.duobiduo.audio.filters.TDSI 
{
	import adobe.utils.CustomActions;
	import com.joa_ebert.apparat.memory.IMemoryPoolStrategy;
	import com.joa_ebert.apparat.memory.MemoryBlock;
	import flash.errors.MemoryError;
	import com.duobiduo.audio.filters.TDSI.MemoryChunk;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author efishocean
	 */
	public class TightChunksStrategy implements IMemoryPoolStrategy
	{
		/**
		 * The size of a chunk in bytes.
		 */
		private var _chunkSize: uint;
		
		/**
		 * The buffer of the MemoryPool.
		 */
		private var _buffer: ByteArray;
		
		/**
		 * The free-list of chunks.
		 */
		private var _freeChunks: MemoryChunk;
		
		/**
		 * each chunk use fixed size
		 */
		private var _ReservedChunk:int;
		
		/**
		 * point to the last chunk
		 */
		private var _lastChunk:MemoryChunk;
		
		/**
		 * point to the first chunk
		 */
		private var _firstChunk:MemoryChunk;
		
		/**
		 * 
		 * 
		 * @param length 
		 */
		/**
		 * Creates a new TightChunksStrategy object.
		 * @param	fixedChunkSize	use fixed chunk size or bytes-tight size.
		 * @param	chunkSize 		The length of one chunk; defaults to 1024b. 
		 */
		public function TightChunksStrategy( ReservedChunk:int = 1024 )
		{
			_ReservedChunk = ReservedChunk;
		}
		
		public function get ReservedChunk():int
		{
			return _ReservedChunk;
		}
		
		/**
		 * @inheritDoc
		 */
		public function initialize( buffer : ByteArray ) : void
		{
			_buffer = buffer;
			_lastChunk = MemoryChunk.create();
			_lastChunk.block = MemoryBlock.create(0, _ReservedChunk);
			_firstChunk = _lastChunk;
			
		}
		
		/**
		 * @inheritDoc
		 */
		public function allocate( length : uint ) : MemoryBlock
		{
			
			var chunk:MemoryChunk = MemoryChunk.create();
			_lastChunk.next = chunk;
			chunk.prev = _lastChunk;
			_lastChunk = chunk;
			
			var block:MemoryBlock = MemoryBlock.create(chunk.prev.block.position + chunk.prev.block.length, length);
			chunk.block = block;
			trace(block);
			if ( block.position + block.length > _buffer.length )
			{
				throw new MemoryError();
			}
			return block;
		
		}

		
		/**
		 * @inheritDoc
		 */
		public function free( block : MemoryBlock ) : void
		{

			var chunk:MemoryChunk = _firstChunk;
			var nxChunk:MemoryChunk = null;
			
			while (null!=chunk.next)
			{
				if ( chunk.block.position == block.position && chunk.block.length == block.length)
				{
					
					while (null!=chunk.next)
					{
						nxChunk = chunk.next;
						nxChunk.prev = chunk.prev;
						nxChunk.block.position -= chunk.block.length;
						chunk = nxChunk;
					}
					break;
				}
				else
				{
					chunk = chunk.next;
				}
			}
	
		}
	}
}