package com.duobiduo.audio.filters 
{
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public interface IBufferFilter 
	{
		function process(source:ByteArray,size:uint):void;
	}
	
}