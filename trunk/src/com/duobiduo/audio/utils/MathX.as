package com.duobiduo.audio.utils 
{

	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class MathX 
	{
		private static var bytes:ByteArray = new ByteArray();
		public function MathX() 
		{
			
		}

		public static function sinh(angleRadians:Number):Number
		{
			var ex:Number = Math.exp(angleRadians);
			return (ex - 1 / ex) / 2;
		}
		
		public static function cosh(angleRadians:Number):Number
		{
			var ex:Number = Math.exp(angleRadians);
			return (ex + 1 / ex) / 2;
		}
		
		public static function floatToInt(float:Number):int
		{
			bytes.writeFloat(float);
			bytes.position-=4;
			return bytes.readInt();
		}
		
		public static function intToFloat(num:int):Number
		{
			bytes.writeInt(num);
			bytes.position-=4;
			return bytes.readFloat();
		}
		
		public static function norm2(vector:Vector.<Number>):Number
		{
			var res:Number=0;
			var len:uint = vector.length;
			for (var i:uint = 0; i < len; i++)
			{
				res += vector[i] * vector[i];
			}
			return Math.sqrt(res);
		}
		
		public static function norm1(vector:Vector.<Number>):Number
		{
			var res:Number=0;
			var len:uint = vector.length;
			for (var i:uint = 0; i < len; i++)
			{
				res += Math.abs(vector[i]);
			}
			return res;
		}
		
		public static function norm$(vector:Vector.<Number>):Number
		{
			var res:Number=0;
			var len:uint = vector.length;
			for (var i:uint = 0; i < len; i++)
			{
				res = Math.max(res,Math.abs(vector[i]));
			}
			return res;
		}
		
		public static function maxVector(vector:Vector.<Number>):Vector.<uint>
		{
			var maxIdx:Vector.<uint> = new Vector.<uint>();
			var len:uint = vector.length;
			var res:Number = -Infinity;
			
			for (var i:uint = 0; i < len; i++)
			{
				res = Math.max(res, vector[i]);
			}
			for (i = 0; i < len; i++)
			{
				(res == vector[i]) ? maxIdx.push(i) :0 ;
			}
			return maxIdx;
		}
		
		public static function firstMax(vector:Vector.<Number>):uint
		{
			var len:uint = vector.length;
			var max:Number = -Infinity;
			var res:uint=0;
			for (var i:uint = 0; i < len; i++)
			{
				if (vector[i] > max)
				{
					max = vector[i];
					res = i;
				}
			}
			return res;
		}
		
		public static function minVector(vector:Vector.<Number>):Vector.<uint>
		{
			var minIdx:Vector.<uint> = new Vector.<uint>();
			var len:uint = vector.length;
			var res:Number = Infinity;
			
			for (var i:uint = 0; i < len; i++)
			{
				res = Math.min(res, vector[i]);
			}
			for (i = 0; i < len; i++)
			{
				res == vector[i] ? minIdx.push(i) :0 ;
			}
			return minIdx;
		}
		
		public static function firstMin(vector:Vector.<Number>):uint
		{
			var len:uint = vector.length;
			var min:Number = Infinity;
			var res:uint=0;
			for (var i:uint = 0; i < len; i++)
			{
				if (vector[i] < min)
				{
					min = vector[i];
					res = i;
				}
			}
			return res;
		}
	}
	
}