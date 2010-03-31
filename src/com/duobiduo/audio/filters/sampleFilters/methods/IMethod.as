package com.duobiduo.audio.filters.sampleFilters.methods 
{
	/**
	 * ...
	 * @author efishocean
	 */
	public interface IMethod
	{
		function process(sample:Number):Number;
		function reset():void;
		function clone():IMethod;
		function toString():String;
	}

}