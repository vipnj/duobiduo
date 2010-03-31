package com.duobiduo.audio.filters 
{
	import com.duobiduo.audio.utils.Sample;
	
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public interface ISampleFilter 
	{
		function process(sample:Sample):void;
		function reset():void;
		function clone():ISampleFilter;
		function toString():String;
	}
	
}