package com.duobiduo.audio 
{
	import cmodule.SolaProcess.CLibInit;
	import com.duobiduo.audio.utils.Sample;
	import flash.events.Event;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.utils.ByteArray;
	/**-----------------------------------------------------
	 * AudioChannelX对象实现一个sound channel的基本播放控制，并默认具有播放速度控制。
	 * 与flash.media.SoundChannel不同的是，AudioChannelX自己控制play,pause,stop,resume,以及自销。
	 * @author efishocean 深海鱼 (Tools -> Custom Arguments...)2009.4
	 */
	public class AudioChannelX 
	{
		public const STOP:uint = 0;
		public const PAUSE:uint = 1;
		public const PLAY:uint = 2;
		
		//全局私有变量
		private var _soundChannel:Object;		//控制播放的声道
		private var _sound:Object;					//提供原始声音数据的对象
		private var _dynSnd:Sound;					//用来dsp播放
		private var _loops:uint;					//循环次数
		private var _samplePos:Number=0;				//提取采样的游标位置
		private var _startPosition:Number=0;			//起始播放位置
		private var _audioBuffer:ByteArray;			//音频数据缓存
		private var _shouldStop:Boolean = false;		//是否立即停止
		private var _status:uint = STOP;
		private var _lastSpeed:Number = 1;
		private var _swithing:Boolean = false;
		
		//solafs算法所需变量
		private var $cLibInit:CLibInit;
		private var $sola:Object;		//solafs算法处理器
		private var $Sa:uint=0;										//读取步长
		private var $addmax:uint = 0;

		//常量
		public const SAMPLES_LENGTH:uint = 4096;							//DSP处理固定长度，由SDK所限的最小长度2048,最大长度8192，取合理值4096
		private const SAMPLES_TIME:Number = SAMPLES_LENGTH / SAMPLE_RATE;	//固定长度音频的时间ms。
		private const SAMPLES_BYTES:uint = SAMPLES_LENGTH * 8;				//固定处理长度的字节数
		private const SAMPLE_RATE:Number = 44.1; 							//没毫秒的采样数 sample rate per millisecond
		
		/**
		 * 当前channel状态，0停止，1暂停，2播放中
		 */
		public function get status():uint
		{
			return _status;
		}
		
		/**-----------------------------------------------------
		 * 是否暂停
		 */
		public function get paused():Boolean
		{
			if ( _status == PAUSE )
			{
				return true;
			}
			return false;
		}

		/**-----------------------------------------------------
		 * 该channel相对于原始声音数据的变速之后的声音长度
		 * 实际长度X播放倍速 = 原始长度
		 */
		public function get length():Number
		{
			return _sound.length/this.speed;
		}
				
		/**-----------------------------------------------------
		 * 当前播放位置，单位毫秒ms。返回的是实际播放位置
		 * 比如原始声音10ms,变速为0.5的时候，
		 * 实际播放长度是20ms，实际播放位置是5ms的话是相对20ms的5ms
		 * 而不是原始10ms的5ms。
		 */
		public function get position():Number 
		{
			
			if (_speed==1.0 && sampleFilters.length == 0 && _status == PLAY )
			{
				//处于从高级播放到普通播放之间切换的时候使用的是动态高级播放的_samplePos值
				_samplePos = _soundChannel.position * SAMPLE_RATE;
	
			}
			return _samplePos / (SAMPLE_RATE * _speed);
		}
		private var _position:Number = 0;		
				
		/**-----------------------------------------------------
		 * 该channel相对于原始声音数据的播放速度，
		 * 改变速度的时候，当前播放位置会随时间轴伸缩以维持播放声音
		 */
		public function get speed():Number
		{
			return _speed;
		}
		public function set speed(value:Number):void
		{
			_lastSpeed = _speed;
			if (value <= 0) //速度不能小于0
			{
				value = 1;
			}
			

			//在这时候判断是否有滤镜以及速度是否为一倍速，并切换到普通sound播放节省cpu
			//如果正在播放
			if ( _status == PLAY && _soundChannel != null)
			{
				//没有滤镜
				if ( sampleFilters.length == 0 )
				{
					//速度从不是一倍速变为一倍速
					if ( value == 1.0 &&  _lastSpeed != 1.0)
					{
						_soundChannel.stop();
						_soundChannel = _sound.play( _samplePos / SAMPLE_RATE  , _loops, _soundTransform);
						trace("速度从不是一倍速变为一倍速 _samplePos",_samplePos);
					}
					//速度从是一倍速变为一倍速，更新_samplePos
					else if( value == 1.0 && _lastSpeed == 1.0)
					{
						
						if (_swithing)
						{
							_soundChannel.stop();
							_soundChannel = _sound.play( _samplePos / SAMPLE_RATE , _loops, _soundTransform);
							
						}
						trace("速度从是一倍速变为一倍速 _samplePos",_samplePos);
					}
					//速度从是一倍速变为不是一倍速，更新_samplePos
					else if ( value != 1.0 && _lastSpeed == 1.0)
					{
						//sound.play后，调用soundChannel.stop会继续播放最多8192个采样。这里偏移8192个采样，以方便衔接。
						_samplePos = _soundChannel.position * SAMPLE_RATE + SAMPLES_LENGTH*4;
						_soundChannel.stop();
						_soundChannel = _dynSnd.play();
						trace("速度从是一倍速变为不是一倍速 _samplePos",_samplePos);
					}
					else
					{
						;
					}
				}
				
				else if ( sampleFilters.length > 0  )
				{
					//速度上次是一倍速
					if ( _lastSpeed == 1.0)
					{
						//从普通播放，附加滤镜后，需调用normalSoundSwitchFilter,_samplePos取值
						
						if (_swithing)
						{
							//sound.play后，调用soundChannel.stop会继续播放最多8192个采样。这里偏移8192个采样，以方便衔接。
							_samplePos = _soundChannel.position * SAMPLE_RATE + SAMPLES_LENGTH * 4;
							
						}
						_soundChannel.stop();
						_soundChannel = _dynSnd.play();
						trace("速度上次是一倍速 _samplePos",_samplePos);
					}
					
				}

			}
			else if (_status == PAUSE)
			{
				;
			}
			//速度赋值
			_speed = value;
			$Sa = SAMPLES_LENGTH * _speed;
			//trace("-----status ",_status);
			
		}
		private var _speed:Number = 1;
		
		
		/**-----------------------------------------------------
		 * 处理每个采样的过滤器列表
		 */
		public var sampleFilters:Array = [];
		
		/**
		 * 当播放速度为一的时候，如果更新了滤镜列表，就需要该方法激活滤镜，
		 * @return 当滤镜列表为空的时返回false
		 */
		public function normalSoundSwitchFilter():void
		{
			_swithing = true;
			this.speed = this.speed;//激活动态播放
			_swithing = false;
			
		}
		
		/**-----------------------------------------------------
		 * 处理缓冲数据的过滤器列表
		 */
		public var bufferFilters:Array = [];
		
				
		
		/**-----------------------------------------------------
		 * 当前左声道音量峰值
		 */
		public function get leftPeak():Number { return _soundChannel.leftPeak; }
		private var _leftPeak:Number=0;
		
		/**-----------------------------------------------------
		 * 当前右声道音量峰值
		 */
		public function get rightPeak():Number { return _soundChannel.rightPeak; }
		private var _rightPeak:Number=0;
		

		
		/**-----------------------------------------------------
		 * 声音变化
		 * @see flash.media.SoundTransform
		 */
		public function get soundTransform():SoundTransform { return _soundChannel.soundTransform; }
		public function set soundTransform(value:SoundTransform):void { _soundTransform = _soundChannel.soundTransform = value; }
		private var _soundTransform:SoundTransform;
		
		
		/**-----------------------------------------------------
		 * @param	soundx
		 */
		public function AudioChannelX(sound:Object) 
		{
			initAlchemy();
			_sound = sound;
			_dynSnd = new Sound();
			_audioBuffer.position = $sola.getPointer();
		}
		
		
		
		/**-----------------------------------------------------
		 * 暂停当前播放
		 */
		public function pause():void
		{
			if ( _speed == 1 && sampleFilters.length==0 && _status==PLAY)
			{
				_samplePos = _soundChannel.position * SAMPLE_RATE;
			}
			//trace("_samplePos ==",_samplePos);
			if (_soundChannel)
			{
				_soundChannel.stop(); 
			}
			_status = PAUSE;
		}
		
		
		
		/**-----------------------------------------------------
		 * 恢复播放到暂停位置
		 */
		public function resume():void
		{
			if ( _status == PAUSE)
			{
				
				//有滤镜
				if (sampleFilters.length > 0)
				{
					_soundChannel = _dynSnd.play();
				}
				
				else
				{
					//没有滤镜，速度为一倍速
					if ( _speed == 1.0 )
					{
						_soundChannel = _sound.play(this.position , _loops, _soundTransform);
						
					}
					//速度不是一倍速
					else if ( _speed != 1.0 )
					{
						_soundChannel = _dynSnd.play();
					}
				}
				_status = PLAY;
			}

		}		
		
		
		/**-----------------------------------------------------
		 * 停止该channel
		 */
		public function stop():void
		{
			
			_dynSnd.removeEventListener("sampleData", onSampleData);
			if ( _soundChannel != null )
			{
				_soundChannel.stop();
				_soundChannel.removeEventListener("complete", onComplete);
			}
			_status=STOP;

			
		}
		
		
		
		/**-----------------------------------------------------
		 * 播放
		 * @param	startTime 实际时间长度下的起始位置。
		 * 			例如原始sound长度10秒，播放倍速0.75的时候，实际播放长度为13.3秒。
		 * 			startTime为5秒的话，是13.3秒的第5秒起，而不是10秒的第5秒。
		 * @param	loops 循环播放次数，默认一次，0表示无限循环。与flash.media.Sound.play()不同。
		 * @param	sndTransform	变型
		 */
		public function play(startTime:Number = 0, loops:int = 1, sndTransform:SoundTransform = null):void
		{

			//计算 startTime
			_position = startTime;
			_startPosition = _position * this.speed * SAMPLE_RATE;
			
			//初始化游标位置
			_samplePos = _startPosition;
			_loops = loops;
			
			if (!_dynSnd.hasEventListener("sampleData") )
			{
				_dynSnd.addEventListener("sampleData", onSampleData);
				//在这时候半段是否有滤镜以及速度是否为一倍速，并切换到普通sound播放节省cpu
				if ( sampleFilters.length == 0 && _speed == 1.0 )
				{
					_soundChannel = _sound.play(_position, _loops, _soundTransform);
				}
				else
				{
					_soundChannel = _dynSnd.play();
				}
			}
			
			if ( sndTransform!=null )
			{
				this.soundTransform = sndTransform;
			}
			
			if (!_soundChannel.hasEventListener("complete") )
			{
				_soundChannel.addEventListener("complete", onComplete);
			}
			
			_shouldStop = false;
			_status = PLAY;
		}


		
		private function onSampleData(event:SampleDataEvent):void
		{

			//开始提取数据，并更新播放进度
			_position = fillAudioBuffer() / SAMPLE_RATE / _speed;
			////trace(sola.getKm());
			if (!_shouldStop)
			{ 
				

				//event.data从buffer取数据
				var sample:Sample = new Sample();
				if (_speed == 1)
				{
					_audioBuffer.position = $sola.getPointer();
				}
				//bufferFilter过滤
				filterBuffer(_audioBuffer);
				//sample过滤
				for (var i:uint = 0; i < SAMPLES_LENGTH; ++i)
				{
					//read buffer->filter->sampleData
					sample.from(_audioBuffer);
					
					filterSample(sample);
					sample.to(event.data);
				}
			}
			else
			{
				this.stop();
			}
			
		}
		
		private function onComplete(event:Event):void
		{
			_soundChannel.removeEventListener("complete", onComplete);
		}
		
		
		

		private function fillAudioBuffer():uint 
		{   
			
			var extracted:uint = 0;
			var isEnd:uint = 0;
			
			//buffer归零
			_audioBuffer.position = $sola.getPointer();

			//原始速度播放时
			if ( _speed == 1 )
			{
				
				//完整提取
				extracted = _sound.extract(_audioBuffer, SAMPLES_LENGTH, _samplePos );
				
				//更新采样位置
				_samplePos += extracted;
				
				//如果数据不够采样长度，就是结尾
				isEnd = SAMPLES_LENGTH - extracted ;
				if (isEnd>0)
				{
					
					if (_loops == 1)//只播放一次
					{
						_shouldStop = true;
					}
					else if(_loops > 1)
					{
						_loops--;
						//开始循环播放,定位提取位置,需填充sampleData
						
						//补齐buffer
						extracted = _sound.extract(_audioBuffer, isEnd, _startPosition);
						_samplePos = _startPosition + extracted;
						
					}
					else if (_loops == 0)
					{
						//开始循环播放,定位提取位置,需填充sampleData
						
						//补齐buffer
						extracted = _sound.extract(_audioBuffer, isEnd, _startPosition);
						_samplePos = _startPosition + extracted;
						
					}
				}
				
			}
			else
			{

				//更新采样位置
				if ( _speed < 1.1 )
				{
					//提取分析所需数据
					extracted = _sound.extract(_audioBuffer, $Sa + $addmax , _samplePos );
					//如果数据不够采样长度，就是结尾
					isEnd = $Sa + $addmax - extracted;
					
				}
				else
				{
					//提取分析所需数据
					extracted = _sound.extract(_audioBuffer, $addmax, _samplePos );
					//如果数据不够采样长度，就是结尾
					isEnd =  $addmax - extracted;
					
				}
				_samplePos += $Sa;
				
				
				
				
				
				if (isEnd>0)
				{
					
					if (_loops == 1)//只播放一次
					{
						_shouldStop = true;
					}
					else if(_loops > 1)
					{
						//开始循环播放,定位提取位置,需填充sampleData
						_loops--;
						
						//补齐buffer
						extracted = _sound.extract(_audioBuffer, isEnd, _startPosition);
						_samplePos = _startPosition;
						//更新采样位置
						if ( _speed < 1.1 )
						{
							//当播放速度小于1.1的时候，需要
							//为solafs算法提供额外的音频数据
							//使得Sa的长度足够搜索窗口使用
							_samplePos += isEnd - $addmax;
						}
						else
						{
							_samplePos += $Sa + isEnd - $addmax;
						}

					}
					else if (_loops == 0)
					{
						//无限循环播放,定位提取位置,需填充sampleData
						//补齐buffer
						extracted = _sound.extract(_audioBuffer, isEnd, _startPosition);
						_samplePos = _startPosition;
						//更新采样位置
						if ( _speed < 1.1 )
						{
							//当播放速度小于1.1的时候，需要
							//为solafs算法提供额外的音频数据
							//使得Sa的长度足够搜索窗口使用
							_samplePos += isEnd - $addmax;
						}
						else
						{
							_samplePos += $Sa + isEnd - $addmax;
						}	
					}
				}
				////trace("time for extract data------------------", getTimer() - time);
				if ( !_shouldStop )
				{
					
					
					

					if ( _speed < 1.1)
					{
						_audioBuffer.position = $sola.process($Sa+$addmax);
					}
					else
					{
						_audioBuffer.position = $sola.process($addmax);
					}


				}
				
			}
			
			return _samplePos;
		}
		
		private function filterSample(sample:Sample):Sample
		{
		
			for each(var filter:* in sampleFilters)
			{
				filter.process(sample);
			}
			return sample;
		}
		
		private function filterBuffer(buffer:ByteArray):void
		{
			for each(var filter:* in bufferFilters)
			{
				filter.process(_audioBuffer);
			}			
		}
		
		protected function initAlchemy():void
		{
			$cLibInit = new CLibInit();
			$sola = $cLibInit.init();
			
			//Retrieve the "Alchemy Memory".
			var ns : Namespace = new Namespace( "cmodule.SolaProcess");
			_audioBuffer = (ns::gstate).ds;
			
			//Alchemy calculates the lookuptables.
			$sola.initSolafs(SAMPLES_LENGTH, 1);
			$addmax = $sola.getAddmax();
		}
	}
}
