package com.duobiduo.audio.visualization
{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.media.*;
	import flash.system.*;
	import flash.utils.*;
//	import flash.utils.*;
// 	import flash.events.EventDispatcher;
//	import flash.display.BitmapData;
//	import flash.geom.Point;
//	import flash.geom.Rectangle;
//	import flash.utils.ByteArray;
//	import flash.events.Event;
//	import flash.media.Sound;
//	import flash.utils.Timer;
//	import flash.events.TimerEvent; 
//	import flash.system.System;
	/**
	 * 
	 * @author efishocean
	 * 
	 */	
	public class SoundWavePainterGo extends EventDispatcher
	{
		[Event (name="segment" , type="SoundWavePaintEvent.Event")]
		[Event (name="sound" , type="SoundWavePaintEvent.Event")]
		public const MAX_WIDTH:uint = 128;	// bitmapData has limitation of 8192 pixels width. here make it smaller 图片最大限�?192像素，为了方便限制的更小�?
		private const MAX_HEIGHT:uint = 2048;
		private const MAX_WIDTH_SHIFT:uint = 7;		// use shift operation while dividing 2048 使用位移运算�?048的除�?  2的MAX_WIDTH_SHIFT次幂＝MAX_WIDTH
		private const SAMPLES_PER_MS:Number = 44.1;	//44.1Hz的采样率
		private var _msPerPixel:uint;			// how many milliseconds of sound wave will fill 1 pixel. 每像素代表多少毫�?
		private var _heightOfPeak:Number;		// max height while value is at peak. 波形峰值代表多少像�?
		private var _leftColor:uint;			// color of painting wave. 左声道颜�?
		private var _rightColor:uint;			// color of painting wave. 右声道颜�?
		private var _timer:Timer;				// 使用timer绘制，防止flashplayer假死
		private var _samplesPerPixel:uint;		// 每像素多少个采样�?
		private var _stereo:Boolean;			// 是否同时绘制双声�?
		//private var timer:Timer;				// 对象内部Timer，用来控制绘制流程�?
		private const OPTIMIZED_JUMP:uint = 44; // 用来优化速度的跳跃采样数
		
		
		public var drawPercent:Number = 0;
		
		//--------------------------------------------------------------------------------
		private var bmpw:BitmapWave ;
			
		private var bitmapDatas:Vector.<BitmapData>;
			
		private var segmentPixels:uint ;
		private	var samples:ByteArray ;
		private	var	timer:Timer ;
		private	var rect:Rectangle ;
		private	var cacheRemain:uint ;//已读取且未绘制的采样�?
		private	var pixelCounter:uint;//已绘制的宽度
		private	var sampleCounter:uint ;//已绘制的宽度
		private	var rightTempBmp:BitmapData ;//临时绘制的右声道，绘制结束后通过通道叠加
		private	var samplesPerPixel:uint;
		
		public var soundLoadEnd:Boolean = false;
		
		private var sound:Object;
		
		public var timerRunning:Boolean = false;
		
		
		
		
		
		
		/**
		 * 构造一个波形绘图对象Construct a SoundWavePainter with specification
		 * @param msPerPixel	每个像素代表声音的多少毫�?
		 * @param heightOfPeak	波形的峰值高�?
		 * @param leftColor		左声道颜�?
		 * @param stereo		是否绘制双声�?
		 * @param rightColor	右声道颜�?
		 * 
		 */		 		 		
		public function SoundWavePainterGo( msPerPixel:uint = 100 , heightOfPeak:Number = 128 , leftColor:uint = 0xffffffff , stereo:Boolean = false , rightColor:uint = 0xff000000 )
		{
			_msPerPixel = msPerPixel;
			_samplesPerPixel = _msPerPixel * SAMPLES_PER_MS;			
			if( heightOfPeak > MAX_HEIGHT )
			{
				heightOfPeak = 128;
			}
			_heightOfPeak = heightOfPeak;
			_leftColor = leftColor;
			_rightColor = rightColor;
			_stereo = stereo;
			
		}
		
		/**
		 * Draw a sound wave image into segments in each timer event.绘制波形，每个timer事件绘制一个片�?
		 * @param sound	sound object to be painted.要绘制的声音对象
		 * @param segment 一次绘制的片段长度，单位是像素 
		 * @return 绘制完成的BitmapWave对象
		 * 
		 */		 
		public function draw( _sound:Object , soundLength:Number, segment:uint = 1 ):BitmapWave
		{
			sound = _sound;
			bmpw = adaptedBmpw(soundLength);
			bmpw.name = "bmpw";
			bitmapDatas = bmpw.bitmapDatas;
			
			segmentPixels = segment;
			samples = new ByteArray();
			timer = new Timer(0);
			rect = new Rectangle( 0 , 0 , 1 , 0 );
			cacheRemain = 0;//已读取且未绘制的采样�?
			pixelCounter = 0;//已绘制的宽度
			sampleCounter = 0;//已绘制的宽度
			rightTempBmp = new BitmapData( MAX_WIDTH , _heightOfPeak * 2 , true , 0 );//临时绘制的右声道，绘制结束后通过通道叠加
			samplesPerPixel = SAMPLES_PER_MS * _msPerPixel;
			//draw one timer loop
			
			
			
			return bmpw;
			
		}
		public function drawGo( _sound:Object ):void
		{
			sound = _sound;
			if( timer.running )//如果在绘�?
			{
				
			}
			else//启动timer
			{
				timer.addEventListener( TimerEvent.TIMER, onSingleDraw );
				timer.start();
			}
		}
		private function onSingleDraw( e:Event ):void
		{
			if(!timerRunning)
			{
				timerRunning = true;
			}
			rightTempBmp.dispose();
			rightTempBmp = new BitmapData( MAX_WIDTH , _heightOfPeak * 2 , true , 0 );
			var i:uint=0;
			
			//---------------一个timer事件内绘制若干像素宽的波形片�?
			samples.position = 0;//采样缓存归零
			//trace("sound extract-------->",(samplesPerPixel * segmentPixels),samplesPerPixel , segmentPixels);
			cacheRemain = sound.extract( samples , samplesPerPixel * segmentPixels );
			if( cacheRemain <=0 )
			{
				
				drawPercent = 1;
				
				timer.stop();
				timerRunning = false;
				trace("----cacheRemain , 0----------->",soundLoadEnd);
				if(soundLoadEnd)
				{
					dispatchEvent( new SoundWavePaintEvent( SoundWavePaintEvent.SEGMENT ) );
					dispatchEvent( new SoundWavePaintEvent( SoundWavePaintEvent.SOUND ) );
					
					
					rightTempBmp.dispose();	// 清空临时位图
					System.gc();		//强制垃圾回收
					timer.removeEventListener( TimerEvent.TIMER, onSingleDraw );
				}
				
			}
			else
			{ 
				
				samples.position = 0;//指针归零
				
				for( var j:uint = 0 ; j < cacheRemain ; j++ )
				{
					sampleCounter ++;
					trace(cacheRemain, sampleCounter, samplesPerPixel);
					if( sampleCounter >= samplesPerPixel )
					{
						pixelCounter ++;
						sampleCounter = 0;
					}
					i = pixelCounter >> MAX_WIDTH_SHIFT;
					rect.x = pixelCounter - ( pixelCounter >> MAX_WIDTH_SHIFT << MAX_WIDTH_SHIFT );//绘图的x位置，快速求余，稍快一点点
					
					drawSampleRect( samples , rect , bitmapDatas[ i ] , rightTempBmp );
					
					//fixed here 
					bitmapDatas[ i ].copyPixels( rightTempBmp, new Rectangle( rect.x, 0, 1, _heightOfPeak * 2 ), new Point(rect.x,0), null, null, true);
					
					//----------------------------------优化，每绘制一个采样，之后跳跃n个采样，n=OPTIMIZED_JUMP,波形图片精度变化不大------------------------
//							for( var k:uint=0; k < OPTIMIZED_JUMP ; k++ )
//							{
//								sampleCounter++;
//								samples.position +=8;
//								j++;
//							}
					sampleCounter += OPTIMIZED_JUMP;
					samples.position += OPTIMIZED_JUMP<<3;
					j += OPTIMIZED_JUMP;
					if( samples.position >= samples.length )//防止samples读取溢出
					{
						break;	
					} 						
				}
				
				//一个timer事件内绘制若干像素宽的波形片�?
				drawPercent = pixelCounter/( sound.length / _msPerPixel);
				
				dispatchEvent( new SoundWavePaintEvent( SoundWavePaintEvent.SEGMENT ) );  //完成一个片�?
				
			}

		}
		
		
		/**
		 * Extract wave samples then draw them in one step. This method will block flashplayer while extracting and drawing. 
		 * 使用该函数全部提取波形样本并立即绘制，但是会阻塞flash播放器�?
		 * @param sound		要绘制的声音对象
		 * @return 绘制出bitmapWave对象
		 * 
		 */		
//		public function instantDraw( sound:Sound ):BitmapWave
//		{
//			var bmpw:BitmapWave = adaptedBmpw( sound );
//			var bitmapDatas:Vector.<BitmapData> = bmpw.bitmapDatas;
//			var samples:ByteArray = new ByteArray();
//			var rect:Rectangle = new Rectangle( 0 , 0 , 1 , 0 );
//			var rightTempBmp:BitmapData = new BitmapData( MAX_WIDTH , _heightOfPeak * 2 , true , 0 );//临时绘制的右声道，绘制结束后通过通道叠加
//			try
//			{
//				var remain:uint = sound.extract( samples , sound.length * SAMPLES_PER_MS );
//				sound.extract( samples , remain );
//				//trace("remain samples "+remain,"needs pixels " + remain/_samplesPerPixel,"while _samplesPerPixel is "+_samplesPerPixel,"All bytes "+samples.length );
//				samples.position = 0;//首先采样byte array归零
//				for( var i:uint = 0 ; i < bitmapDatas.length - 1 ; i++ )// 遍历数组
//				{
//					for( var j:uint = 0 ; j < MAX_WIDTH ; j++ )// 沿横向填充具�?048宽的图片的每个一像素宽的矩形
//					{
//						rect.x = j;// 该一像素宽的矩形的绘制位置x�?
//						for( var k:uint = 0 ; k < _samplesPerPixel ; k++ )// 每个像素绘制若干个采�?
//						{
//							drawSampleRect( samples , rect , bitmapDatas[ i ] , rightTempBmp );
//
// 							//----------------------------------优化，每绘制一个采样，之后跳跃n个采样，n=OPTIMIZED_JUMP,波形图片精度变化不大------------------------
//
//							for( var m:uint=0; m < OPTIMIZED_JUMP ; m++ )
//							{
//								samples.position +=8;
//								k++;
//							}
//							if( samples.position >= samples.length )//防止samples读取溢出
//							{
//								break;	
//							} 	
//																			 
//						}
//						remain -= _samplesPerPixel;
//					}
//					bitmapDatas[ i ].copyPixels( rightTempBmp, bitmapDatas[ i ].rect, new Point(0,0), null, null, true);//合并复制临时位图�?
//					rightTempBmp.dispose();
//					rightTempBmp = new BitmapData( MAX_WIDTH , _heightOfPeak * 2 , true , 0 );//重建临时位图
//				}
//
//				for( i = 0 ; i < remain ; i++ )//绘制剩余采样
//				{
//					rect.x = i / _samplesPerPixel;// x位置通过每像素采样数确定
//					drawSampleRect( samples , rect , bitmapDatas[ bitmapDatas.length - 1 ] , rightTempBmp );
// 					
// 					//----------------------------------优化，每绘制1个采样，之后跳跃n个采样，n=OPTIMIZED_JUMP,波形图片精度变化不大------------------------
//			
//					for( m=0; m < OPTIMIZED_JUMP ; m++ )
//					{
//						samples.position +=8;
//						i++;
//					}
//					if( samples.position >= samples.length )//防止samples读取溢出
//					{
//						break;	
//					}
//							
//				}
//				bitmapDatas[ bitmapDatas.length -1 ].copyPixels( rightTempBmp, bitmapDatas[ bitmapDatas.length -1 ].rect, new Point(0,0), null, null, true);
//				this.dispatchEvent( new SoundWavePaintEvent( SoundWavePaintEvent.SOUND ) );	// 发出绘制完成事件
//				rightTempBmp.dispose();	// 清空临时位图
//				//trace("drawing end");
//			}
//			catch( e:Error )
//			{
//				//trace(e)
//				throw e;
//			}
//			return bmpw;
//		}
		
		/**
		 * 
		 * @param samples
		 * @param rect
		 * @param leftBmp
		 * @param rightBmp
		 * 
		 */		
		protected function drawSampleRect( samples:ByteArray, rect:Rectangle, leftBmp:BitmapData, rightBmp:BitmapData ):void
		{
			var left:Number = 0;
			var right:Number = 0;	


			left = samples.readFloat() * _heightOfPeak;//波形值乘以峰�?	
			right = samples.readFloat() * _heightOfPeak;

//				if ( left > 0 )//确定rect位置
//				{
//					rect.y = _heightOfPeak - left;
//					rect.height = left;
//				} else
//				{
//					rect.y = _heightOfPeak;
//					rect.height = -left;
//				}
//优化速度,提高5%
			(left > 0) ? ( (rect.y = _heightOfPeak - left), (rect.height = left) ) : ( (rect.y = _heightOfPeak), (rect.height = -left) );
			leftBmp.fillRect( rect , _leftColor );//画一个采�?
			if( _stereo )//是否画右声道
			{
//					if (right>0)				
//					{
//						rect.y = _heightOfPeak - right;
//						rect.height = right;
//					} else
//					{
//						rect.y = _heightOfPeak;
//						rect.height = -right;
//					}
//优化速度
				(right>0) ? ( (rect.y =  _heightOfPeak - right), (rect.height = right) )  : ( (rect.y =  _heightOfPeak), (rect.height = -right) );
				rightBmp.fillRect( rect , _rightColor );//在右声道的临时位图中画一个采�?
				

			}

			
		}
		
		/**
		 * 计算加载完成的sound对象需要的bitmapWave尺寸 
		 * @param sound	要绘制的声音对象
		 * @return 需要的波形位图
		 * 
		 */
		protected function adaptedBmpw( length:Number ):BitmapWave
		{
			//--------calculate sound length and return bmps
			try
			{
				var pixels:uint = length / _msPerPixel;
				var len:uint = pixels >> MAX_WIDTH_SHIFT;
				var remain:uint = pixels % MAX_WIDTH;
				var bmps:Vector.<BitmapData> = new Vector.<BitmapData>( len + 1 );
				for( var i:uint = 0 ; i < len ; i++ )
				{
					bmps[i] = new BitmapData( MAX_WIDTH , _heightOfPeak * 2 , true , 0 );
				}
				bmps[len] = new BitmapData( remain , _heightOfPeak * 2 , true , 0 );
				
			}
			catch( e:Error )
			{
				//trace( e );
				//throw e;
			}
			return new BitmapWave( bmps );
		}
		
		/**
		 * 
		 * @param sound
		 * @param bitmapData
		 * @return 
		 * 
		 */		
		protected function loadingDraw( sound:Object , bitmapData:Vector.<BitmapData> ):void
		{
			//trace("asf");
		}
		
	}
}