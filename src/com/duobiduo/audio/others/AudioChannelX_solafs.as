package com.duobiduo.audio 
{
	import com.duobiduo.audio.filters.bufferFilters.BufferNotchFilter;
	import com.duobiduo.audio.filters.bufferFilters.SolafsProcess;
	import com.duobiduo.audio.utils.Sample;
	import flash.events.Event;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.utils.ByteArray;
	import flash.utils.*;
	/**-----------------------------------------------------
	 * AudioChannelX对象实现一个sound channel的基本播放控制，并默认具有播放速度控制。
	 * 与flash.media.SoundChannel不同的是，AudioChannelX自己控制play,pause,stop,resume,以及自销。
	 * @author efishocean 深海鱼 (Tools -> Custom Arguments...)2009.4
	 */
	public class AudioChannelX 
	{
		private var _soundChannel:SoundChannel;		//控制播放的声道
		private var _sound:Sound;					//提供原始声音数据的对象
		private var _dynSnd:Sound;					//用来dsp播放
		private var _loops:uint;					//循环次数
		private var _samplePos:Number=0;				//提取采样的游标位置
		private var _startPosition:Number=0;			//起始播放位置
		private var _audioBuffer:ByteArray;			//音频数据缓存
		private var shouldStop:Boolean = false;		//是否立即停止
		
		//solafs算法所需变量
		private var sola:SolafsProcess = new SolafsProcess(SAMPLES_LENGTH,true);		//solafs算法处理器
		private var Sa:uint=0;										//读取步长
		private var vecInL:Vector.<Number> = new Vector.<Number>();	//缓存左声道输入向量
		private var vecInR:Vector.<Number> = new Vector.<Number>();	//缓存右声道输入向量
		private var vecOutL:Vector.<Number> = new Vector.<Number>();//缓存左声道输出向量
		private var vecOutR:Vector.<Number> = new Vector.<Number>();//缓存右声道输出向量
				
		private const SAMPLES_LENGTH:uint = 2048;							//DSP处理固定长度，由SDK所限的最小长度
		private const SAMPLES_TIME:Number = SAMPLES_LENGTH / SAMPLE_RATE;	//固定长度音频的时间ms。
		private const SAMPLES_BYTES:uint = SAMPLES_LENGTH * 8;				//固定处理长度的字节数
		private const SAMPLE_RATE:Number = 44.1; 							//没毫秒的采样数 sample rate per millisecond
		
		/**-----------------------------------------------------
		 * 是否暂停
		 */
		public function get paused():Boolean
		{
			return _paused;
		}
		private var _paused:Boolean = false;
		
		/**-----------------------------------------------------
		 * 该channel相对于原始声音数据的变速之后的声音长度
		 * 实际长度X播放倍速 = 原始长度
		 */
		public function get length():Number
		{
			return _sound.length/this.speed;
		}
				
		
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
			if (value <= 0) //速度不能小于0
			{
				value = 1;
			}
			
			_speed = value;
			if ( _speed < 1.1 )
			{
				//当播放速度小于1.1的时候，需要
				//为solafs算法提供额外的音频数据
				//使得Sa的长度足够搜索窗口使用
				Sa = SAMPLES_LENGTH * _speed + sola.ADDMAX;
			}
			else
			{
				//速度大于1.1时正常提取，以较少extract消耗
				Sa = SAMPLES_LENGTH * _speed;
			}
		}
		private var _speed:Number = 1;
		
		
		/**-----------------------------------------------------
		 * 处理每个采样的过滤器列表
		 */
		public var sampleFilters:Array = [];
		
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
		 * 当前播放位置，单位毫秒ms。返回的是实际播放位置
		 * 比如原始声音10ms,变速为0.5的时候，
		 * 实际播放长度是20ms，实际播放位置是5ms的话是相对20ms的5ms
		 * 而不是原始10ms的5ms。
		 */
		public function get position():Number { return _position; }
		private var _position:Number = 0;
		
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
		public function AudioChannelX(sound:Sound) 
		{
			_sound = sound;
			_dynSnd = new Sound();
			_audioBuffer = new ByteArray();
		}
		
		
		
		/**-----------------------------------------------------
		 * 暂停当前播放
		 */
		public function pause():void
		{
			_paused = true;
			_soundChannel.stop();
		}
		
		
		
		/**-----------------------------------------------------
		 * 停止该channel
		 */
		public function stop():void
		{
			try
			{
				_dynSnd.removeEventListener("sampleData", onSampleData);
				_soundChannel.stop();
				_soundChannel.removeEventListener("complete", onComplete);
			}
			catch (e:Error)
			{
				//trace(e);
			}
			
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
			if (!_dynSnd.hasEventListener("sampleData") )
			{
				_dynSnd.addEventListener("sampleData", onSampleData);
				_soundChannel = _dynSnd.play();
			}
			//计算 startTime
			_position = startTime;
			_startPosition = _position * this.speed * SAMPLE_RATE;
			
			//初始化游标位置
			_samplePos = _startPosition;
			_loops = loops;
			
			if ( sndTransform!=null )
			{
				this.soundTransform = sndTransform;
			}
			
			if (!_soundChannel.hasEventListener("complete") )
			{
				_soundChannel.addEventListener("complete", onComplete);
			}
			
			shouldStop = false;
		}
		
		
		
		/**-----------------------------------------------------
		 * 恢复播放到暂停位置
		 */
		public function resume():void
		{
			_paused = false;
			_soundChannel = _dynSnd.play();
		}

		
		private function onSampleData(event:SampleDataEvent):void
		{
			
			//开始提取数据，并更新播放进度
			_position = fillAudioBuffer()*SAMPLES_TIME/_speed;
			if (!shouldStop)
			{ 
				//bufferFilter过滤
				//filterBuffer(_audioBuffer);
				
				//event.data从buffer取数据
				_audioBuffer.position = 0;
				
				var sample:Sample = new Sample();
				
				//sample过滤
				for (var i:uint = 0; i < SAMPLES_LENGTH; i++)
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
		
		
		private function b2v(bytes:ByteArray, vecLeft:Vector.<Number>, vecRight:Vector.<Number>):void
		{
			//将双声道二进制音频数据分离为两个向量，个代表左右声道
			var len:uint = bytes.length >> 3;
			bytes.position = 0;
			
			vecLeft.length = vecRight.length = len;
			for (var i:uint = 0; i < len; i++)
			{
				vecLeft[i] = bytes.readFloat();
				vecRight[i] = bytes.readFloat();
			}
			
		}
		private function v2b(vecLeft:Vector.<Number>, vecRight:Vector.<Number>, bytes:ByteArray):void
		{
			//将双声道音频数据的两个声道向量合并为一个二进制数据
			var len:uint = vecLeft.length;
			bytes.length = len << 3;
			bytes.position = 0;
			
			for (var i:uint = 0; i < len; i++)
			{
				bytes.writeFloat(vecLeft[i]);
				bytes.writeFloat(vecRight[i]);
			}
			
		}
		
		

		private function fillAudioBuffer():uint 
		{   
			
			var extracted:uint = 0;
			var isEnd:uint = 0;
			
			//buffer归零
			_audioBuffer.length = 0;
			_audioBuffer.position = 0;
			var time:uint = 0;/////////////////////////////////////////
			time = getTimer();
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
						shouldStop = true;
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
					extracted = _sound.extract(_audioBuffer, Sa, _samplePos );
					//如果数据不够采样长度，就是结尾
					isEnd = Sa - extracted;
					_samplePos += extracted - sola.ADDMAX;
				}
				else
				{
					//提取分析所需数据
					extracted = _sound.extract(_audioBuffer, sola.ADDMAX, _samplePos );
					//如果数据不够采样长度，就是结尾
					isEnd =  sola.ADDMAX - extracted;
					_samplePos += Sa;//extracted;
				}
				
				
				
				
				
				
				if (isEnd>0)
				{
					
					if (_loops == 1)//只播放一次
					{
						shouldStop = true;
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
							extracted -= sola.ADDMAX;
							_samplePos += extracted;
						}
						else
						{
							_samplePos += Sa+isEnd-sola.ADDMAX;
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
							extracted -= sola.ADDMAX;
						}
						_samplePos += extracted;	
					}
				}
				//trace("time for extract data------------------", getTimer() - time);
				if ( !shouldStop )
				{
					
					
					
					//字节转向量
					b2v(_audioBuffer, vecInL, vecInR);
					
					

					
					
					//进行solafs处理
					vecOutL = sola.process(vecInL, _speed);
					vecOutR = sola.quickProcess(vecInR);
					
					
					
					//结果向量转字节
					v2b(vecOutL, vecOutR, _audioBuffer);
					
					
					
					_audioBuffer.position = 0;


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
	}
	
}
