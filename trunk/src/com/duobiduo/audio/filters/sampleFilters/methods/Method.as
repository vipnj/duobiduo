package com.duobiduo.audio.filters.sampleFilters.methods 
{
	/**
	 * ...
	 * @author efishocean
	 */
	public class Method implements IMethod
	{
		
		public function Method() 
		{
			
		}
		public function process(sample:Number):Number
		{
			return sample;
		}
		public function reset():void{}
		public function clone():IMethod
		{
			return new Method();
		}
		public function toString():String
		{
			return "empty method"; 
		}
	}

}