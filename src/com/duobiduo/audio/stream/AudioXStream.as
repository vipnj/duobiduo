package com.duobiduo.audio.stream 
{
	import com.duobiduo.audio.AudioChannelX;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.media.SoundLoaderContext;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class AudioXStream extends EventDispatcher
	{
		
		/**-----------------------------------------------------
		 * 使用sound对象代理sound数据装载
		 */
		public function get sound():StreamSound
		{
			return _sound;
		} 
		private var _sound:StreamSound;
		
		/*
		* 加载进度事件
		*/
		public static const PROGRESS:String = "progress";
		/*
		* 加载进度过程中的数据
		*/
		private var _progressInfo:Object = new Object();
		
		public function get progressInfo():Object
		{
			return _progressInfo;
		}
		
		
		/**-----------------------------------------------------
		 * 创建一个AudioX对象
		 * @param	stream	音频数据流
		 * @param	context 装载环境
		 */
		public function AudioXStream(stream:URLRequest = null, context:SoundLoaderContext = null,decoder:URLRequest=null)
		{
			_sound = new StreamSound(stream, context,decoder);
			_sound.addEventListener("loadComplete", eventHandler, false, 0, true);
			_sound.addEventListener("progress", progressHandler, false, 0, true);
			_sound.addEventListener("ioError", ioErrorHandler, false, 0, true);
		}
		
		private function progressHandler(e:ProgressEvent):void
		{
			//_progressInfo.sound = _sound;
			_progressInfo.bytesLoaded = e.bytesLoaded; 
			
			this.dispatchEvent(new ProgressEvent(AudioXStream.PROGRESS,false,false,e.bytesLoaded,e.bytesTotal));
		}		
		
		private function eventHandler(e:Event):void
		{
			this.dispatchEvent(new Event("complete"));
		}
		
		private function ioErrorHandler(e:IOErrorEvent):void
		{
			this.dispatchEvent(e);
		}	
		
		
		/**-----------------------------------------------------
		 * 载入音频数据
		 * @param	stream	音频数据流
		 * @param	context 装载环境
		 */
		public function load(stream:URLRequest):void
		{
			_sound.load(stream);
		}
		
		
		
		/**-----------------------------------------------------
		 * 创建一个AudioChannelXStream对象
		 * @return AudioChannelXStreamX对象
		 * @see AudioChannelXStream
		 */
		public function createChannel():AudioChannelX
		{
			var sc:AudioChannelX = new AudioChannelX(_sound);
			return sc;
		}
		
		
		
		/**-----------------------------------------------------
		 * 提取声音原始数据。与Sound.extract一致
		 * @param	target	保存提取的数据
		 * @param	length	提取长度
		 * @param	startPosition	起始位置
		 * @return	成功提取采样数量
		 */
		public function extract(target:ByteArray, length:Number, startPosition:Number = -1):Number
		{
			return _sound.extract(target, length, startPosition);
		}

		/**
		 * 加载二进制数据。可以播放本地mp3文件
		 * @param	bytes	完整mp3的二进制数据
		 */
		public function loadBytes(bytes:ByteArray):void
		{
			_sound.loadBytes(bytes);
		}
		
	}
	
}
