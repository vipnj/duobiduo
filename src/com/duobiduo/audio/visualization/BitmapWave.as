package com.duobiduo.audio.visualization
{	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.display.Sprite ;
	
	public class BitmapWave extends Sprite 
	{
		private var _bitmapDatas:Vector.<BitmapData>;
		private var _bitmaps:Vector.<Bitmap>;
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get bitmapDatas( ):Vector.<BitmapData>
		{
			return _bitmapDatas;
		}
		public function set bitmapDatas( bmpds:Vector.<BitmapData> ):void
		{
			_bitmapDatas = bmpds;
			for( var i:uint=0 ; i < _bitmaps.length ; i++ )
			{
				this.removeChild( _bitmaps[i] );
			}
			initBitmaps(); 
		}
		
		/**
		 * The BitmapWave carry many bitmaps that represent sound wave images.
		 * @param bitmapDatas The BitmapData objects arranged in vector being referenced.
		 * 
		 */		
		public function BitmapWave( bitmapDatas:Vector.<BitmapData> = null )
		{
			super();
			_bitmaps = new Vector.<Bitmap>();
			_bitmapDatas = bitmapDatas;
			initBitmaps();
		}
		private function initBitmaps():void
		{
			var offset:uint = 0;
			for( var i:uint = 0 ; i < _bitmapDatas.length ; i++ )
			{
				_bitmaps[i] = new Bitmap( _bitmapDatas[i] );
				this.addChild( _bitmaps[i] );
				_bitmaps[i].x = offset;
				offset += _bitmaps[i].width; 
			}			
		}
	}
}