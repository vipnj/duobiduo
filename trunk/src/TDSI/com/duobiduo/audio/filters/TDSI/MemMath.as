package com.duobiduo.audio.filters.TDSI
{
	import com.duobiduo.audio.filters.TDSI.MemoryAgent;
	import com.joa_ebert.apparat.memory.Memory;
	public class MemMath
	{
		public static function firstMax(vector:MemoryAgent):uint
		{
			var len:uint = vector.typedLen;
			var max:Number = -Infinity;
			var res:uint=0;
			for (var i:uint = 0; i < len; i++)
			{
				if (Memory.readFloat(vector.pos+(i<<2)) > max)
				{
					max = Memory.readFloat(vector.pos + (i << 2));
					res = i;
				}
			}
			return res;
		}

		
		public static function norm2(vector:MemoryAgent):Number
		{
			var res:Number=0;
			var len:uint = vector.typedLen;
			for (var i:uint = 0; i < len; i++)
			{
				res += Memory.readFloat(vector.pos + (i << 2)) * Memory.readFloat(vector.pos + (i << 2));
			}
			return Math.sqrt(res);
		}
	}
}