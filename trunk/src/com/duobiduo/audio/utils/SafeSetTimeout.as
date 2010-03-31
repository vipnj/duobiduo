package com.duobiduo.audio.utils 
{
	/**
	 * ...
	 * @author efishocean
	 */
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	public class SafeSetTimeout
	{
		private var _timer:Timer;
		private var _closure:Function;
		public function SafeSetTimeout(closure:Function, delay:Number, repeat:uint = 10):void
		{
			_closure = closure;
			_timer = new Timer(delay,repeat);
			_timer.addEventListener(TimerEvent.TIMER, onTimer, false, 0, false);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimer, false, 0, false);
			_timer.start();

		}
		private function onTimer(e:TimerEvent):void
		{
			if (e.type == TimerEvent.TIMER)
			{
				if (_closure.apply())
				{
					trace("_closure.apply()");
					e.target.stop();
					e.target.removeEventListener(TimerEvent.TIMER, onTimer, false);
				}
			}
			else
			{
				e.target.stop();
				e.target.removeEventListener(TimerEvent.TIMER, onTimer, false);	
			}

		}
		
	}

}