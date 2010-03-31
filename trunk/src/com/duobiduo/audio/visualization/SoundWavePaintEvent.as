package com.duobiduo.audio.visualization
{
	import flash.events.Event;
	public class SoundWavePaintEvent extends Event
	{
		public static const SEGMENT:String = "segment";	// dispatch when finish drawing one segment of any sound
		public static const SOUND:String = "sound";		// dispatch when finish drawing one sound wave
		public function SoundWavePaintEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
		}

	}
}