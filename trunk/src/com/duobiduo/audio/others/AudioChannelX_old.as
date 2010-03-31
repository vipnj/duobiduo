package com.duobiduo.audio 
{
	import com.duobiduo.audio.filters.bufferFilters.BufferNotchFilter;
	import com.duobiduo.audio.utils.AudioBuffer;
	import com.duobiduo.audio.utils.Sample;
	import com.duobiduo.audio.utils.FillAudioBuffer;
	import flash.events.Event;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import com.duobiduo.audio.generators.PinkNoise;
	import flash.utils.ByteArray;
	
	/**-----------------------------------------------------
	 * AudioChannelX对象实现一个sound channel的基本播放控制，并默认具有播放速度控制。
	 * 与flash.media.SoundChannel不同的是，AudioChannelX自己控制play,pause,stop,resume,以及自销。
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class AudioChannelX 
	{
		private var _soundChannel:SoundChannel;
		private var _sound:Sound;
		private var _dynSnd:Sound;
		private var _loops:uint;
		private var _samplePos:Number;	//提取采样的游标位置
		private var _startPosition:Number;
		private var _audioBuffer:ByteArray;

		
		private const SAMPLES_LENGTH:uint = 2048;
		private const SAMPLES_TIME:Number = SAMPLES_LENGTH / SAMPLE_RATE;
		private const SAMPLES_BYTES:uint = SAMPLES_LENGTH * 8;
		private const SAMPLE_RATE:Number = 44.1; //sample rate per millisecond
		
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
			//var bnf:BufferNotchFilter = new BufferNotchFilter(44100/2048/_speed, 0);
			
			//bufferFilters.push(bnf);
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
		public function set soundTransform(value:SoundTransform):void { _soundTransform = _soundChannel.soundTransform; }
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
			_dynSnd.removeEventListener("sampleData", onSampleData);
			_soundChannel.stop();
			_soundChannel.removeEventListener("complete", onComplete);
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
			if (!_dynSnd.hasEventListener("sampleData") ){
				_dynSnd.addEventListener("sampleData", onSampleData);
				_soundChannel = _dynSnd.play();
			}
			//计算 startTime
			_position = startTime;
			_startPosition = _position * this.speed * SAMPLE_RATE;
			//初始化游标位置
			_samplePos = _startPosition;
			_loops = loops;
			
			this.soundTransform = sndTransform;
			if (!_soundChannel.hasEventListener("complete") )
			{
				_soundChannel.addEventListener("complete", onComplete);
			}
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

			//bufferFilter过滤
			filterBuffer(_audioBuffer);
			
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
		
		private function onComplete(event:Event):void
		{
			_soundChannel.removeEventListener("complete", onComplete);
		}
		
		private function fillAudioBuffer():uint 
		{   
			
			
			var extracted:uint = 0;
			var isEnd:uint = 0;
			var tempSamples:ByteArray = new ByteArray();
			var sample:Sample = new Sample();
			
			//buffer归零
			_audioBuffer.length = 0;
			_audioBuffer.position = 0;
			
			if ( _speed == 1 )
			{
				
				//完整提取
				extracted = _sound.extract(tempSamples, SAMPLES_LENGTH, _samplePos );
				
				//更新采样位置
				_samplePos += extracted;
				
				tempSamples.position = 0;
				while (tempSamples.bytesAvailable>0)
				{
					
					sample.from(tempSamples);
					//写入buffer
					_audioBuffer.writeFloat(sample.left);
					_audioBuffer.writeFloat(sample.right);
				}
				//如果数据不够采样长度，就是结尾
				isEnd = SAMPLES_LENGTH - extracted ;
			}
			else if ( _speed > 1 )
			{
				//丢弃的采样
				_samplePos += SAMPLES_LENGTH * (_speed - 1);
				
				//播放的采样
				extracted = _sound.extract(tempSamples, SAMPLES_LENGTH, _samplePos );
				
				//更新采样位置
				_samplePos += extracted;
				
				tempSamples.position = 0;
				while (tempSamples.bytesAvailable>0)
				{
					
					sample.from(tempSamples);
					//写入buffer
					_audioBuffer.writeFloat(sample.left);
					_audioBuffer.writeFloat(sample.right);
				}
				
				//如果数据不够采样长度，就是结尾
				isEnd = SAMPLES_LENGTH - extracted;
			}
			else//调慢速度播放
			{
				
				//需填充samlpeData长度，单位是byte
				var remain:uint = SAMPLES_LENGTH << 3;
				//暂时取样长度，单位是sample
				var tempLen:Number = SAMPLES_LENGTH * _speed;
				//抽取采样
				extracted = _sound.extract(tempSamples, tempLen, _samplePos );
				_samplePos += extracted;
				isEnd = uint(tempLen) - extracted;
				
				////////填充采样
				
				while (remain >= tempSamples.length)
				{
					
					remain -= tempSamples.length;
					tempSamples.position = 0 ;
					
					while (tempSamples.bytesAvailable>0)
					{
						
						sample.from(tempSamples);
						//写入buffer
						_audioBuffer.writeFloat(sample.left);
						_audioBuffer.writeFloat(sample.right);
					}
					
				}
				
				if (remain>0)
				{
					tempSamples.position = 0 ;
					while (remain>0)
					{
						
						sample.from(tempSamples);
						//写入buffer
						_audioBuffer.writeFloat(sample.left);
						_audioBuffer.writeFloat(sample.right);
						remain-=8;
					}
				}
				
			}
			
			if (isEnd>0)
			{
				
				if (loops == 1)//只播放一次
				{
					this.stop();
				}
				else if(_loops > 1)
				{
					_loops--;
					//开始循环播放,定位提取位置,需填充sampleData
					tempSamples.length = 0;
					//补齐buffer
					extracted = _sound.extract(tempSamples, isEnd, _startPosition);
					_samplePos = _startPosition + extracted;
					tempSamples.position = 0 ;
					while (isEnd>0)
					{
						
						sample.from(tempSamples);
						//写入buffer
						_audioBuffer.writeFloat(sample.left);
						_audioBuffer.writeFloat(sample.right);
						isEnd--;
					}
				}
				else if (_loops == 0)
				{
					//开始循环播放,定位提取位置,需填充sampleData
					tempSamples.length = 0;
					//补齐buffer
					extracted = _sound.extract(tempSamples, isEnd, _startPosition);
					_samplePos = _startPosition + extracted;
					tempSamples.position = 0 ;
					while (isEnd>0)
					{
						
						sample.from(tempSamples);
						//写入buffer
						_audioBuffer.writeFloat(sample.left);
						_audioBuffer.writeFloat(sample.right);
						isEnd--;
					}	
				}
			}
			tempSamples.clear();
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
