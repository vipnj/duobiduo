package com.duobiduo.utils
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.utils.*;
	/**
	 * ...
	 * @author efishocean
	 */
	public class RunTrace
	{
		
		public function RunTrace() 
		{

		}
		private static var draged:Boolean = false;
		private static const traceText:TextField = new TextField();
		private static const dot:Sprite = new Sprite();
		private static const timer:Timer = new Timer(100);
		private static var running:Boolean = true;
		private static var lastTime:int = getTimer();
		private static var getTime:Boolean;
		/**
		 * 初始化
		 * @param	stage		放在那里显示
		 * @param	width		宽度
		 * @param	height		高度
		 * @param	light		是否闪烁
		 * @param	showTime	是否显示间隔时间
		 */
		public static function init(stage:Sprite,width:Number=600,height:Number=400,light:Boolean=true,showTime:Boolean=true):void
		{
			dot.graphics.beginFill(0x666666);
			dot.graphics.drawCircle(5, 5, 5);
			dot.graphics.endFill();
			if (traceText.parent !== stage)
			{
				stage.addChild( traceText );
				stage.addChild( dot );
			}
			traceText.width = width;
			traceText.height = height;
			traceText.x = 0+5;
			traceText.y = 0 + 5;
			traceText.border = true;
			dot.x = 0;
			dot.y = 0;
			dot.addEventListener(MouseEvent.CLICK, onMouseEvent);
			dot.addEventListener(MouseEvent.MOUSE_DOWN, onMouseEvent);
			dot.addEventListener(MouseEvent.MOUSE_UP, onMouseEvent);
			dot.addEventListener(MouseEvent.MOUSE_MOVE, onMouseEvent);
			if (light)
			{
				timer.addEventListener("timer", onTimer);	
				timer.start();
				function onTimer(e:TimerEvent):void
				{
					if ( running )
					{
						if ( traceText.visible )
						{
							dot.graphics.clear();
							dot.graphics.beginFill(0x666666);
							dot.graphics.drawCircle(5, 5, 5);
							dot.graphics.endFill();
						}
						else
						{
							dot.graphics.clear();
							dot.graphics.beginFill(0xff6666);
							dot.graphics.drawCircle(5, 5, 5);
							dot.graphics.endFill();
						}
						running = false;
					}
				}
			}
			else
			{
				running = true;
			}
			getTime = showTime;
		}

		private static function onMouseEvent(e:MouseEvent):void
		{
			switch(e.type)
			{
				case(MouseEvent.MOUSE_UP):
				{
					dot.stopDrag();
					traceText.x = dot.x + 5;
					traceText.y = dot.y + 5;
					break;
				}
				case(MouseEvent.CLICK):
				{
					if (!draged) traceText.visible = !traceText.visible;
					if ( traceText.visible )
					{
						dot.graphics.clear();
						dot.graphics.beginFill(0x666666);
						dot.graphics.drawCircle(5, 5, 5);
						dot.graphics.endFill();
					}
					else
					{
						dot.graphics.clear();
						dot.graphics.beginFill(0xff6666);
						dot.graphics.drawCircle(5, 5, 5);
						dot.graphics.endFill();
					}
					break;
				}
				case(MouseEvent.MOUSE_DOWN):
				{
					draged = false;
					dot.startDrag();
					break;
				}
				case(MouseEvent.MOUSE_MOVE):
				{
					draged = true;
					break;
				}
				default:break;
			}
		}
		
		/**
		 * 显示调试信息
		 * @param	...arg	显示内容，变量、数值或者任何表达式。
		 * @return	返回调试信息字符串
		 */
		public static function show(...arg):String
		{
			if (!running)
			{
				running = true;
				dot.graphics.clear();
				dot.graphics.beginFill(0x66ff66);
				dot.graphics.drawCircle(5, 5, 5);
				dot.graphics.endFill();
			}
			//获取trace发生的地点
			//try
			//{
				//new Math();
			//}
			//catch (e:Error)
			//{
				//var codeLine:String = e.getStackTrace().match(/[a-z]+\.as:[0-9]+/gim)[1];
				//if(codeLine)traceText.appendText(codeLine + "\t\t" ) ;
			//}

			for each(var item:* in arg )
			{
				if (item == null)
				{
					if (typeof item == "number")
					{
						traceText.appendText("NaN" + "\t");
					}
					else if (typeof item == "undefined")
					{
						traceText.appendText("undefined" + "\t");
					}
					else
					{
						traceText.appendText("null" + "\t");
					}
					
				}
				else
				{
					traceText.appendText(item.toString() + "\t");
				}
			}


			if (getTime)
			{
				traceText.appendText("\t::" + ( getTimer() - lastTime));
				lastTime = getTimer();
			}
			var str:String = traceText.text.substring();
			traceText.appendText("\n");
			traceText.scrollV = traceText.maxScrollV;
			return str;
		}
		
	}

}