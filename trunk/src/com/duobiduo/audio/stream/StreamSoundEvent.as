package com.duobiduo.audio.stream
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author efishocean
	 */
	public class StreamSoundEvent extends Event
	{
		public static const SOUND_UPDATED:String = "soundUpdated";
		public static const INITIALIZED:String = "initialized";
		public static const LOAD_COMPLETE:String = "loadComplete";
		public function StreamSoundEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) 
		{
			super(type, bubbles, cancelable);
		}
		
	}
	
}