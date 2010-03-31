package com.duobiduo.audio.utils
{
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.media.Sound;
	import flash.events.Event;
	import flash.events.SampleDataEvent;
	import flash.media.SoundChannel;
	import flash.utils.ByteArray;

	/**
	 * 使用sound采样来模拟一个精度不高，但是更稳定可靠的timer。
	 * 间隔可以稳定在46.4ms.
	 * @author efishocean 2008-12-31
	 */
	public class SoundTimer extends EventDispatcher
	{	
		
		protected var _soundLoop:Sound;		//产生sampleData事件的源
		protected var _soundChannel:SoundChannel;	//保留待用
		protected var _emptyData:ByteArray;			//采样内容
		private var _currentCount:int;		//计数
		private var _running:Boolean;		//运行状态
		private var _currentTimer:Number;	//计时
		private const DELAY:Number = 2048 / 44.1;	//间隔时间
		private var _delay:Number;
		private const MIN_SAMPLE_LENGTH:uint = 2048;	//flash10支持的最小采样长度	
		
		public var repeatCount:int;
		
		/**
		 * 从start()开始的计时，单位ms
		 */
		public function get currentTimer():int		
		{
			return _currentTimer;
		}
		
		/**
		 * 从start()开始的计数
		 */ 
		public function get currentCount():int
		{
			return _currentCount;
		}
		
		/**
		 * SoundTimer的运行状态
		 */
		public function get running():Boolean
		{
			return _running;
		}
		
		/**
		 * 构造函数
		 * @param	repeatCount	设定SoundTimer运行计数，技术结束时，timer停止。
		 */
		public function SoundTimer(repeatCount:int = 0, delay:Number=DELAY )
		{
			super();
			this.repeatCount = repeatCount;
			_currentCount = 0;
			_currentTimer = 0;
			_running = false;
			_emptyData = new ByteArray();
			_delay = delay;
			for ( var c:int=0; c<MIN_SAMPLE_LENGTH; c++ ) {
				_emptyData.writeDouble(0);
			}
		}
		
		/**
		 * 重置并停止SoundTimer，计数和计时都归零，
		 */
		public function reset():void
		{
			_currentCount = 0;
			_currentTimer = 0;
			if( _running ) stop();
		}
		
		/**
		 * 启动SoundTimer。
		 */
		public function start():void 
		{
			_soundLoop = new Sound();
			_soundLoop.addEventListener("sampleData", silentLoop);
			_soundChannel = _soundLoop.play();
			_running = true;
		}
		
		/**
		 * 使用计时稳定的sampleData事件来生成timer事件
		 * @param	event
		 */
		protected function silentLoop(event:SampleDataEvent):void {
			
			//写入采样
			event.data.writeBytes(_emptyData, 0, _emptyData.length);
			//计数
			_currentCount++;
			//计时
			_currentTimer += DELAY;
			//通知监听事件
			dispatchEvent(new TimerEvent(TimerEvent.TIMER));
			//计数结束
			if ( _currentCount == repeatCount )
			{
				//通知事件
				dispatchEvent(new TimerEvent(TimerEvent.TIMER_COMPLETE));
				reset();
			}
		}
		
		/**
		 * 停止SoundTimer
		 */
		public function stop():void
		{
			//移除内部心跳事件
			_soundLoop.removeEventListener("sampleData",silentLoop);
			_running = false;
		}
		
	}
	
}