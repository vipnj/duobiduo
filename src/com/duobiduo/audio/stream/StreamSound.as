package   com.duobiduo.audio.stream
{
	import com.duobiduo.audio.utils.SafeSetTimeout;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.media.SoundLoaderContext;
	import flash.display.Loader;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	import flash.media.ID3Info;
	import flash.utils.Endian;
	import flash.display.LoaderInfo;
	import flash.utils.*;
	//import com.duobiduo.utils.RunTrace;
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class StreamSound extends EventDispatcher
	{
		private var _lastTimer:int;					//上次progress事件加载的时间
		private var _bytesLoaded:uint = 0;			//已下载字节
		private var _bytesTotal:uint = 0;			//总字节
		internal var sound:Sound;					//声音类
		internal var silentSound:Sound;				//无声对象
		internal var loadComplete:Boolean = false;	//供StreamSoundChannel判断是否已经加载
		private var _stream:URLStream;				//流对象，用于加载mp3流
		private var _context:SoundLoaderContext;	//音频加载上下文信息
		private var _mp3Data:ByteArray;				//解密后mp3数据
		private var _url:String;					//mp3文件的地址
		private var _isStreaming:Boolean = true;	//是否仍在加载mp3流
		private var _swfBytes:ByteArray;			//swf数据
		private var _bytesCount:uint;				//已保存的mp3数据
		private var _frameCount:uint;				//已计算出来的帧数
		private var _frameSize:uint;				//mp3每帧字节数
		private var _channels:uint;					//双声道单声道
		private var _version:uint;					//mpeg版本
		private var _sampleRate:uint;				//mp3采样率
		private var _mp3headerPostion:int=-1;		//mp3数据流，头部结束位置
		private var _streamPosition:uint;			//mp3数据流中断的地方
		private var _audioSizePosition:uint;		//记录音频大小的地方
		private var _sampleSizePosition:uint;		//记录采样大小的地方
		private var _swfSizePosition:uint;			//swf数据流中记录swf文件大小的位置
		private var _headerParsed:Boolean = false;	//是否成功解析mp3头
		private var	_swfBytesLoader:Loader;			//用于加载内存swf
		private var _decoder:Object;				//解码类
		private var _streamUrl:URLRequest;			//流链接
		private var _loadBytes:ByteArray;			//直接加载二进制，可用于播放本地文件
		private var _loadMode:int = 0;				//加载模式,0：未设置；1：URLStream模式；2：loadBytes模式		
		
		private static var _channelList:Array = new Array();
		private static var $bitRates:Array=[-1,32,40,48,56,64,80,96,112,128,160,192,224,256,320,-1,-1,8,16,24,32,40,48,56,64,80,96,112,128,144,160,-1];
		private static var $versions:Array=[2.5,-1,2,1];
		private static var $samplingRates:Array = [44100, 48000, 32000];

		/**
		 * 可控制字节流加载mp3
		 * @param	stream
		 */
		public function StreamSound(stream:URLRequest = null,context:SoundLoaderContext = null,decoder:URLRequest=null)
		{
			_mp3Data = new ByteArray();
			//初始化stream
			_stream = new URLStream();
			_stream.addEventListener(ProgressEvent.PROGRESS, onStreamEvent );
			_stream.addEventListener(Event.COMPLETE, onStreamEvent );
			_stream.addEventListener(IOErrorEvent.IO_ERROR, onStreamEvent );
			_stream.addEventListener(Event.OPEN, onStreamEvent );
			_stream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onStreamEvent );
			if (stream != null)
			{
				_loadMode = 1;
				_stream.load(stream);
				_url = stream.url;
			}
			
			//兼容Sound类的加载策略，缓冲策略和安全策略（安全策略无法使用）
			if (context)
			{
				_context = context;
				//如果小于1000毫秒的安全时间，有可能上次generateSound方法后等待的create swf没有完成，就调用第二次generateSoundAdd了。
				//开发机器上该安全缓冲时间为85毫秒，但考虑用户机器速度较慢，而定为3000毫秒更安全些。
				if (_context.bufferTime < 1000)
				{
					_context.bufferTime = 1000;
				}
			}
			else
			{
				_context = new SoundLoaderContext(1000, false);
			}
			

			//初始化loader
			_swfBytesLoader = new Loader();
			_swfBytesLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onSwfCreated );
			_swfBytesLoader.contentLoaderInfo.addEventListener(Event.UNLOAD, onSwfUnload );
			
			//初始化decoder
			if (decoder)
			{
				var decoderLoader:Loader = new Loader();
				decoderLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,onDecoderLoaded );
				decoderLoader.load(decoder);
			}
			else
			{
				//生成短无声，由于激发完成事件
				generateSilence();
			}
		}

		//
		private function onDecoderLoaded(e:Event):void
		{
			//RunTrace.show("onDecoderLoaded", "generateSilence");
			//RunTrace.show("e.currentTarget.sameDomain",e.currentTarget.sameDomain);
			var DecoderClass:Class = (e.currentTarget as LoaderInfo).applicationDomain.getDefinition("DecodeClass") as Class;
			_decoder = new DecoderClass(e.currentTarget);
			
			generateSilence();
		}

		
		//处理流事件
		private function onStreamEvent(e:Event):void
		{
			switch(e.type)
			{
				case(ProgressEvent.PROGRESS):	//progress 事件中更新加载状态
				{
					var ev:ProgressEvent = e as ProgressEvent;
					if (_bytesTotal == 0)
					{
						_bytesTotal = ev.bytesTotal;
						if (_decoder)_decoder.target = this;
						//RunTrace.show("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",typeof(this));
					}
					_bytesLoaded = ev.bytesLoaded;
					if ( updateStrategy() )
					{
						upDate();
						_lastTimer = getTimer();
					}
					
					this.dispatchEvent(e);
					
					break;
				}
				case(Event.COMPLETE):	//完全加载，生成最终sound
				{
					trace("Event.COMPLETE",this.bytesLoaded);
					
					//RunTrace.show("******--------******* 完全加载mp3 ********--------*******");
					/*生成最终含有完整mp3的sound*/
					new SafeSetTimeout(finalUpdate,1000);
					//complete事件延迟到loadComplete之后发出
					break;
				}
				case(IOErrorEvent.IO_ERROR):
				{
					this.dispatchEvent(new IOErrorEvent("ioError"));
					
					break;
				}
				case(Event.OPEN):
				{
					this.dispatchEvent(e);
					
					break;
				}
				case(SecurityErrorEvent.SECURITY_ERROR):
				{
					this.dispatchEvent(e);
					
					break;
				}
				default:break;
			}
			
		}
		
		private function finalUpdate():Boolean
		{
			if ( updateStrategy() )
			{
				_isStreaming = false;
				upDate();
				_lastTimer = getTimer();
				return true;
			}
			return false;
		}
		
		//更新策略
		private function updateStrategy():Boolean
		{
			////RunTrace.show("getTimer() - _lastTimer",getTimer() - _lastTimer);
			if ((getTimer() - _lastTimer) > _context.bufferTime ) return true;
			return false;
		}
		
		//更新音频数据流
		private function upDate():void
		{
			//var genRes:Boolean;
			/*尝试用已经加载的mp3数据重新生成sound*/
			var buffer:ByteArray = new ByteArray();
			//读取流
			if (_loadMode == 1)
			{
				_stream.readBytes(buffer, 0, _stream.bytesAvailable);
			}
			else if (_loadMode == 2)
			{
				buffer.writeBytes(_loadBytes);
			}
			trace(buffer.length);
			//将流解密
			if (_decoder)_decoder.decode(buffer);
			trace(buffer.length);
			//如果已经解析头部
			if (_headerParsed)
			{
				
				//向swf二进制中继续写入mp3数据
				//开始写入mp3数据
				_mp3Data.position = _mp3Data.length;
				_mp3Data.writeBytes(buffer, 0, buffer.length);
				generateSoundAdd();
			}
			else
			{
				//RunTrace.show(buffer);
				//开始写入mp3数据
				_mp3Data.position = _mp3Data.length;
				_mp3Data.writeBytes(buffer, 0, buffer.length);
				_mp3headerPostion = getFirstHeaderPosition();
				if (_mp3headerPostion == -1)
				{
					_headerParsed = false;
				}
				else
				{
					_headerParsed = true;
					generateSound();
				}

			}
			buffer.clear();
			////RunTrace.show("generate sound result",genRes);
		}
		

		/**
		 * 生成SoundChannel来播放声音
		 * @param	startTime	播放起点
		 * @return	SoundChannel
		 */ 
		public function play (startTime:Number = 0,loops:int=0,sndTransform:SoundTransform=null) : StreamSoundChannel
		{
			var channel:StreamSoundChannel = new StreamSoundChannel();
			channel.init(this, startTime, loops, sndTransform);
			if (sound)
			{
				dispatchEvent(new StreamSoundEvent(StreamSoundEvent.INITIALIZED, false, false));
			}
			
			_channelList.push(channel);
			return channel;
		}



		//查找头并解析mp3头
		private function getFirstHeaderPosition():int
		{
			_mp3Data.position=0;
			
			
			while(_mp3Data.position<_mp3Data.length)
			{
				try
				{
					var readPosition:uint = _mp3Data.position;
					var str:String = _mp3Data.readMultiByte(3, "us-ascii");
					
					
					if(str=="ID3") //here's an id3v2 header. fuck that for a laugh. skipping
					{
						_mp3Data.position += 3;
						var b3:int = (_mp3Data.readByte() & 0x7F) << 21;
						var b2:int = (_mp3Data.readByte() & 0x7F) << 14;
						var b1:int = (_mp3Data.readByte() & 0x7F) << 7;
						var b0:int = _mp3Data.readByte() & 0x7F;
						var headerLength:int = b0 + b1 + b2 + b3;
						var newPosition:int = _mp3Data.position + headerLength;
						//RunTrace.show("Found id3v2 header, length " + headerLength.toString(16) + " bytes. Moving to " + newPosition.toString(16));
						_mp3Data.position = newPosition;
						readPosition = newPosition;
					}
					else
					{
						//RunTrace.show("Not found id3v2 header ",readPosition);
						_mp3Data.position = readPosition;
					}
					
					var val:uint = _mp3Data.readInt();
					
					if(isValidHeader(val))
					{
						parseHeader(val);
						_mp3Data.position = readPosition + getFrameSize(val);
						
						if (isValidHeader(_mp3Data.readInt()))
						{
							//RunTrace.show("getFrameSize(val)", getFrameSize(val));
							return readPosition;
						}
						
					}	
				}
				catch (e:Error)
				{
					break;
				}

			}
			return -1;
		}		
		
		private function parseHeader(headerBytes:uint):void
		{
			var channelMode:uint=getModeIndex(headerBytes);
			_version=getVersionIndex(headerBytes);
			var samplingRate:uint=getFrequencyIndex(headerBytes);
			_channels=(channelMode>2)?1:2;
			var actualVersion:Number=$versions[_version];
			var samplingRates:Array=[44100,48000,32000];
			_sampleRate=$samplingRates[samplingRate];
			switch(actualVersion)
			{
				case 2:
					_sampleRate/=2;
					break;
				case 2.5:
					_sampleRate/=4;
			}
			
		}
		
	 	private function isValidHeader(headerBits:uint):Boolean 
	    {
	        return (((getFrameSync(headerBits)      & 2047)==2047) &&
	                ((getVersionIndex(headerBits)   &    3)!=   1) &&
	                ((getLayerIndex(headerBits)     &    3)!=   0) && 
	                ((getBitrateIndex(headerBits)   &   15)!=   0) &&
	                ((getBitrateIndex(headerBits)   &   15)!=  15) &&
	                ((getFrequencyIndex(headerBits) &    3)!=   3) &&
	                ((getEmphasisIndex(headerBits)  &    3)!=   2)    );
	    }
	
	    private function getFrameSync(headerBits:uint):uint     
	    {
	        return uint((headerBits>>21) & 2047); 
	    }
	
	    private function getVersionIndex(headerBits:uint):uint  
	    { 
	        return uint((headerBits>>19) & 3);  
	    }
	
	    private function getLayerIndex(headerBits:uint):uint    
	    { 
	        return uint((headerBits>>17) & 3);  
	    }
	
	    private function getBitrateIndex(headerBits:uint):uint  
	    { 
	        return uint((headerBits>>12) & 15); 
	    }
	
	    private function getFrequencyIndex(headerBits:uint):uint
	    { 
	        return uint((headerBits>>10) & 3);  
	    }
	
	    private function getPaddingBit(headerBits:uint):uint    
	    { 
	        return uint((headerBits>>9) & 1);  
	    }
	
	    private function getModeIndex(headerBits:uint):uint     
	    { 
	        return uint((headerBits>>6) & 3);  
	    }
	
	    private function getEmphasisIndex(headerBits:uint):uint
	    { 
	        return uint(headerBits & 3);  
	    }		
		
		// 计算mp3帧长度
		private function getFrameSize(headerBytes:uint):uint
		{
			
			
			var version:uint=getVersionIndex(headerBytes);
			var bitRate:uint=getBitrateIndex(headerBytes);
			var samplingRate:uint=getFrequencyIndex(headerBytes);
			var padding:uint=getPaddingBit(headerBytes);
			var channelMode:uint=getModeIndex(headerBytes);
			var actualVersion:Number=$versions[version];
			var sampleRate:uint=$samplingRates[samplingRate];
			if(sampleRate!=_sampleRate||_version!=version)
			{
				return 0xffffffff;
			}
			switch(actualVersion)
			{
				case 2:
					sampleRate/=2;
					break;
				case 2.5:
					sampleRate/=4;
			}
			var bitRatesYIndex:uint=((actualVersion==1)?0:1)*$bitRates.length/2;
			var actualBitRate:uint = $bitRates[bitRatesYIndex + bitRate] * 1000;	
			traceOnce(actualVersion,actualBitRate,bitRate);
			var frameLength:uint=(((actualVersion==1?144:72)*actualBitRate)/sampleRate)+padding;
			return frameLength;
		}
		private var once:Boolean = true;
		private function traceOnce( ...rest ):void
		{
			if (once)
			{
				trace(rest);
				once = false;
			}
		}
		////_mp3Data中，下一帧起点
		private function nextFramePostion():int
		{
			_mp3Data.position=_mp3headerPostion;
			var headerByte:uint;

			while(true)
			{
				if(_mp3headerPostion>(_mp3Data.length-4))
				{
					//RunTrace.show("passed eof");
					return -1;
				}
				try
				{
					headerByte=_mp3Data.readInt();
				}
				catch (e:Error)
				{
					//RunTrace.show("nextFramePostion error");
					return -1;
				}
				if(isValidHeader(headerByte))
				{
					_frameSize = getFrameSize(headerByte);
					if(_frameSize!=0xffffffff)
					{
						break;
					}
				}
				_mp3headerPostion=_mp3Data.position;
				
			}

			_mp3Data.position=_mp3headerPostion;
			
			if((_mp3headerPostion+_frameSize)>_mp3Data.length)
			{
				//RunTrace.show("(_mp3headerPostion+_frameSize)>_mp3Data.length");
				return -1;
			}
			
			_mp3headerPostion += _frameSize;
			return _mp3Data.position;
		}
		
		///写入swf格式
		private function writeSwfFormatByte(byteArray:ByteArray):void
		{
			var sampleRateIndex:uint=4-(44100/_sampleRate);
			byteArray.writeByte((2<<4)+(sampleRateIndex<<2)+(1<<1)+(_channels-1));
		}
		
		///生成含有一个无声帧的swf
		private function generateSilence():void
		{
			_swfBytes = new ByteArray();
			_swfBytes.endian = Endian.LITTLE_ENDIAN;
			/*初始化swf头*/
			for (var i:uint = 0; i < $soundClassSwfBytes1.length;++i)
			{
				_swfBytes.writeByte( $soundClassSwfBytes1[i] );
			}
			//存储swf文件大小的位置
			_swfSizePosition = _swfBytes.position;
			_swfBytes.writeInt(0); //写入swf文件大小，初始为0
			for (i = 0; i < $soundClassSwfBytes2.length;++i)
			{
				_swfBytes.writeByte( $soundClassSwfBytes2[i] );
			}

			_swfBytes.writeInt( $silentMp3Frame.length + 9 );
			_swfBytes.writeByte(1);
			_swfBytes.writeByte(0);
			writeSwfFormatByte( _swfBytes );
			_swfBytes.writeInt( 1152 );
			_swfBytes.writeByte(0); //seeksamples
			_swfBytes.writeByte(0);
			//写入缓冲mp3数据
			for (i = 0; i < $silentMp3Frame.length;++i)
			{
				_swfBytes.writeByte( $silentMp3Frame[i] );
			}

			for (i = 0; i < $soundClassSwfBytes3.length;++i)
			{
				_swfBytes.writeByte( $soundClassSwfBytes3[i] );
			}
			_swfBytes.position = _swfSizePosition;
			_swfBytes.writeInt( _swfBytes.length );
			_swfBytes.position = 0;
			_swfBytesLoader.loadBytes(_swfBytes);
			
		}
		
		//组装swf文件
		private function generateSound():Boolean
		{
			//RunTrace.show("...................generateSound().....................");
			_swfBytes.position = 0;
			_swfBytes.endian = Endian.LITTLE_ENDIAN;
			/*初始化swf头*/
			for (var i:uint = 0; i < $soundClassSwfBytes1.length;++i)
			{
				_swfBytes.writeByte( $soundClassSwfBytes1[i] );
			}
			//存储swf文件大小的位置
			_swfSizePosition = _swfBytes.position;
			_swfBytes.writeInt(0); //写入swf文件大小，初始为0
			for (i = 0; i < $soundClassSwfBytes2.length;++i)
			{
				_swfBytes.writeByte( $soundClassSwfBytes2[i] );
			}
			//存储mp3文件大小的位置
			_audioSizePosition = _swfBytes.position;
			_swfBytes.writeInt(0); //(audiodatasize+7)写到这里
			_swfBytes.writeByte(1);
			_swfBytes.writeByte(0);
			writeSwfFormatByte( _swfBytes );

			_sampleSizePosition = _swfBytes.position;
			_swfBytes.writeInt(0); //采样数量写在这里
			
			_swfBytes.writeByte(0); //seeksamples
			_swfBytes.writeByte(0);
						
			
			_frameCount = 0;
			_bytesCount = 0; //包含先前的seeksamples
						
			//写入缓冲mp3数据
			for(;;)
			{
				var pos:int = nextFramePostion();
				if (pos == -1) break;
				_swfBytes.writeBytes(_mp3Data, pos, _frameSize);
				_bytesCount += _frameSize;
				_frameCount++;
			}			
			
			//记录mp3数据中断点
			_streamPosition = _swfBytes.position;

			if(_bytesCount==0)
			{
				return false;
			}
			
			_bytesCount += 2;

			var currentPos:uint = _swfBytes.position;
			_swfBytes.position = _audioSizePosition;
			_swfBytes.writeInt( _bytesCount + 7 );
			_swfBytes.position = _sampleSizePosition;
			_swfBytes.writeInt( _frameCount * 1152 );
			_swfBytes.position = currentPos;
			for (i = 0; i < $soundClassSwfBytes3.length;++i)
			{
				_swfBytes.writeByte( $soundClassSwfBytes3[i] );
			}
			_swfBytes.position = _swfSizePosition;
			_swfBytes.writeInt( _swfBytes.length );
			_swfBytes.position = 0;

			_swfBytesLoader.unloadAndStop(true);
			return true;
		}
		
		//附加mp3数据流
		private function generateSoundAdd():Boolean
		{
			//RunTrace.show("...................generateSoundAdd().....................");
			_swfBytes.length = _streamPosition;
			_swfBytes.position = _streamPosition;
			
			//写入缓冲mp3数据
			for(;;)
			{
			
				var pos:int= nextFramePostion();
				if(pos == -1)break;
				_swfBytes.writeBytes(_mp3Data, pos, _frameSize);
				_bytesCount += _frameSize;
				_frameCount++;
			}			
			
			//记录mp3数据中断点，下次接着写入数据
			_streamPosition = _swfBytes.position;

			if(_bytesCount==0)
			{
				return false;
			}
			
			var currentPos:uint = _swfBytes.position;
			_swfBytes.position = _audioSizePosition;
			_swfBytes.writeInt( _bytesCount + 7 );
			_swfBytes.position = _sampleSizePosition;
			_swfBytes.writeInt( _frameCount * 1152 );
			_swfBytes.position = currentPos;
			for (var i:uint = 0; i < $soundClassSwfBytes3.length;++i)
			{
				_swfBytes.writeByte( $soundClassSwfBytes3[i] );
			}
			_swfBytes.position = _swfSizePosition;
			_swfBytes.writeInt( _swfBytes.length );
			_swfBytes.position = 0;
			
			_swfBytesLoader.unloadAndStop(true);
			//RunTrace.show("）））））卸载上次数据");
			return true;
		}

		//生成swf
		private function onSwfCreated(ev:Event):void
		{
			//RunTrace.show("生成swf",sound);
			//内存swf中提取SoundClass类
			var loaderInfo:LoaderInfo = ev.currentTarget as LoaderInfo;
			var soundClass:Class = loaderInfo.applicationDomain.getDefinition("SoundClass") as Class;
			
			if (sound)
			{
				//RunTrace.show("_isStreaming",_isStreaming)
				if (_isStreaming)//还在加载流，没有加载完全，发出更新事件
				{
					//RunTrace.show(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>  sound updated event")
					sound = new soundClass();
					dispatchEvent(new StreamSoundEvent(StreamSoundEvent.SOUND_UPDATED, false, false));
					
				}
				else//完全加载，发出完成事件
				{
					//RunTrace.show("\\\\\\\\\\\\\\\\\\\\\\\\\\\\\  load sound complete event")
					sound = new soundClass();
					dispatchEvent(new StreamSoundEvent(StreamSoundEvent.LOAD_COMPLETE, false, false));
					dispatchEvent(new Event(Event.COMPLETE, false, false));
					loadComplete = true;
					_swfBytesLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onSwfCreated);
					_swfBytesLoader.contentLoaderInfo.removeEventListener(Event.UNLOAD, onSwfUnload);
					_swfBytesLoader.contentLoaderInfo.addEventListener(Event.UNLOAD, onFinish );
					_swfBytesLoader.unloadAndStop(true);
				}
			}
			else//sound初始化完成，发出初始化时间
			{
				sound = new soundClass();
				silentSound = sound;
				dispatchEvent(new StreamSoundEvent(StreamSoundEvent.INITIALIZED, false, false));
				
			}
			
		}
		
		//全部加载完毕时清空byteArray
		private function onFinish(e:Event):void
		{
			//RunTrace.show("onFinish");
			trace("onFinish called");
			_mp3Data.clear();
			_swfBytes.clear();
			_stream.removeEventListener(ProgressEvent.PROGRESS, onStreamEvent);
			_stream.removeEventListener(Event.COMPLETE, onStreamEvent);
			_stream.removeEventListener(IOErrorEvent.IO_ERROR, onStreamEvent);
			_stream.removeEventListener(Event.OPEN, onStreamEvent);
			_stream.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onStreamEvent);
			close();
		}
		
		//执行加载swf
		private function onSwfUnload(e:Event):void
		{
			//RunTrace.show("￥￥￥￥￥￥￥卸载数据完成   ---");
			if (_swfBytesLoader.contentLoaderInfo.hasEventListener(Event.COMPLETE)) 
			{
				_swfBytesLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onSwfCreated);
			}
			if (_swfBytesLoader.contentLoaderInfo.hasEventListener(Event.UNLOAD)) 
			{
				_swfBytesLoader.contentLoaderInfo.removeEventListener(Event.UNLOAD, onSwfUnload);
			}
			_swfBytesLoader = new Loader();
			_swfBytesLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onSwfCreated );
			_swfBytesLoader.contentLoaderInfo.addEventListener(Event.UNLOAD, onSwfUnload );
			_swfBytesLoader.loadBytes(_swfBytes);
			//RunTrace.show("-- -    尝试加载swf数据￥￥￥￥￥￥￥￥￥￥￥￥￥");
		}
		
		private static const $silentMp3Frame:Array=
		[
			0xFF , 0xFA , 0x92 , 0x40 , 0x78 , 0x05 , 0x00 , 0x00 , 0x00 , 0x00 , 0x00,
			0x4B , 0x80 , 0x00 , 0x00 , 0x08 , 0x00 , 0x00 , 0x09 , 0x70 , 0x00 , 0x00,
			0x01 , 0x00 , 0x00 , 0x01 , 0x2E , 0x00 , 0x00 , 0x00 , 0x20 , 0x00 , 0x00,
			0x25 , 0xC0 , 0x00 , 0x00 , 0x04 , 0xB0 , 0x04 , 0xB1 , 0x00 , 0x06 , 0xBA,
			0xA8 , 0x22 , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF,
			0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF , 0xFF
		]
		private static const $soundClassSwfBytes1:Array=
		[ 
			0x46 , 0x57 , 0x53 , 0x09 
		];
		private static const $soundClassSwfBytes2:Array=
		[	
			0x78 , 0x00 , 0x05 , 0x5F , 0x00 , 0x00 , 0x0F , 0xA0 , 
			0x00 , 0x00 , 0x0C , 0x01 , 0x00 , 0x44 , 0x11 , 0x08 , 
			0x00 , 0x00 , 0x00 , 0x43 , 0x02 , 0xFF , 0xFF , 0xFF , 
			0xBF , 0x15 , 0x0B , 0x00 , 0x00 , 0x00 , 0x01 , 0x00 , 
			0x53 , 0x63 , 0x65 , 0x6E , 0x65 , 0x20 , 0x31 , 0x00 , 
			0x00 , 0xBF , 0x14 , 0xC8 , 0x00 , 0x00 , 0x00 , 0x00 , 
			0x00 , 0x00 , 0x00 , 0x00 , 0x10 , 0x00 , 0x2E , 0x00 , 
			0x00 , 0x00 , 0x00 , 0x08 , 0x0A , 0x53 , 0x6F , 0x75 , 
			0x6E , 0x64 , 0x43 , 0x6C , 0x61 , 0x73 , 0x73 , 0x00 , 
			0x0B , 0x66 , 0x6C , 0x61 , 0x73 , 0x68 , 0x2E , 0x6D , 
			0x65 , 0x64 , 0x69 , 0x61 , 0x05 , 0x53 , 0x6F , 0x75 , 
			0x6E , 0x64 , 0x06 , 0x4F , 0x62 , 0x6A , 0x65 , 0x63 , 
			0x74 , 0x0F , 0x45 , 0x76 , 0x65 , 0x6E , 0x74 , 0x44 , 
			0x69 , 0x73 , 0x70 , 0x61 , 0x74 , 0x63 , 0x68 , 0x65 , 
			0x72 , 0x0C , 0x66 , 0x6C , 0x61 , 0x73 , 0x68 , 0x2E , 
			0x65 , 0x76 , 0x65 , 0x6E , 0x74 , 0x73 , 0x06 , 0x05 , 
			0x01 , 0x16 , 0x02 , 0x16 , 0x03 , 0x18 , 0x01 , 0x16 , 
			0x07 , 0x00 , 0x05 , 0x07 , 0x02 , 0x01 , 0x07 , 0x03 , 
			0x04 , 0x07 , 0x02 , 0x05 , 0x07 , 0x05 , 0x06 , 0x03 , 
			0x00 , 0x00 , 0x02 , 0x00 , 0x00 , 0x00 , 0x02 , 0x00 , 
			0x00 , 0x00 , 0x02 , 0x00 , 0x00 , 0x01 , 0x01 , 0x02 , 
			0x08 , 0x04 , 0x00 , 0x01 , 0x00 , 0x00 , 0x00 , 0x01 , 
			0x02 , 0x01 , 0x01 , 0x04 , 0x01 , 0x00 , 0x03 , 0x00 , 
			0x01 , 0x01 , 0x05 , 0x06 , 0x03 , 0xD0 , 0x30 , 0x47 , 
			0x00 , 0x00 , 0x01 , 0x01 , 0x01 , 0x06 , 0x07 , 0x06 , 
			0xD0 , 0x30 , 0xD0 , 0x49 , 0x00 , 0x47 , 0x00 , 0x00 , 
			0x02 , 0x02 , 0x01 , 0x01 , 0x05 , 0x1F , 0xD0 , 0x30 , 
			0x65 , 0x00 , 0x5D , 0x03 , 0x66 , 0x03 , 0x30 , 0x5D , 
			0x04 , 0x66 , 0x04 , 0x30 , 0x5D , 0x02 , 0x66 , 0x02 , 
			0x30 , 0x5D , 0x02 , 0x66 , 0x02 , 0x58 , 0x00 , 0x1D , 
			0x1D , 0x1D , 0x68 , 0x01 , 0x47 , 0x00 , 0x00 , 0xBF , 
			0x03 
		];
		private static const $soundClassSwfBytes3:Array=
		[ 
			0x3F , 0x13 , 0x0F , 0x00 , 0x00 , 0x00 , 0x01 , 0x00 , 
			0x01 , 0x00 , 0x53 , 0x6F , 0x75 , 0x6E , 0x64 , 0x43 , 
			0x6C , 0x61 , 0x73 , 0x73 , 0x00 , 0x44 , 0x0B , 0x0F , 
			0x00 , 0x00 , 0x00 , 0x40 , 0x00 , 0x00 , 0x00 
		];
		
		/**
		 *	已经加载的数据 
		 */
		public function get bytesLoaded () : uint
		{
			return _bytesLoaded;
		}

		
		/**
		 * mp3数据总长度
		 */
		public function get bytesTotal () : int
		{
			return _bytesTotal;
		}

		
		/**
		 * 访问ID3
		 */
		public function get id3 () : ID3Info
		{
			if (sound)
			{
				return sound.id3;
			}
			return null;
		}

		
		/**
		 * 是否还在缓冲
		 */
		public function get isBuffering () : Boolean
		{
			
			if (sound)
			{
				return sound.isBuffering;
			}
			return true;
		}

		/**
		 * 当前声音长度
		 */
		public function get length () : Number
		{
			if (sound)
			{
				return sound.length;
			}
			return -1;
		}


		/**
		 * 声音对象的地址
		 */
		public function get url () : String
		{
			return _url;
		}

		public function get decoderInfo():Object
		{
			if (_decoder)
			{
				
				try
				{
					_decoder.info;
				}
				catch(e:Error)
				{
					return null;
				}
				return _decoder.info;
			}
			return null;
		}
		
		/**
		 * 关闭mp3流
		 */
		public function close () : void
		{
			_bytesTotal = _bytesLoaded;
			if (_loadMode == 1)
			{
				_stream.close();
			}
		}

		/**
		 * 提取mp3波形数据
		 * @param	target
		 * @param	length
		 * @param	startPosition
		 * @return
		 */
		public function extract (target:ByteArray, length:Number, startPosition:Number = -1) : Number
		{
			//var len:Number = 0;
			//len = 
			//if (_isStreaming)
			//{
				//
			//}
			if (sound)
			{
				return sound.extract(target, length, startPosition);
			}
			return 0;
		}

		/**
		 * 加载mp3流
		 * @param	stream
		 */
		public function load (stream:URLRequest = null) : void
		{
			if (_loadMode == 0)
			{
				_loadMode = 1;
				_streamUrl = stream;
				this.addEventListener(StreamSoundEvent.INITIALIZED, onInialized,false,0,true);
			}
			else
			{
				throw new Error("can't reload any sound");
			}
		}

		public function loadBytes(bytes:ByteArray):void
		{
			if (_loadMode == 0)
			{
				_loadMode = 2;
				_loadBytes = bytes;
				new SafeSetTimeout(finalUpdate,1000);
			}
			else
			{
				throw new Error("can't reload any sound");
			}
		}
		
		//本类收到初始化事件后需要摘除事件
		private function onInialized(e:Event):void
		{
			//RunTrace.show("load on initialized");
			_lastTimer = getTimer();
			_stream.load(_streamUrl);
			_url = _streamUrl.url;
			this.removeEventListener(StreamSoundEvent.INITIALIZED, onInialized);
		}

	}
	
}