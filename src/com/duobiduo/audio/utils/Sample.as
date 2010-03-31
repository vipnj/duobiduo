package com.duobiduo.audio.utils
{
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class Sample 
	{
		public var left:Number;
		public var right:Number;

		public function from(samples:ByteArray):void
		{
			left = samples.readFloat();
			right = samples.readFloat();
		}
		
		public function to(samples:ByteArray):void
		{
			samples.writeFloat(left);
			samples.writeFloat(right);
		}
		
		public function Sample( left: Number = 0.0, right: Number = 0.0 )
		{
			this.left = left;
			this.right = right;
		}
		
		public function clone(): Sample
		{
			return new Sample( left, right );
		}
		
		public function toString(): String
		{
			return '{ left: ' + left + ' right: ' + right + ' }';
		}
		
	}
	
}