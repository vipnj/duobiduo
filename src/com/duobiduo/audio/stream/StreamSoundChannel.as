package   com.duobiduo.audio.stream
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	//import com.duobiduo.utils.RunTrace;
	/**
	 * ...
	 * @author efishocean
	 */
	public class StreamSoundChannel extends EventDispatcher
	{
		internal var channel:SoundChannel;
		internal var streamSound:StreamSound = null;
		internal var loops:int = 0;
		internal var startTime:Number = 0;
		private var _postionStart:Number = 0;
		private var _loadComplete:Boolean = false;
		private var _waitUpdate:Boolean = false;
		private var _playOnce:Boolean = false;
		private var _notSilent:Boolean = false;
		private var _soundTransform:SoundTransform = null;
		private var _leftPeak:Number;
		private var _rightPeak:Number;
		private var _position:Number;
		private const FRAME_TIME:Number = 26;
		
		///由包内StreamSound调用，初始化声道
		internal function init(streamSound:StreamSound, startTime:Number = 0, loops:int = 0, soundTransform:SoundTransform = null ):void
		{
			
			this.streamSound = streamSound;
			this.streamSound.addEventListener(StreamSoundEvent.INITIALIZED, onInitialized, false, 0, true);
			this.streamSound.addEventListener(StreamSoundEvent.SOUND_UPDATED, onUpdated, false, 0, true);
			this.streamSound.addEventListener(StreamSoundEvent.LOAD_COMPLETE, onComplete, false, 0, true);
			this.startTime = startTime;
			_loadComplete = streamSound.loadComplete;
			this.loops = loops;
			if (_loadComplete) this.loops--;
			
			if (soundTransform == null)
			{
				this.soundTransform = new SoundTransform(1,0);
			}
			else
			{
				this.soundTransform = soundTransform; 
			}
		}

		public  function get leftPeak() : Number
		{
			if (channel)
			{
				return this.channel.leftPeak;
			}
			return _leftPeak;
		}
		public  function get rightPeak():Number
		{
			if (channel)
			{
				return this.channel.rightPeak;
			}
			return _rightPeak;
		}
		public  function get position():Number
		{
			if (channel)
			{
				return this.channel.position;
			}
			return _position;
		}
		public function get soundTransform():SoundTransform
		{
			if (channel == null)
			{
				return null;
			}
			return channel.soundTransform;
		}
		public function set soundTransform(value:SoundTransform):void
		{
			_soundTransform = value;
			if (channel)
			{
				channel.soundTransform = _soundTransform;
			}
		}
		public  function stop():void
		{
			//停止声道
			if (channel)
			{
				_leftPeak = channel.leftPeak;
				_rightPeak = channel.rightPeak;
				_position = channel.position;
				channel.stop();
			}
			//解除事件
			if (streamSound)
			{
				if(streamSound.hasEventListener(StreamSoundEvent.INITIALIZED))
				{
					streamSound.removeEventListener(StreamSoundEvent.INITIALIZED, onInitialized);
				}
				if(streamSound.hasEventListener(StreamSoundEvent.SOUND_UPDATED))
				{
					streamSound.removeEventListener(StreamSoundEvent.SOUND_UPDATED, onUpdated);
				}
				if (streamSound.hasEventListener(StreamSoundEvent.LOAD_COMPLETE))
				{
					streamSound.removeEventListener(StreamSoundEvent.LOAD_COMPLETE, onComplete);
				}
			}
			//解除引用
			streamSound = null;		
			loops = 0;
			//soundTransform = null;
		}
		
		///处理声道播放完成事件
		private function onSoundComplete(e:Event):void
		{
			if ( _notSilent )
			{
				//记录完成时播放位置
				_postionStart = channel.position + FRAME_TIME;
			}
			
			//RunTrace.show("-------------------------soundComplete");
			//如果音频文件没有加载完成
			if (!_loadComplete)
			{
				//开启等待音频
				_waitUpdate = true;
			}
			//如果加载完成
			trace("in soundComplete", _loadComplete,_playOnce,loops);
			if (_loadComplete )
			{
				//完整播放一次
				if (_playOnce)
				{
					//判断需要循环
					if (loops >= 0)
					{
						//继续循环播放
						if (startTime > streamSound.length )
						{
							//RunTrace.show("onSoundComplete,_loadComplete,_playOnce,loops >= 0,声音长度不够");
						}
						else
						{
							channel = streamSound.sound.play(startTime, loops, _soundTransform);
							_leftPeak = channel.leftPeak;
							_rightPeak = channel.rightPeak;
							_position = channel.position;
							_notSilent = true;
						}
					}
					else
					{
						//不需再处理SOUND_COMPLETE事件
						channel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
						//传递该事件
						this.dispatchEvent(e);
					}
				}
				else//音频完全加载后没有一次完整播放到结尾
				{
					channel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
					if (_postionStart > streamSound.length || streamSound.length < startTime)
					{
						//RunTrace.show("onSoundComplete,_loadComplete,not _playOnce,声音长度不够");
						channel = streamSound.silentSound.play();
						_leftPeak = channel.leftPeak;
						_rightPeak = channel.rightPeak;
						_position = channel.position;
						_notSilent = false;
					}
					else
					{
						channel = streamSound.sound.play(_postionStart, 0, _soundTransform);
						_leftPeak = channel.leftPeak;
						_rightPeak = channel.rightPeak;
						_position = channel.position;
						_notSilent = true;
					}
					channel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete, false, 0, true);
		
					//这次播放可以播放到结尾
					_playOnce = true;
				}

			}

		}
		
		private function onUpdated(e:StreamSoundEvent):void
		{
			//RunTrace.show("!!!!!!!!!!!!!StreamSoundChannel get update event");
			//音频文件获得更新
			if (_waitUpdate)//如果声道处于等待状态
			{
				//RunTrace.show("声道处于等待状态,从当前位置重新播放",_postionStart);
				channel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
				//sound加载内容更新了，继续播放
				if (_postionStart > streamSound.length || streamSound.length < startTime)
				{
					//RunTrace.show("onUpdated,_waitUpdate,声音长度不够");
					channel = streamSound.silentSound.play();
					_leftPeak = channel.leftPeak;
					_rightPeak = channel.rightPeak;
					_position = channel.position;
					_notSilent = false;
				}
				else
				{
					channel = streamSound.sound.play(_postionStart, 0, _soundTransform);
					_leftPeak = channel.leftPeak;
					_rightPeak = channel.rightPeak;
					_position = channel.position;
					_notSilent = true;
				}
				channel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete, false, 0, true);
				
				_waitUpdate = false;
			}
		}
		
		private function onInitialized(e:StreamSoundEvent):void
		{
			//成功初始化，移除初始化事件
			streamSound.removeEventListener(StreamSoundEvent.INITIALIZED, onInitialized);
			//开始播放音频
			if (startTime > streamSound.length )
			{
				//RunTrace.show("onInitialized,声音长度不够");
				channel = streamSound.silentSound.play();
				_leftPeak = channel.leftPeak;
				_rightPeak = channel.rightPeak;
				_position = channel.position;
				_postionStart = startTime;
				_notSilent = false;
			}
			else
			{
				channel = streamSound.sound.play(startTime, 0, _soundTransform);
				_leftPeak = channel.leftPeak;
				_rightPeak = channel.rightPeak;
				_position = channel.position;
				_notSilent = true;
			}
			//RunTrace.show("音频长度",streamSound.length);
			if (channel)
			{
				channel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete, false, 0, true);
			}
			else
			{
				throw new Error("未知错误，无法播放音频");
			}
		}	
		
		private function onComplete(e:StreamSoundEvent):void
		{
			_loadComplete = true;
			streamSound.removeEventListener(StreamSoundEvent.SOUND_UPDATED, onUpdated);
			streamSound.removeEventListener(StreamSoundEvent.LOAD_COMPLETE, onComplete);
			//如果音频停止，处于等待状态，立即播放
			if (_waitUpdate)
			{
				//RunTrace.show("如果音频停止，处于等待状态，立即播放,",_postionStart);
				channel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
				if (_postionStart > streamSound.length || streamSound.length < startTime)
				{
					//RunTrace.show("onComplete,_waitUpdate,声音长度不够");
					channel = streamSound.silentSound.play();
					_leftPeak = channel.leftPeak;
					_rightPeak = channel.rightPeak;
					_position = channel.position;
					_notSilent = false;
				}
				else
				{
					channel = streamSound.sound.play(_postionStart, 0, _soundTransform);
					_leftPeak = channel.leftPeak;
					_rightPeak = channel.rightPeak;
					_position = channel.position;
					_notSilent = true;
				}
				channel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete, false, 0, true);

				_waitUpdate = false;
			}
			loops--;
		}
	}
	
}