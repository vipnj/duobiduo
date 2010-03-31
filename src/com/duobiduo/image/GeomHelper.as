package com.duobiduo.image 
{
	import flash.geom.Point;
	import flash.display.DisplayObject;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.geom.Matrix;
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class GeomHelper 
	{
		
		public function GeomHelper() 
		{
			
		}
		
		/**
		 * 计算p2绕p1的旋转角度，以直角坐标系的x轴为0度角。
		 * @param	p1	中心点
		 * @param	p2	旋转点
		 * @return	旋转角度值
		 */
		public static function degree(p1:Point, p2:Point):Number
		{
			var dis:Number = Point.distance(p1, p2);
			var v:Number = p2.y - p1.y;
			var h:Number = p2.x - p1.x;
			var degree:Number = Math.asin(v / dis) / Math.PI * 180;
			if ( h > 0 && v>=0  )
			{
				return degree;
			}
			else if ( h <= 0 && v > 0 )
			{
				return  -degree-180;
			}
			else if ( h >= 0 && v < 0 )
			{
				return degree;
			}
			else ( h < 0 && v <= 0 )
			{
				return 180-degree;
			}
			return 0;
		}
		
		/**
		 * 计算矩形对象变化后的右下角坐标
		 * @param	displayObj
		 * @return
		 */
		public static function getBottomRightOriginalMapping(displayObj:DisplayObject):Point
		{
			//第一个直角边
			var a:Number = (displayObj.getRect(displayObj).width * displayObj.scaleX / 2);
			//第二个直角边
			var b:Number = (displayObj.getRect(displayObj).height * displayObj.scaleY / 2);
			//长边
			var c:Number = Math.sqrt(a * a + b * b);
			var point:Point = new Point();
			//三角函数计算投影位置
			point.x = displayObj.x + c * Math.cos(displayObj.rotation / 180 * Math.PI + Math.PI / 4);
			point.y = displayObj.y + c * Math.sin(displayObj.rotation / 180 * Math.PI + Math.PI / 4);
			//返回矩形对象变化后的右下角坐标
			return point;
		}
		
		/**
		 * 复制像素
		 * @param	destBmpData		目标图像
		 * @param	sourceBmpdata	源图像
		 * @param	fillColor		透明区域填充颜色
		 * @param	rotationPoint 	在sourceBmpdata坐标系中的旋转点
		 * @param	maskRect		在sourceBmpdata坐标系中取景框
		 * @param	degree			旋转角度
		 * @param	scaleMask		取景框放大率
		 * @param	sourceObject	源对象，当传入源对象的时候，坐标系转换
		 */
		public static function copyPixelsByDegree(destBmpData:BitmapData, sourceBmpdata:BitmapData, fillColor:uint, rotationPoint:Point, maskRect:Rectangle, degree:Number, scaleMask:Number, sourceObject:DisplayObject = null):void
		{
			
			var sp:Point = rotationPoint;
			var w:uint = Math.ceil(maskRect.width);
			var h:uint = Math.ceil(maskRect.height);
			var mtx:Matrix = new Matrix();
			var px:Number;
			var py:Number;
			var dp:Point;		//转换后坐标
			var scMtx:Matrix;	
			var scRect:Rectangle;
			if ( sourceObject != null)
			{
				//复制目标显示对象矩阵
				scMtx = sourceObject.transform.matrix.clone();
				//计算目标显示对象矩形
				scRect = new Rectangle(sourceObject.x,sourceObject.y,sourceObject.width,sourceObject.height);
			}
			else
			{
				scMtx = new Matrix();
				scRect =  new Rectangle(0, 0, 0, 0);
			}
			
			//由取景框缩放更新矩阵
			mtx.a = scaleMask/scMtx.a;
			mtx.d = scaleMask / scMtx.d;
			//取景矩阵的旋转角度
			mtx.rotate(degree * Math.PI / 180);
			//根据目标显示对象转换旋转位置
			sp.x = sp.x  / scMtx.a + scRect.x -scMtx.tx;
			sp.y = sp.y  / scMtx.d + scRect.y -scMtx.ty;
			//平移至旋转位置
			mtx.tx = sp.x;
			mtx.ty = sp.y;  

			//获取像素
			for (var i:uint = 0; i < h; i++)
			{
				for (var j:uint = 0; j < w; j++)
				{
					//计算像素坐标
					dp = mtx.transformPoint(new Point(j + maskRect.x, i + maskRect.y));
					var c:uint = sourceBmpdata.getPixel32( dp.x, dp.y);
					if ( dp.x<0 || dp.x>sourceBmpdata.width || dp.y<0 || dp.y>sourceBmpdata.height || c==0x00000000 )
					{
						//若是空像素填充颜色
						c = fillColor;
					}

					destBmpData.setPixel32(j, i, c);
				}
			}
			
		}
	}
	
}